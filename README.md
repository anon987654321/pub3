# pub3 - Multi-Project Repository

A comprehensive repository containing Rails applications, multimedia tools, OpenBSD infrastructure, and shell utilities.

[![CI](https://github.com/anon987654321/pub3/actions/workflows/ci.yml/badge.svg)](https://github.com/anon987654321/pub3/actions/workflows/ci.yml)
[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

## 📚 Documentation

- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Complete development setup guide
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines
- **[SECURITY.md](SECURITY.md)** - Security policy and reporting
- **[CHANGELOG.md](CHANGELOG.md)** - Version history
- **[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)** - Community standards

## 🏗️ Project Structure

```
pub3/
├── master.json          # Central governance and configuration
├── rails/               # Rails 8 application generators
│   ├── brgen.sh        # Multi-tenant platform (40+ domains)
│   ├── amber.sh        # Social amber alert system
│   ├── blognet.sh      # Decentralized blogging
│   └── ...             # 7+ Rails applications
├── multimedia/          # Audio/video/image processing
│   ├── dilla/          # Music production (Ruby)
│   ├── postpro/        # Image post-processing (Ruby)
│   └── repligen/       # AI image generation (Ruby)
├── openbsd/            # OpenBSD deployment scripts
├── sh/                 # Shell utilities (tree, lint, security)
└── bplans/             # Business plans and documentation
```

## 🚀 Quick Start

```bash
# Clone repository
git clone https://github.com/anon987654321/pub3.git
cd pub3

# Review project philosophy
cat master.json

# Explore structure
sh/tree.sh .

# See DEVELOPMENT.md for detailed setup
```

## 🌐 Rails Platform - Brgen

A Rails 8 multi-tenant platform hosting specialized Norwegian web applications on OpenBSD infrastructure.

### Architecture
**Platform**: OpenBSD 7.7 (GENERIC) #2 amd64
**Web Server**: Puma (Rails 8)

**Database**: PostgreSQL with `acts_as_tenant` multi-tenancy

**Reverse Proxy**: relayd(8) for TLS termination

**DNS**: NSD authoritative nameserver

**TLS**: Let's Encrypt via acme-client(1)

**Deployment**: VPS at 185.52.176.18

## Applications
### Base Application
- **Domain**: brgen.no

- **Port**: 10001 (internal)

- **Status**: ✅ Deployed and running

### Sub-Applications
- **brgen_dating** - Dating platform (dating.brgen.no)

- **brgen_marketplace** - Marketplace (markedsplass.brgen.no)

- **brgen_playlist** - Playlist management (playlist.brgen.no)

- **brgen_tv** - TV/streaming (tv.brgen.no)

- **brgen_takeaway** - Food delivery (takeaway.brgen.no)

All sub-applications share the core brgen codebase via multi-tenancy.
## Infrastructure Status
### ✅ Completed
- [x] Base Rails application deployed on port 10001

- [x] PostgreSQL database initialized with multi-tenancy

- [x] Redis cache and job queue running

- [x] NSD DNS server configured for brgen.no zone

- [x] DNS records propagated (ns.brgen.no @ Amsterdam VPS)

- [x] Let's Encrypt TLS certificates generated for all domains

- [x] Certificate format converted (PKCS#8 → RSA for LibreSSL)

- [x] pf(4) firewall configured (ports 22, 80, 443 open)

- [x] httpd(8) configured for ACME challenges

### 🚧 In Progress
- [ ] relayd reverse proxy configuration (BLOCKED - parser bug)

- [ ] Sub-application deployment

- [ ] Generator script fixes (bundler permissions)

## TLS Certificates
All certificates managed via acme-client(1) with 90-day renewal:
```
/etc/ssl/brgen.no.crt                    # Certificate chain

/etc/ssl/private/brgen.no.key           # Private key (RSA format)

```

**SANs covered**:
- brgen.no

- www.brgen.no

- dating.brgen.no

- markedsplass.brgen.no

- playlist.brgen.no

- tv.brgen.no

- takeaway.brgen.no

- maps.brgen.no

**Renewal**: Automated via cron with acme-client(1)
## DNS Configuration
**Primary NS**: ns.brgen.no (185.120.77.132 - Amsterdam VPS)
**Secondary NS**: ns.hyp.net (Oslo registrar's free service)

NSD configuration at `/var/nsd/zones/brgen.no.zone` with:
- A records for main domain and subdomains → 185.52.176.18

- NS records pointing to primary/secondary nameservers

- SOA with 24h refresh, 2h retry, 30d expire

## Known Issues
### relayd Parser Failure (OpenBSD 7.7)
**Issue**: All newly created `relayd.conf` files fail validation with `"protocol X defined twice"` errors, even when using exact syntax from working examples.
**Status**: Bug report prepared for misc@openbsd.org
**Workaround**: None found (tested 10+ approaches)

**Impact**: HTTPS reverse proxy cannot be configured

**Temporary**: Applications accessible via HTTP on port 10001

**Details**: See `/g/pub/openbsd_relayd_bug_report.txt`
## Deployment Scripts
Located in `/g/pub/rails/`:
- `brgen.sh` - Base application generator
- `bsdports.sh` - OpenBSD ports installation

- `amber.sh` - Amber framework deployment (alternative)

- `__shared.sh` - Shared generator functions

### Generator Issue
Scripts currently use `bundle add` which requires system-wide gem installation permissions. Needs refactoring to use `bundle install` with local `vendor/bundle`.

## Process Management
**Current**: Manual background process
**Command**: `cd ~/brgen && bundle exec puma -p 10001 -e production &`

**Future**: Consider rc.d script for proper service management

## Database Schema
Multi-tenant setup using `acts_as_tenant`:
```ruby
# Core tables

tenants              # Tenant isolation

users               # Per-tenant users

accounts            # User accounts (removed social fields)

followers           # Following relationships (no counter cache)

```

### Notable Migrations
- Removed unused social media columns from accounts table

- Simplified followers table (removed counter cache for compatibility)

- Fixed `acts_as_tenant` generator issues with foreign keys

## Rails Configuration
**Environment**: Production
**Secret Key**: Managed via `RAILS_MASTER_KEY`

**Asset Pipeline**: Propshaft

**CSS**: Tailwind CSS

**JS**: Importmap

**Background Jobs**: Solid Queue (backed by PostgreSQL)

## Security
- **Firewall**: pf(4) with synproxy and rate limiting
- **TLS**: Let's Encrypt with strict transport security

- **SSH**: Root access restricted, key-based auth

- **Database**: Local PostgreSQL (not exposed)

- **Secrets**: Environment variables, not committed

## Development
### Local Setup
```bash

git clone <repository>

bundle install

rails db:create db:migrate

rails assets:precompile

rails server

```

### Deployment to OpenBSD
```bash

# Via deployment scripts

./rails/brgen.sh

# Or manual
ssh root@185.52.176.18

cd ~/brgen

git pull

bundle install

rails db:migrate RAILS_ENV=production

rails assets:precompile RAILS_ENV=production

# Restart puma process

```

## Directory Structure
```
/g/pub/

├── rails/              # Deployment scripts

│   ├── brgen.sh       # Base app generator

│   ├── __shared.sh    # Shared functions

│   └── *.sh           # Other generators

├── openbsd.sh         # Historical VPS setup script

├── master.json        # Configuration rules (zsh-first, deny lists)

└── README.md          # This file

VPS: /root/brgen/
├── app/               # Rails application

├── config/            # Rails configuration

├── db/                # Database migrations

├── public/            # Static assets

└── vendor/bundle/     # Gem dependencies

```

## 🎯 Key Features

### Rails Applications
- **Multi-tenant architecture** with `acts_as_tenant`
- **7 production apps** on OpenBSD infrastructure
- **40+ domain support** through brgen platform
- **Zero-trust security** with comprehensive validation

### Multimedia Tools
- **dilla**: Music production with 808 synthesis, MIDI generation
- **postpro**: Image post-processing with ruby-vips
- **repligen**: AI image generation with LoRA workflow

### Infrastructure
- **OpenBSD 7.7** with pledge/unveil security
- **DNSSEC** with ECDSAP256SHA256
- **Let's Encrypt TLS** with automated renewal
- **PF firewall** with synproxy and rate limiting
- **Relayd** reverse proxy with OWASP headers

### Development Tools
- **Shell utilities** for tree listing, linting, security scans
- **Zero-trust validation** for all inputs
- **Continuous refactoring** built into workflow

## 📖 Getting Started

1. **Read**: [DEVELOPMENT.md](DEVELOPMENT.md) for complete setup
2. **Explore**: Run `sh/tree.sh .` to see structure
3. **Review**: Check `master.json` for project philosophy
4. **Contribute**: See [CONTRIBUTING.md](CONTRIBUTING.md)

## 🔒 Security

This project follows zero-trust security principles. See [SECURITY.md](SECURITY.md) for:
- Vulnerability reporting
- Security measures
- Cryptography standards
- Authentication requirements

**Never commit secrets or credentials!**

## 🤝 Contributing

We welcome contributions! Please:

1. Read [CONTRIBUTING.md](CONTRIBUTING.md)
2. Follow the development workflow
3. Run tests and quality gates
4. Submit focused pull requests

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for community standards.

## 📝 License

Proprietary - All rights reserved. See [LICENSE](LICENSE) for details.

## 📞 Contact

- **GitHub**: [@anon987654321](https://github.com/anon987654321)
- **Domain**: brgen.no
- **DNS**: ns.brgen.no (primary), ns.hyp.net (secondary)

## 🔗 Links

- [Issue Tracker](https://github.com/anon987654321/pub3/issues)
- [Security Advisories](https://github.com/anon987654321/pub3/security)
- [Changelog](CHANGELOG.md)

---

**Version**: 502.0.0  
**Last Updated**: 2025-10-16  
**Rails**: 8.0.0 | **Ruby**: 3.3.0 | **OpenBSD**: 7.7

