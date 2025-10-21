# OpenBSD Native Operations Guide for Claude Code

This guide provides detailed instructions for using OpenBSD native tools and avoiding non-native patterns when working with the pub3 project deployed on OpenBSD 7.6.

## Philosophy

OpenBSD emphasizes security, correctness, and simplicity. The base system includes well-audited, minimal tools. We prefer these over third-party alternatives to:

- **Reduce attack surface**: Fewer dependencies, less code to audit
- **Ensure consistency**: Match production environment exactly
- **Leverage security**: OpenBSD tools are rigorously audited
- **Maintain simplicity**: Avoid sprawl and complexity

## Service Management with rcctl

OpenBSD uses `rcctl` for service management (not systemd or other init systems).

### Common Operations

````zsh
# Enable service to start at boot
doas rcctl enable postgresql

# Start a service
doas rcctl start postgresql

# Stop a service
doas rcctl stop postgresql

# Restart a service
doas rcctl restart postgresql

# Check if service is running
doas rcctl check postgresql

# Show status of all enabled services
doas rcctl ls on

# Show all available services
doas rcctl ls all

# Show failed services
doas rcctl ls failed
````

### Example: Managing Rails Application Services

````zsh
# Enable and start PostgreSQL
doas rcctl enable postgresql
doas rcctl start postgresql

# Enable and start our Rails app (assuming custom rc.d script)
doas rcctl enable falcon_brgen
doas rcctl start falcon_brgen

# Check status
doas rcctl check postgresql
doas rcctl check falcon_brgen
````

## Package Management

OpenBSD uses `pkg_add`, `pkg_info`, and `pkg_delete` (not apt, yum, or brew).

### Installing Packages

````zsh
# Install a package
doas pkg_add ruby

# Install specific version
doas pkg_add ruby%3.3

# Install multiple packages
doas pkg_add postgresql-server postgresql-client

# Install with verbose output
doas pkg_add -v nginx
````

### Querying Packages

````zsh
# Search for packages
pkg_info -Q postgresql

# Show installed packages
pkg_info

# Show details of installed package
pkg_info postgresql-server

# Show which package owns a file
pkg_info -E /usr/local/bin/ruby33
````

### Removing Packages

````zsh
# Remove a package
doas pkg_delete ruby

# Remove unused dependencies
doas pkg_delete -a
````

## System Updates

### Security Patches with syspatch

````zsh
# Check for available patches
syspatch -c

# Apply all available patches
doas syspatch

# Apply patches with verbose output
doas syspatch -v

# Revert the most recent patch (if needed)
doas syspatch -R
````

### System Upgrades with sysupgrade

````zsh
# Upgrade to next release
doas sysupgrade

# Upgrade to specific snapshot
doas sysupgrade -s

# Check what would be upgraded (dry run)
doas sysupgrade -n
````

## Firewall Management with pfctl

OpenBSD uses `pf` (Packet Filter), configured via `/etc/pf.conf`.

### Common Operations

````zsh
# Reload firewall rules
doas pfctl -f /etc/pf.conf

# Enable firewall
doas pfctl -e

# Disable firewall
doas pfctl -d

# Show current ruleset
doas pfctl -s rules

# Show NAT rules
doas pfctl -s nat

# Show current state table
doas pfctl -s states

# Show statistics
doas pfctl -s info

# Flush all rules and states
doas pfctl -F all

# Flush only states
doas pfctl -F states

# Test config without loading
doas pfctl -nf /etc/pf.conf
````

### Example pf.conf snippet

````
# Block by default
block all

# Allow SSH on custom port
pass in on egress proto tcp to port 31415

# Allow HTTP/HTTPS
pass in on egress proto tcp to port {80, 443}

# Allow PostgreSQL from localhost only
pass in on lo0 proto tcp to port 5432
````

## Load Balancing with relayd

OpenBSD's `relayd` provides load balancing and reverse proxy functionality.

### Managing relayd

````zsh
# Reload configuration
doas relayctl reload

# Show summary
doas relayctl show summary

# Show all hosts
doas relayctl show hosts

# Show redirects
doas relayctl show redirects

# Show relays
doas relayctl show relays

# Show sessions
doas relayctl show sessions
````

## DNS with nsd

OpenBSD typically uses `nsd` (Name Server Daemon) for authoritative DNS.

### Managing nsd

````zsh
# Reload zones
doas nsd-control reload

# Reload specific zone
doas nsd-control reload example.com

# Reconfig (reload nsd.conf)
doas nsd-control reconfig

# Show status
doas nsd-control status

# Show statistics
doas nsd-control stats
````

## TLS Certificates with acme-client

OpenBSD includes `acme-client` for Let's Encrypt certificates.

### Obtaining/Renewing Certificates

````zsh
# Obtain or renew certificate
doas acme-client -v example.com

# Renew all domains in /etc/acme-client.conf
doas acme-client -v
````

### Automation via cron

Add to `/etc/crontab`:

````
0 2 * * * root acme-client example.com && rcctl reload relayd
````

## Virtualization with vmctl

OpenBSD's `vmm` hypervisor is managed with `vmctl`.

### VM Operations

````zsh
# List VMs
doas vmctl status

# Start a VM
doas vmctl start myvm

# Stop a VM
doas vmctl stop myvm

# Create a VM
doas vmctl create -s 20G mydisk.img

# Console into VM
doas vmctl console myvm
````

## Cryptographic Signing with signify

OpenBSD uses `signify` for cryptographic signing and verification.

### Verifying Downloads

````zsh
# Verify file signature
signify -C -p /etc/signify/openbsd-76-base.pub -x SHA256.sig file.tgz

# Generate key pair
signify -G -p pubkey.pub -s seckey.sec

# Sign a file
signify -S -s seckey.sec -m message.txt

# Verify signature
signify -V -p pubkey.pub -m message.txt
````

## Networking

### Interface Configuration with ifconfig

````zsh
# Show all interfaces
ifconfig

# Show specific interface
ifconfig em0

# Configure IP address
doas ifconfig em0 192.168.1.10 netmask 255.255.255.0

# Enable interface
doas ifconfig em0 up

# Create VLAN
doas ifconfig vlan0 create
doas ifconfig vlan0 vnetid 100 parent em0
````

### Routing

````zsh
# Show routing table
netstat -rn

# Add route
doas route add -net 10.0.0.0/8 192.168.1.1

# Delete route
doas route delete -net 10.0.0.0/8

# Set default gateway
doas route add default 192.168.1.1
````

### Network Statistics

````zsh
# Show connections
netstat -an

# Show interface statistics
netstat -i

# Show protocol statistics
netstat -s

# Live system monitor
systat vmstat

# Network traffic
systat netstat
````

## System Introspection

### Kernel Parameters with sysctl

````zsh
# Show all kernel parameters
sysctl -a

# Show specific parameter
sysctl kern.version

# Set parameter (temporary)
doas sysctl net.inet.ip.forwarding=1

# Set parameter (permanent, add to /etc/sysctl.conf)
echo "net.inet.ip.forwarding=1" | doas tee -a /etc/sysctl.conf
````

### System Messages with dmesg

````zsh
# Show all boot messages
dmesg

# Show recent messages
dmesg | tail -50

# Monitor for new messages
dmesg -w
````

### Manual Pages

````zsh
# Read manual page
man rcctl

# Search manual pages
apropos firewall

# Show all man pages for a command
man -k ssh

# Open man page in specific section
man 5 pf.conf
````

## Shell Scripting: Modern zsh Patterns

OpenBSD includes `ksh` by default, but we use `zsh` for scripting. **Always avoid bashisms and prefer zsh builtins.**

### String Manipulation

````zsh
# Bad: using sed
filename=$(echo "$path" | sed 's/\.txt$/.bak/')

# Good: parameter expansion
filename="${path%.txt}.bak"

# Uppercase
upper="${var:u}"

# Lowercase
lower="${var:l}"

# Replace first occurrence
new="${var/old/new}"

# Replace all occurrences
new="${var//old/new}"
````

### File Operations

````zsh
# Bad: using find
for file in $(find . -name "*.rb"); do
  echo "$file"
done

# Good: glob patterns
for file in **/*.rb; do
  [[ -f $file ]] && print "$file"
done

# Match files only (not directories)
for file in **/*.rb(N.); do
  print "$file"
done
````

### Conditionals

````zsh
# Bad: old test syntax
if [ -f "$file" ]; then
  echo "exists"
fi

# Good: modern [[ ]]
if [[ -f $file ]]; then
  print "exists"
fi

# Pattern matching
if [[ $file == *.rb ]]; then
  print "Ruby file"
fi
````

### Arrays

````zsh
# Bad: parsing ls output
files=($(ls))

# Good: glob into array
files=(*.txt)

# Array length
print ${#files}

# Array element
print ${files[1]}

# Array slice
print ${files[2,4]}

# Join array
IFS=:
joined="${files[*]}"
````

### Reading Files

````zsh
# Bad: cat | grep
cat file.txt | grep pattern

# Good: redirect input
grep pattern < file.txt

# Even better: pass file as argument
grep pattern file.txt

# Read file into variable
content=$(<file.txt)
````

### Loops

````zsh
# Bad: seq
for i in $(seq 1 10); do
  echo $i
done

# Good: brace expansion
for i in {1..10}; do
  print $i
done

# Zsh-style loop
for ((i=1; i<=10; i++)); do
  print $i
done
````

## Rails Application Deployment

### Setting Up Rails Environment

````zsh
# Install Ruby
doas pkg_add ruby%3.3

# Install bundler
gem install bundler

# Install Rails dependencies
cd /home/dev/brgen
bundle install

# Database setup
bundle exec rails db:create
bundle exec rails db:migrate

# Precompile assets
bundle exec rails assets:precompile
````

### Running Rails with Falcon

````zsh
# Start Falcon server
bundle exec falcon serve -b http://localhost:11006

# Start as daemon
bundle exec falcon serve -b http://localhost:11006 -d

# With environment
RAILS_ENV=production bundle exec falcon serve -b http://localhost:11006
````

### Database Operations

````zsh
# PostgreSQL commands
doas rcctl start postgresql

# Connect to database
psql -U postgres -d brgen_production

# Backup database
pg_dump -U postgres brgen_production | gzip > backup.sql.gz

# Restore database
gunzip < backup.sql.gz | psql -U postgres brgen_production
````

## Common Pitfalls to Avoid

### Don't Use These Tools

- **docker**: Use vmctl for virtualization
- **systemd**: Use rcctl for service management
- **bash**: Use zsh or ksh
- **gsed/gawk/ggrep**: Use built-in sed/awk/grep or prefer zsh
- **python**: Prefer Ruby for scripting per project policy

### Why Avoid GNU Tools?

GNU tools (gsed, gawk, ggrep) have different flags and behaviors than OpenBSD base tools. Using them creates:
- Additional dependencies (pkg_add required)
- Portability issues (scripts break on base system)
- Inconsistency (mixing tool flavors)
- Security concerns (larger codebase, less audited)

### Prefer Base System

OpenBSD base system includes:
- `sed`, `awk`, `grep` (POSIX-compliant versions)
- `ksh` (Korn shell, POSIX-compliant)
- `zsh` (available via pkg_add, our scripting standard)
- Standard UNIX tools: `cut`, `sort`, `uniq`, etc.

But we prefer **zsh parameter expansion and builtins** over these when possible.

## Ruby Automation Examples

### System Administration Script

````ruby
#!/usr/bin/env ruby
# check_services.rb - Monitor critical services

require 'open3'

CRITICAL_SERVICES = %w[postgresql falcon relayd pf nsd]

def service_running?(name)
  stdout, stderr, status = Open3.capture3("doas rcctl check #{name}")
  status.success?
end

def restart_service(name)
  puts "Restarting #{name}..."
  system("doas rcctl restart #{name}")
end

CRITICAL_SERVICES.each do |service|
  unless service_running?(service)
    puts "ERROR: #{service} is not running!"
    restart_service(service)
  else
    puts "OK: #{service} is running"
  end
end
````

### Deployment Script

````ruby
#!/usr/bin/env ruby
# deploy.rb - Deploy Rails application

require 'fileutils'

APP_DIR = '/home/dev/brgen'
APP_USER = 'dev'

def run_command(cmd, description)
  puts ">>> #{description}"
  system(cmd) || abort("Failed: #{description}")
end

Dir.chdir(APP_DIR) do
  run_command('git pull origin main', 'Pull latest code')
  run_command('bundle install', 'Install dependencies')
  run_command('bundle exec rails db:migrate', 'Run migrations')
  run_command('bundle exec rails assets:precompile', 'Precompile assets')
  run_command('doas rcctl restart falcon_brgen', 'Restart application')
end

puts "\n✓ Deployment complete!"
````

## Security Best Practices

### Use doas, not sudo

OpenBSD uses `doas` (simpler than sudo):

````
# /etc/doas.conf
permit persist :wheel
permit nopass dev as root cmd rcctl
````

### Keep System Updated

````zsh
# Regular update routine
doas syspatch
doas pkg_add -u
````

### Minimal Services

- Only run necessary services
- Use `rcctl disable` for unused services
- Review `rcctl ls all` regularly

### Firewall Rules

- Default deny policy
- Explicit allow rules
- Regular audit of `pfctl -s rules`

## Monitoring and Logs

### System Logs

````zsh
# System log
tail -f /var/log/messages

# Daemon log
tail -f /var/log/daemon

# Rails logs
tail -f /home/dev/brgen/log/production.log
````

### Monitoring Tools

````zsh
# System monitor
top

# Interactive system monitor
systat vmstat

# Disk usage
df -h

# Memory usage
vmstat -s
````

## Quick Reference

### Essential Commands Cheat Sheet

| Task | Command |
|------|---------|
| Start service | `doas rcctl start name` |
| Enable service | `doas rcctl enable name` |
| Install package | `doas pkg_add name` |
| Update system | `doas syspatch` |
| Reload firewall | `doas pfctl -f /etc/pf.conf` |
| Check firewall | `doas pfctl -s rules` |
| Reload web config | `doas relayctl reload` |
| DNS reload | `doas nsd-control reload` |
| Renew TLS cert | `doas acme-client -v domain` |
| Show interfaces | `ifconfig` |
| Show routes | `netstat -rn` |
| System log | `tail -f /var/log/messages` |

## Additional Resources

- OpenBSD FAQ: https://www.openbsd.org/faq/
- OpenBSD man pages: https://man.openbsd.org/
- pf User's Guide: https://www.openbsd.org/faq/pf/
- Rails on OpenBSD: Community guides and forums

---

**Remember**: When in doubt, check the OpenBSD man pages (`man command`) - they are comprehensive and authoritative.
