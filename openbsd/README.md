# OpenBSD Rails Infrastructure v337.4.0
Two-phase deployment: 40+ domains, 8 Rails apps, NSD DNS+DNSSEC, TLS, PF firewall, Relayd reverse proxy.

## Architecture
```
Internet → PF (synproxy, rate limit, bruteforce)
        → Relayd (TLS termination, port 443)
        → Falcon (async HTTP server)
        → Rails apps

DNS: NSD with DNSSEC (ECDSAP256SHA256)
```

## Two-Phase Deployment

### Phase 1: Pre-Point (before DNS glue record)
```bash
scp openbsd.sh dev@brgen.no:/home/dev/
ssh dev@brgen.no
doas zsh openbsd.sh --pre-point
```

Sets up:
- Ruby 3.3 + Rails 8.0.3 + Falcon async HTTP
- PostgreSQL + Redis
- **NSD DNS with DNSSEC** (MUST run before glue registration)
- PF firewall (synproxy, rate limiting, bruteforce detection)
- 8 Rails apps on ports 10002-11006, 10008

**CRITICAL**: NSD must be running on port 53 BEFORE registering `ns.brgen.no` glue record at Norid.

### Phase 2: Post-Point (after DNS propagation)
```bash
# After: 1) Norid accepts ns.brgen.no, 2) DNS propagates
doas zsh openbsd.sh --post-point
```

Sets up:
- TLS certificates via acme-client (Let's Encrypt)
- Relayd reverse proxy (port 443 → brgen:11006)
- PTR records (OpenBSD Amsterdam)
- Cron jobs (certificate renewal)

## Apps & Ports

Canonical port assignments (from master.json):

- **brgen:11006** - 40+ city domains (brgen.no, oshlo.no, lndon.uk, etc.)
- **pubattorney:10002** - pub.attorney, freehelp.legal
- **bsdports:10003** - bsdports.org
- **hjerterom:10004** - hjerterom.no
- **privcam:10005** - privcam.no
- **amber:10006** - amberapp.com
- **blognet:10007** - foodielicio.us, stacyspassion.com, etc.
- **mytoonz:10008** - mytoonz.com (AI comic generator)
## Requirements
- OpenBSD 7.7+
- Root/doas access
- Public IP: 185.52.176.18
- ~2GB RAM, 10GB disk

## Verify Daemons
```bash
# Check all services
rcctl ls on

# Check individual daemons
rcctl check httpd relayd postgresql redis nsd

# Check Rails apps
rcctl check brgen amber blognet bsdports hjerterom privcam pubattorney

# View logs
tail -f /var/log/messages
tail -f /var/log/rails/unified.log
```

## Security

### PF Firewall
- **Synproxy**: TCP SYN flood protection on ports 22, 80, 443
- **Rate limiting**: Max 50 connections/30s per IP, overload to `<ratelimit>` table
- **Bruteforce protection**: SSH limited to 15 conn/60s, overload to `<bruteforce>` table
- **Scrubbing**: no-df, random-id, max-mss 1440

### Relayd Security Headers (OWASP Secure Headers)
Request headers:
- `X-Forwarded-For: $REMOTE_ADDR`
- `X-Forwarded-Proto: https`

Response headers (added 2025-10-16):
- `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
- `X-Frame-Options: DENY`
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy: geolocation=(), microphone=(), camera=()`
- `Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'`

### DNSSEC
- Algorithm: ECDSAP256SHA256 (algorithm 13)
- ZSK + KSK per domain
- Zone signing with NSEC3 salt
- DS records at /var/nsd/zones/keys/*.ds (submit to registrar)

## Configuration Files
- `/etc/pf.conf` - Firewall (verified against man.openbsd.org/pf.conf)
- `/etc/relayd.conf` - Reverse proxy (verified against man.openbsd.org/relayd.conf)
- `/etc/httpd.conf` - ACME HTTP-01 challenge server
- `/etc/acme-client.conf` - Let's Encrypt TLS certificates
- `/etc/nsd/nsd.conf` - DNS server with DNSSEC
- `/etc/rc.d/{app}` - Service control scripts

## PostgreSQL Configuration

Optimized for small VPS (~2GB RAM):

```conf
# /var/postgresql/data/postgresql.conf
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 4MB
min_wal_size = 1GB
max_wal_size = 4GB
```

## Falcon Worker Configuration

8 instances (one per app) on ports defined in master.json:

```ruby
# Each app's bin/falcon-host
require 'falcon/host'
require 'async/container'

Falcon::Host.new do
  count ENV.fetch('WORKERS', 4).to_i
  
  endpoint Async::HTTP::Endpoint.parse("http://0.0.0.0:#{ENV.fetch('PORT')}")
  
  protocol :rack
  
  rack do
    File.expand_path('config.ru', __dir__)
  end
end.run
```

Worker distribution (4-5 workers per app):
- brgen:11006 - 5 workers (multi-tenant, high traffic)
- pubattorney:10002 - 4 workers
- bsdports:10003 - 4 workers
- hjerterom:10004 - 4 workers
- privcam:10005 - 4 workers
- amber:10006 - 4 workers
- blognet:10007 - 4 workers
- mytoonz:10008 - 4 workers

Total: ~33 worker processes

## Service Topology

```
┌─────────────────────────────────────────────────────────────┐
│ Internet (IPv4 + IPv6)                                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ PF Firewall (185.52.176.18)                                 │
│ - Synproxy on 22/80/443                                     │
│ - Rate limit: 50 conn/30s                                   │
│ - Bruteforce protection: SSH 15/60s                         │
│ - Tables: <bruteforce>, <ratelimit>                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Relayd (TLS Termination)                                    │
│ - Port 443 → 11006 (brgen.no production)                    │
│ - OWASP Secure Headers                                      │
│ - HSTS, CSP, X-Frame-Options, etc.                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Falcon Async HTTP Server (8 instances)                      │
│ 11006: brgen        (40+ domains, multi-tenant)             │
│ 10002: pubattorney  (pub.attorney, legal services)          │
│ 10003: bsdports     (OpenBSD ports directory)               │
│ 10004: hjerterom    (Norwegian dating/social)               │
│ 10005: privcam      (Privacy-focused camera)                │
│ 10006: amber        (Amber framework demo)                  │
│ 10007: blognet      (Blog network, 6 domains)               │
│ 10008: mytoonz      (AI comic generator)                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Rails 8.0.3 Applications                                    │
│ - PostgreSQL 16 (single database server)                    │
│ - Solid Queue (background jobs)                             │
│ - Solid Cache (SQLite-backed cache)                         │
│ - Solid Cable (WebSockets)                                  │
│ - StimulusReflex (real-time reactivity)                     │
└─────────────────────────────────────────────────────────────┘
```

## Payment & Billing

**VPS Provider**: OpenBSD Amsterdam  
**Server**: vm08 on server27.openbsd.amsterdam  
**Cost**: €69/year  
**Due**: 2026-08-01

### Payment Methods

- **Stripe**: https://buy.stripe.com/8wMaEO0i67LS1eE288
- **iDEAL (bunq)**: https://bunq.me/openbsdams/69/vm08%20server27
- **PayPal**: https://paypal.me/runbsd/69eur

### Renewal Process

1. Receive renewal email from OpenBSD Amsterdam
2. Pay via one of the methods above (iDEAL preferred)
3. Service continues uninterrupted
4. Update `payment_due` in master.json

## Backup Procedures

**Provider**: Tarsnap  
**Frequency**: Daily (04:00 UTC)  
**Retention**: 30 days  
**Encryption**: AES-256

### Backup Targets

1. PostgreSQL databases (all apps)
2. Uploaded files (`public/uploads/*`)
3. Configuration files (`config/`, `.env.*`)
4. Logs (`log/*.log`, `/var/log/rails/`)

### Backup Script

```bash
# /usr/local/bin/backup-rails.sh (runs daily via cron)
#!/bin/sh
set -euo pipefail

BACKUP_NAME="rails-$(date +%Y%m%d-%H%M%S)"

# Dump all PostgreSQL databases
for db in brgen pubattorney bsdports hjerterom privcam amber blognet mytoonz; do
  pg_dump -U postgres "$db" | gzip > "/tmp/${db}.sql.gz"
done

# Create tarsnap archive
tarsnap -c -f "$BACKUP_NAME" \
  /tmp/*.sql.gz \
  /home/*/public/uploads \
  /home/*/config \
  /home/*/log \
  /var/log/rails

# Cleanup
rm /tmp/*.sql.gz

# Verify backup exists
tarsnap --list-archives | grep "$BACKUP_NAME"
```

### Restore Procedure

```bash
# List available backups
tarsnap --list-archives | grep rails

# Restore specific backup
tarsnap -x -f rails-20251021-040000 -C /restore

# Restore PostgreSQL database
gunzip -c /restore/brgen.sql.gz | psql -U postgres brgen
```

### Weekly Verification

Every Monday at 10:00 UTC, automated check:

```bash
# Verify latest backup is restorable
LATEST=$(tarsnap --list-archives | grep rails | tail -1)
tarsnap -t -f "$LATEST" > /dev/null && echo "✓ Backup verified"
```

## Monitoring

**Primary**: Munin (system metrics)  
**Logs**: Centralized syslog + Rails logs  
**Alerts**: Email + log files

### Munin Metrics

- CPU usage per process
- Memory usage (RSS, VSZ)
- Disk I/O (read/write)
- Network traffic (in/out)
- PostgreSQL connections
- Rails request rate
- Response times (p50, p95, p99)

### Log Files

- `/var/log/messages` - System log
- `/var/log/rails/unified.log` - All Rails apps (JSON format)
- `/home/*/log/production.log` - Per-app Rails logs
- `/var/log/daemon` - Service control (rcctl)

### Health Check Endpoint

All apps expose `/up` endpoint:

```bash
# Check all apps
for port in 11006 10002 10003 10004 10005 10006 10007 10008; do
  echo -n "Port $port: "
  curl -sf http://localhost:$port/up && echo "✓" || echo "✗"
done
```

### Alert Rules

Email alerts sent for:
- High CPU (>80% sustained for 5min)
- High memory (>90%)
- Low disk space (<10% free)
- PostgreSQL connection errors
- Rails app crashes (>3 restarts/hour)
- TLS certificate expiry (<7 days)

## Verified
- 2025-10-21: All configs verified against official OpenBSD man pages
- VPS: dev@brgen.no (185.52.176.18)
- Version: 337.4.0 (matches master.json 16.9.0)
