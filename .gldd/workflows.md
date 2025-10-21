# Development Workflows

This document describes common development workflows for the pub3 repository.

## Architecture Overview

```
master.json (Governance - Single Source of Truth)
    ↓ reads config
openbsd/openbsd.sh (Deployment Orchestrator)
    ↓ calls with ports
rails/__install_all.sh (Parallel Installer)
    ↓ executes each
rails/*.sh (Individual App Installers)
    ↓ sources
rails/__shared/@common.sh + feature modules
```

## Creating a New Rails Application

### 1. Create Installer Script

```zsh
cd rails/
vim myapp.sh
```

**Template structure**:
```zsh
#!/usr/bin/env zsh
set -euo pipefail

# Source common utilities
source "$(dirname "$0")/__shared/@common.sh"

# Optional: Source feature modules
source "$(dirname "$0")/__shared/@reddit_features.sh"

# App configuration
APP_NAME="myapp"
PORT="${1:-3012}"  # Accept port as argument
DOMAINS="myapp.com"

# Generate Rails app
generate_app() {
  rails new "$APP_NAME" \
    --database=postgresql \
    --css=sass \
    --javascript=importmap
  
  cd "$APP_NAME"
  
  # Add gems via heredoc
  cat >> Gemfile <<'EOF'
gem "stimulus_reflex", "~> 3.5"
gem "pagy", "~> 6.0"
EOF
  
  bundle install
  
  # Generate models, controllers, views via heredocs
  # (See existing installers for patterns)
}

# Main execution
generate_app
```

### 2. Add to master.json

Edit `master.json` deployment.installers array:

```json
{
  "n": "myapp",
  "port": 10008,
  "size": "25KB",
  "generates": "~1500_lines",
  "domains": ["myapp.com"],
  "type": "standalone",
  "status": "development",
  "https": false
}
```

### 3. Add to openbsd.sh

Edit `openbsd/openbsd.sh` app_domains:

```zsh
app_domains=(
  ["myapp:10008"]="myapp.com"
  # ... other apps
)
```

### 4. Add to __install_all.sh

Edit `rails/__install_all.sh` APPS array:

```zsh
APPS=(
  "myapp:10008"
  # ... other apps
)
```

### 5. Create README

```zsh
vim rails/myapp_README.md
```

## Deploying to VPS

### Pre-deployment Checklist

```zsh
# 1. Validate installer
cd rails/
./validate_installers.sh

# 2. Test locally
./myapp.sh 3012

# 3. Check Rails app starts
cd myapp/
bin/rails server

# 4. Run tests (if any)
bin/rails test
```

### Deployment Process

**On VPS (server27.openbsd.amsterdam)**:

```zsh
# SSH to VPS
ssh -p 31415 dev@185.52.176.18

# Navigate to deployment directory
cd /var/rails

# Pull latest code
git pull origin main

# Run pre-point setup (infrastructure + apps)
doas ./openbsd/openbsd.sh --pre-point

# Wait for DNS propagation (~1-24 hours)
dig @ns.brgen.no myapp.com

# Run post-point setup (TLS + relayd)
doas ./openbsd/openbsd.sh --post-point

# Verify app is running
curl http://localhost:10008/up
```

### Parallel Deployment (All Apps)

```zsh
# Deploy all apps simultaneously
cd /var/rails/rails
./install_all.sh

# Check logs
tail -f *_install.log
```

## Working with Feature Modules

### Available Modules

Located in `rails/__shared/`:

- **@common.sh** - Core utilities (25KB)
- **@features_base.sh** - Base framework (2.3KB)
- **@reddit_features.sh** - Voting, karma, comments (15KB)
- **@twitter_features.sh** - Retweets, follows, timeline (15KB)
- **@airbnb_features.sh** - Bookings, reviews, hosts (20KB)
- **@momondo_features.sh** - Flights, hotels, alerts (18KB)
- **@messenger_features.sh** - DMs, typing, read receipts (20KB)

### Using Feature Modules

```zsh
# In your installer script
source "$(dirname "$0")/__shared/@common.sh"
source "$(dirname "$0")/__shared/@reddit_features.sh"

# Call feature functions
generate_voting_system
generate_karma_tracking
generate_comment_threads
```

## Database Migrations

### Creating Migrations

```ruby
# In installer script
rails generate migration AddColumnToModel column:type

# Or via heredoc
cat > db/migrate/$(date +%Y%m%d%H%M%S)_migration_name.rb <<'EOF'
class MigrationName < ActiveRecord::Migration[8.0]
  def change
    add_column :table, :column, :type
  end
end
EOF
```

### Running Migrations

```zsh
bin/rails db:migrate
bin/rails db:seed
```

## Testing Workflow

### Unit Tests

```zsh
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/user_test.rb

# Run specific test
bin/rails test test/models/user_test.rb:42
```

### System Tests

```zsh
# Run system tests (requires Chrome/Firefox)
bin/rails test:system
```

## Stimulus & StimulusReflex Development

### Creating Stimulus Controller

```zsh
# Via Rails generator
bin/rails generate stimulus controller_name

# Or manually
mkdir -p app/javascript/controllers
cat > app/javascript/controllers/feature_controller.js <<'EOF'
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Feature controller connected")
  }
}
EOF
```

### Creating Reflex

```zsh
# Via generator
bin/rails generate stimulus_reflex Feature

# Or manually
mkdir -p app/reflexes
cat > app/reflexes/feature_reflex.rb <<'EOF'
class FeatureReflex < ApplicationReflex
  def action
    # Access: element, params, session, current_user
    morph "#target", render(partial: "path/to/partial")
  end
end
EOF
```

### Testing Real-time Features

1. Start Rails server: `bin/rails server`
2. Start Solid Cable: `bin/rails solid_cable:start`
3. Open browser to `http://localhost:3000`
4. Open browser console to see WebSocket activity
5. Trigger reflex actions and watch DOM morphing

## Git Workflow

### Branch Strategy

```zsh
# Create feature branch
git checkout -b feature/new-app

# Make changes
git add .
git commit -m "Add new app installer"

# Push to GitHub
git push origin feature/new-app

# Create pull request via GitHub UI
```

### Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

**Example**:
```
feat: Add mytoonz Rails installer

- Create mytoonz.sh with heredoc templates
- Add to master.json deployment.installers
- Configure port 10008 in openbsd.sh
- Add mytoonz_README.md documentation

Closes #123
```

## Validation & Quality Gates

### Pre-commit Checks

```zsh
# Validate installers
rails/validate_installers.sh

# Check JSON syntax
jq empty master.json

# Lint shell scripts (if shellcheck available)
shellcheck rails/*.sh openbsd/*.sh
```

### Quality Metrics (from master.json)

Must maintain:
- **Coverage**: ≥90%
- **Complexity**: ≤10
- **Duplication**: ≤3%
- **Method length**: ≤20 lines
- **Class length**: ≤300 lines
- **Parameters**: ≤3 per method
- **Chain depth**: ≤3 levels
- **File size**: ≤100KB

## Troubleshooting

### Installer Won't Run

```zsh
# Check shebang
head -1 rails/myapp.sh

# Check permissions
chmod +x rails/myapp.sh

# Check for syntax errors
zsh -n rails/myapp.sh
```

### App Won't Start

```zsh
# Check logs
tail -f log/development.log

# Check database connection
bin/rails db:migrate:status

# Check dependencies
bundle check

# Restart Rails server
pkill -f "rails server"
bin/rails server
```

### Port Conflicts

```zsh
# Check what's using a port
lsof -i :3000

# Kill process
kill -9 <PID>

# Use different port
bin/rails server -p 3001
```

### PostgreSQL Issues

```zsh
# Check PostgreSQL is running
psql -l

# Create database
bin/rails db:create

# Reset database (CAUTION: destroys data)
bin/rails db:reset
```

## Monitoring & Maintenance

### Log Locations

- **Rails logs**: `log/*.log`
- **System logs**: `/var/log/rails/`
- **Deployment logs**: `rails/*_install.log`

### Health Checks

```zsh
# Check app health
curl http://localhost:3000/up

# Check all apps
for port in 11006 10002 10003 10004 10005 10006 10007; do
  echo "Port $port:"
  curl -s http://localhost:$port/up || echo "DOWN"
done
```

### Backups

From `master.json`:
- **Provider**: Tarsnap
- **Frequency**: Daily
- **Retention**: 30 days
- **Targets**: database, uploads, config, logs
- **Verification**: Weekly

## References

- **Master configuration**: `master.json`
- **Deployment script**: `openbsd/openbsd.sh`
- **Parallel installer**: `rails/__install_all.sh`
- **Feature modules**: `rails/__shared/@*.sh`
- **Code style**: `.gldd/code-style.md`
- **Stimulus guide**: `.gldd/stimulus.md`
