# Contributing to pub3

Thank you for your interest in contributing to pub3. This document provides guidelines and instructions for contributing.

## Philosophy

This project follows the principles defined in `master.json`:

- **internalize→secure→prove→remove→optimize**
- questions > commands
- evidence > opinion
- execution > explanation
- clarity > cleverness

## Development Setup

### Prerequisites

- **Ruby**: 3.2+ (for Rails applications)
- **Node.js**: 20.x+ (for frontend tooling)
- **Python**: 3.13+ (for multimedia tools)
- **Zsh**: 5.9+ (for shell scripts)
- **OpenBSD**: 7.7+ (for production deployment)

### Local Setup

```bash
# Clone the repository
git clone https://github.com/anon987654321/pub3.git
cd pub3

# Ruby/Rails projects
cd rails
bundle install
rails db:create db:migrate
rails test

# Python multimedia tools
cd multimedia/repligen
pip install -r requirements.txt
python repligen.rb

# Shell utilities
cd sh
./tree.sh .
./lint.sh
```

## Code Standards

### Shell Scripts (Zsh)

- Use `set -euo pipefail` for strict mode
- Prefer zsh builtins over external commands
- Use parameter expansion instead of `sed`, `awk`, `cut`
- Example: `${var//old/new}` instead of `echo $var | sed 's/old/new/g'`

### Ruby

- Follow Rubocop guidelines
- Use double quotes for strings
- 2-space indentation
- Write tests with Minitest

### Rails

- Use Rails 8 conventions
- Follow Hotwire/Turbo/Stimulus patterns
- Use concerns and service objects appropriately
- Multi-tenant architecture with `acts_as_tenant`

### JavaScript

- Single quotes for strings
- Use semicolons
- Prefer `const` over `let`
- ES6+ syntax

## Project Structure

```
pub3/
├── master.json          # Central configuration and governance
├── README.md            # Main documentation
├── bplans/              # Business plans
├── multimedia/          # Audio/video/image tools
│   ├── dilla/          # Music production (Ruby)
│   ├── postpro/        # Image post-processing (Ruby)
│   └── repligen/       # AI image generation (Ruby)
├── openbsd/            # OpenBSD deployment scripts
├── rails/              # Rails application generators
└── sh/                 # Shell utilities
```

## Testing

Run tests before submitting:

```bash
# Shell scripts
cd sh
./lint.sh

# Ruby projects
cd multimedia/dilla
ruby -c master.rb

# Rails apps (in individual app directories)
bundle exec rails test
```

## Git Workflow

### Commit Messages

Follow semantic commit format:

```
type(scope): description

feat(dilla): add 808 drum synthesis
fix(repligen): correct LoRA weight calculation
docs(readme): update setup instructions
refactor(rails): extract service objects
test(postpro): add recipe validation tests
chore(deps): update ruby to 3.3.0
```

### Branch Naming

- `feature/description` - New features
- `fix/description` - Bug fixes
- `refactor/description` - Code refactoring
- `docs/description` - Documentation updates

### Pull Requests

1. Create a feature branch from `main`
2. Make focused, incremental changes
3. Write tests for new functionality
4. Update documentation as needed
5. Submit PR with clear description
6. Address review feedback

## Quality Gates

All code must pass:

- **Functional**: Tests pass, coverage ≥ 80%
- **Secure**: No vulnerabilities, input validated
- **Maintainable**: Complexity ≤ 10, no duplication
- **Accessible**: WCAG AA compliance for UI
- **Performant**: LCP < 2.5s for web apps

## Security

- Never commit secrets or credentials
- Use environment variables for configuration
- Validate all user input
- Follow zero-trust principles
- Report security issues privately (see SECURITY.md)

## Code Review

We look for:

- **Correctness**: Does it solve the problem?
- **Clarity**: Is it easy to understand?
- **Maintainability**: Will it be easy to change?
- **Minimal changes**: Smallest possible diff
- **Tests**: Are edge cases covered?

## Documentation

Update documentation when:

- Adding new features
- Changing APIs or interfaces
- Fixing bugs that affect usage
- Modifying configuration

## Questions?

- Review `master.json` for detailed governance
- Check existing code for patterns
- Read component-specific READMEs
- Open a discussion issue

## License

By contributing, you agree that your contributions will be licensed under the same terms as the project.
