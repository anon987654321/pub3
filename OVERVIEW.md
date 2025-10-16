# Project Overview

## Introduction

**pub3** is a comprehensive multi-project repository combining Rails applications, multimedia tools, OpenBSD infrastructure, and development utilities. It embodies a philosophy of clarity, security, and maintainability.

## Philosophy

Defined in `master.json`, the project follows these core principles:

- **internalize→secure→prove→remove→optimize** - The development lifecycle
- **questions > commands** - Understanding before action
- **evidence > opinion** - Data-driven decisions
- **execution > explanation** - Results over talk
- **clarity > cleverness** - Simple, maintainable solutions

## Project Components

### 1. Rails Applications (rails/)

Multi-tenant web platforms built on Rails 8 with OpenBSD deployment:

- **brgen** (11006) - Multi-tenant platform for 40+ Norwegian city domains
- **amber** (10001) - Social amber alert system
- **blognet** (10002) - Decentralized blogging network
- **bsdports** (10003) - OpenBSD ports tracking and management
- **hjerterom** (10004) - Private mental health journaling
- **privcam** (10005) - Privacy-focused camera/media platform
- **pubattorney** (10006) - Legal services platform

**Technologies:**
- Rails 8.0 with Hotwire/Turbo/Stimulus
- Multi-tenancy via `acts_as_tenant`
- PostgreSQL with zero-trust security
- Redis for caching and background jobs

### 2. Multimedia Tools (multimedia/)

Professional audio, image, and AI generation tools:

#### Dilla (Music Production)
- 808 drum synthesis
- MIDI generation with chord theory
- Multi-track rendering
- Effects processing with SoX

#### PostPro (Image Processing)
- Camera RAW processing
- Recipe-based transformations
- Ruby-vips powered
- Batch processing support

#### RepLigen (AI Image Generation)
- Stable Diffusion workflow
- LoRA model support
- Masterpiece-oriented pipeline
- ComfyUI integration

### 3. OpenBSD Infrastructure (openbsd/)

Production-grade deployment scripts and configuration:

- **Two-phase deployment** (pre/post DNS)
- **DNSSEC** with ECDSAP256SHA256
- **PF firewall** with synproxy, rate limiting, bruteforce protection
- **Relayd** reverse proxy with OWASP headers
- **NSD** authoritative DNS server
- **Let's Encrypt** TLS with automated renewal

**Security Features:**
- pledge/unveil privilege separation
- Zero-trust input validation
- W^X memory protection
- Kernel ASLR

### 4. Shell Utilities (sh/)

Development and system administration tools:

- **tree.sh** - Directory structure listing (pure zsh)
- **lint.sh** - Code quality checks
- **security_scan.sh** - Vulnerability scanning
- **nmap.sh** - Network mapping with i18n
- **clean.sh** - Artifact cleanup

**Design Philosophy:**
- Pure zsh builtins (no external commands)
- Parameter expansion over sed/awk
- 20-50% code reduction target

### 5. Business Plans (bplans/)

Comprehensive business planning documentation following master.json governance:

- Evidence-based projections
- Four critical factors analysis
- Adversarial review methodology
- Execution-focused structure

## Architecture Patterns

### Zero-Trust Security

Every layer implements zero-trust principles:

1. **Input Validation**
   - HTML sanitization (sanitize gem)
   - SQL injection prevention
   - XSS protection
   - CSRF tokens

2. **Cryptography**
   - At rest: AES-256-GCM
   - In transit: TLS 1.3
   - Passwords: Argon2id (64MB, 3 iterations)

3. **Authentication**
   - Multi-factor required
   - 15-minute session lifetime
   - Rate limiting (5/15min)

### Multi-Tenant Architecture

Rails applications use `acts_as_tenant` for isolation:

- Tenant-scoped queries
- Shared codebase, isolated data
- Per-tenant configuration
- Domain-based tenant detection

### Progressive Enhancement

UI follows three-layer approach:

1. **Layer 0**: Semantic HTML (100ms TTI)
2. **Layer 1**: Minimal CSS (200ms FCP)
3. **Layer 2**: Minimal JS (50ms FID)

### Continuous Refactoring

Every file touch triggers quality checks:

- Apply all principles from master.json
- Run quality gates
- Validate no regressions
- Iterate until convergence

## Development Workflow

### Phases

1. **Discover** - Define problem with evidence
2. **Analyze** - Identify constraints and risks
3. **Ideate** - Generate 15+ alternatives
4. **Design** - Create minimal viable solution
5. **Implement** - TDD with continuous refactoring
6. **Validate** - Run quality gates
7. **Deliver** - Deploy with monitoring
8. **Learn** - Capture insights, update governance

### Quality Gates

All code must pass:

- **Functional**: Tests pass, 80%+ coverage
- **Secure**: No vulnerabilities, inputs validated
- **Maintainable**: Complexity ≤ 10, no duplication
- **Accessible**: WCAG AA compliance
- **Performant**: LCP < 2.5s

## Technology Stack

### Languages
- Ruby 3.3.0+ (Rails apps, multimedia tools)
- JavaScript ES6+ (Frontend)
- Python 3.13+ (AI/ML tools)
- Zsh 5.9+ (Scripts)

### Frameworks
- Rails 8.0 (Web applications)
- Hotwire/Turbo/Stimulus (Frontend)
- Falcon (Async HTTP server)

### Databases
- PostgreSQL 14+ (Primary)
- Redis 6+ (Cache/jobs)

### Infrastructure
- OpenBSD 7.7+ (Production)
- NSD (DNS)
- Relayd (Reverse proxy)
- PF (Firewall)

### Tools
- RuboCop (Ruby linting)
- Brakeman (Security scanning)
- Bundler Audit (Dependency checks)
- ShellCheck (Shell linting)

## Project Metrics

### Complexity Limits
- Cyclomatic complexity: ≤ 10
- Coupling: ≤ 5 dependencies
- Duplication: ≤ 3%
- Nesting depth: ≤ 4 levels
- Test coverage: ≥ 80%

### Performance Targets
- LCP (Largest Contentful Paint): < 2.5s
- INP (Interaction to Next Paint): < 200ms
- CLS (Cumulative Layout Shift): < 0.1

## Governance

### master.json

Central configuration defining:

- Modification rules (requires express permission)
- Principles (38 total)
- Intelligence (11 adversarial personas)
- Execution phases (8 phases)
- Quality gates and metrics
- Standards and tools

### Versioning Strategy

- **Major**: Breaking changes to structure/rules
- **Minor**: New features or sections
- **Patch**: Bug fixes, clarifications

Current version: **502.0.0**

## Getting Started

1. **Read**: [DEVELOPMENT.md](DEVELOPMENT.md) for setup
2. **Explore**: Run `make tree` to see structure
3. **Review**: Study `master.json` for philosophy
4. **Contribute**: Follow [CONTRIBUTING.md](CONTRIBUTING.md)

## Resources

### Documentation
- [README.md](README.md) - Quick overview
- [DEVELOPMENT.md](DEVELOPMENT.md) - Setup guide
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [SECURITY.md](SECURITY.md) - Security policy
- [CHANGELOG.md](CHANGELOG.md) - Version history

### External Resources
- [OpenBSD man pages](https://man.openbsd.org/)
- [Rails Guides](https://guides.rubyonrails.org/)
- [Ruby Documentation](https://ruby-doc.org/)

## License

Proprietary - All rights reserved. See [LICENSE](LICENSE) for details.

## Contact

- **GitHub**: [@anon987654321](https://github.com/anon987654321)
- **Issues**: [GitHub Issues](https://github.com/anon987654321/pub3/issues)
- **Security**: [Security Policy](SECURITY.md)

---

**Last Updated**: 2025-10-16  
**Version**: 502.0.0
