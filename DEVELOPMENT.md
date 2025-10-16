# Development Guide

Complete guide for developing and contributing to pub3.

## Architecture Overview

pub3 is a multi-project repository containing:

- **Rails Applications**: Multi-tenant web platforms (brgen, amber, etc.)
- **Multimedia Tools**: Audio (dilla), image processing (postpro), AI generation (repligen)
- **Infrastructure**: OpenBSD deployment scripts and configuration
- **Shell Utilities**: Development and deployment tools

## Prerequisites

### System Requirements

- **Operating System**: macOS, Linux, OpenBSD, or Windows with Cygwin
- **Memory**: 4GB minimum, 8GB recommended
- **Disk**: 10GB free space
- **Network**: Internet access for dependencies

### Required Tools

```bash
# Ruby (via rbenv or rvm)
ruby --version  # Should be 3.2+

# Node.js (via nvm)
node --version  # Should be 20.x+

# Python (system or pyenv)
python --version  # Should be 3.13+

# Zsh
zsh --version  # Should be 5.9+

# PostgreSQL (for Rails apps)
psql --version  # Should be 14+

# Redis (for Rails background jobs)
redis-cli --version  # Should be 6+
```

## Project Setup

### Clone and Initialize

```bash
# Clone repository
git clone https://github.com/anon987654321/pub3.git
cd pub3

# Review master.json for project philosophy
cat master.json

# Explore project structure
sh/tree.sh .
```

### Rails Applications

```bash
cd rails

# Install dependencies
bundle install

# Setup database (for each app)
cd ~/brgen
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed

# Run tests
bundle exec rails test

# Start development server
bundle exec rails server -p 3000
```

### Multimedia Tools

#### Dilla (Music Production)

```bash
cd multimedia/dilla

# Dependencies
gem install midilib

# Test synthesis
ruby master.rb

# Render audio
./render_all.sh
```

#### PostPro (Image Processing)

```bash
cd multimedia/postpro

# Dependencies
gem install ruby-vips tty-prompt

# Run interactively
ruby postpro.rb

# Check recipes
ls recipes/
```

#### RepLigen (AI Image Generation)

```bash
cd multimedia/repligen

# Dependencies
pip install -r requirements.txt

# Run generation
ruby repligen.rb
```

### Shell Utilities

```bash
cd sh

# Tree utility (list directory structure)
./tree.sh /path/to/directory

# Lint shell scripts
./lint.sh

# Security scan
./security_scan.sh

# Network mapping
./nmap.sh
```

## Development Workflow

### 1. Start with Discovery

Before writing code:

```bash
# Read existing code
sh/tree.sh rails/brgen

# Understand dependencies
grep -r "require\|import\|include" .

# Check tests
find . -name "*_test.rb" -o -name "*_spec.rb"
```

### 2. Follow TDD

```bash
# Write test first
vim test/models/user_test.rb

# Run specific test
bundle exec rails test test/models/user_test.rb

# Implement feature
vim app/models/user.rb

# Verify
bundle exec rails test
```

### 3. Continuous Refactoring

Apply principles from `master.json`:

- **DRY**: Abstract at 3rd repetition
- **KISS**: Simplify complex code
- **YAGNI**: Remove unused code
- **SOLID**: Maintain low coupling

### 4. Quality Gates

Before committing:

```bash
# Run linters
rubocop
eslint .

# Run tests
bundle exec rails test
python -m pytest

# Check coverage
bundle exec rails test:coverage

# Security scan
./sh/security_scan.sh
```

## Testing

### Ruby/Rails

```bash
# All tests
bundle exec rails test

# Specific test file
bundle exec rails test test/models/user_test.rb

# Single test
bundle exec rails test test/models/user_test.rb:15

# With coverage
COVERAGE=true bundle exec rails test
```

### Shell Scripts

```bash
# Syntax check
zsh -n script.sh

# Shellcheck
shellcheck script.sh

# Run with tracing
zsh -x script.sh
```

### Python

```bash
# Unit tests
python -m pytest

# With coverage
python -m pytest --cov

# Type checking
mypy .
```

## Debugging

### Rails

```bash
# Start with debugger
bundle exec rails server

# Add breakpoint in code
debugger

# Console
bundle exec rails console

# Logs
tail -f log/development.log
```

### Ruby Scripts

```bash
# With debugger
ruby -r debug master.rb

# With verbose output
ruby -w master.rb

# Check syntax
ruby -c master.rb
```

### Shell Scripts

```bash
# Verbose mode
zsh -x script.sh

# Stop on error
zsh -e script.sh

# Trace execution
set -x
```

## Common Tasks

### Adding a New Rails App

```bash
cd rails

# Copy generator template
cp brgen.sh newapp.sh

# Modify for new app
vim newapp.sh

# Generate app
./newapp.sh

# Test locally
cd ~/newapp
bundle exec rails server
```

### Updating Dependencies

```bash
# Ruby gems
bundle update

# Node packages
npm update

# Python packages
pip install --upgrade -r requirements.txt
```

### Database Migrations

```bash
# Create migration
bundle exec rails generate migration AddFieldToModel

# Edit migration
vim db/migrate/YYYYMMDDHHMMSS_add_field_to_model.rb

# Run migration
bundle exec rails db:migrate

# Rollback if needed
bundle exec rails db:rollback

# Test migration
bundle exec rails db:migrate:redo
```

### Deployment to OpenBSD

```bash
# Phase 1: Pre-DNS setup
scp openbsd/openbsd.sh dev@brgen.no:/home/dev/
ssh dev@brgen.no
doas zsh openbsd.sh --pre-point

# Update DNS at registrar
# Wait for propagation

# Phase 2: Post-DNS setup
doas zsh openbsd.sh --post-point

# Verify services
rcctl ls on
rcctl check brgen amber blognet
```

## Performance Optimization

### Rails

```bash
# Profile controller action
bundle exec rails middleware

# Database query analysis
bundle exec rails dbconsole

# N+1 query detection
gem install bullet
```

### Asset Pipeline

```bash
# Precompile assets
bundle exec rails assets:precompile

# Check asset sizes
du -sh public/assets/*

# Analyze bundle
bundle exec rails assets:clobber
```

## Troubleshooting

### Common Issues

**Bundle install fails**:
```bash
# Clear bundler cache
bundle clean --force
rm -rf vendor/bundle
bundle install
```

**Database connection error**:
```bash
# Start PostgreSQL
pg_ctl start -D /usr/local/var/postgres

# Or on OpenBSD
rcctl start postgresql
```

**Port already in use**:
```bash
# Find process
lsof -i :3000

# Kill process
kill -9 PID
```

**Asset precompilation fails**:
```bash
# Clean assets
bundle exec rails assets:clobber

# Reinstall node modules
rm -rf node_modules
npm install
```

## Editor Configuration

### VS Code

```json
{
  "ruby.intellisense": "rubyLocate",
  "ruby.format": "rubocop",
  "editor.rulers": [80, 120],
  "files.trimTrailingWhitespace": true,
  "editor.formatOnSave": true
}
```

### Vim

```vim
" .vimrc
set expandtab
set shiftwidth=2
set softtabstop=2
set number
filetype plugin indent on
syntax on
```

## Resources

- **master.json**: Project philosophy and governance
- **README.md**: Project overview
- **CONTRIBUTING.md**: Contribution guidelines
- **OpenBSD man pages**: https://man.openbsd.org/
- **Rails Guides**: https://guides.rubyonrails.org/

## Getting Help

1. Check existing documentation
2. Search issues on GitHub
3. Review code examples in the repo
4. Open a discussion issue
5. Ask maintainers

## Best Practices

- Read `master.json` before making changes
- Follow the execution phases (discover → analyze → ideate → design → implement → validate → deliver → learn)
- Make minimal, focused changes
- Write tests before implementation
- Update documentation with code changes
- Run quality gates before committing
- Use semantic commit messages

## Next Steps

1. Complete project setup
2. Run all tests to verify environment
3. Pick an issue to work on
4. Follow TDD workflow
5. Submit focused pull request

Happy coding!
