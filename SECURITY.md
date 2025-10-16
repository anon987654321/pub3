# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| Current | :white_check_mark: |
| Older   | :x:                |

We only support the latest version of the codebase. Please ensure you're using the most recent commit from the main branch.

## Security Philosophy

This project follows zero-trust security principles as defined in `master.json`:

- **verify_never_trust_assume_breach**
- All inputs are validated and sanitized
- Credentials never logged or committed
- Defense in depth with multiple layers
- Regular security audits and updates

## Reporting a Vulnerability

**DO NOT** open public issues for security vulnerabilities.

### How to Report

1. **Email**: Contact maintainers privately through GitHub
2. **GitHub Security Advisory**: Use the "Security" tab to report privately
3. **Provide Details**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity
  - Critical: 24-48 hours
  - High: 7 days
  - Medium: 30 days
  - Low: Best effort

## Security Measures

### Input Validation

- HTML sanitization using `sanitize` gem
- SQL injection protection via parameterized queries
- XSS prevention through proper escaping
- CSRF tokens on all state-changing operations

### Cryptography

- **At rest**: AES-256-GCM
- **In transit**: TLS 1.3
- **Passwords**: Argon2id (64MB, 3 iterations)
- **Key rotation**: Quarterly

### Authentication

- Multi-factor authentication required
- Session lifetime: 15 minutes
- Password minimum: 12 characters
- Rate limiting: 5 attempts per 15 minutes

### Security Headers

All web applications use OWASP secure headers:

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'; script-src 'self' 'strict-dynamic'
```

### Infrastructure Security

- **OpenBSD**: pledge/unveil for privilege separation
- **Firewall**: pf with synproxy, rate limiting, bruteforce detection
- **TLS**: Let's Encrypt with automated renewal
- **DNSSEC**: ECDSAP256SHA256 algorithm

## Security Tools

We use:

- **brakeman**: Rails security scanner
- **bundler-audit**: Dependency vulnerability checking
- **semgrep**: Static analysis
- **trivy**: Container and dependency scanning

Run security scan:

```bash
cd sh
./security_scan.sh
```

## Known Security Features

### OpenBSD Deployment

- Privilege separation via unveil/pledge
- Memory protection with W^X
- Kernel ASLR and stack protection
- Minimal attack surface

### Rails Applications

- Strong parameters required
- SQL injection protection
- XSS protection via auto-escaping
- CSRF protection enabled
- Secure session cookies

### Shell Scripts

- Strict mode: `set -euo pipefail`
- Input validation
- Path sanitization
- No eval/exec of user input

## Security Best Practices

When contributing:

1. **Never commit**:
   - Passwords or API keys
   - Private keys or certificates
   - Session secrets
   - Database credentials

2. **Always**:
   - Validate user input
   - Sanitize HTML output
   - Use parameterized queries
   - Enable CSRF protection
   - Set secure headers

3. **Review**:
   - Dependencies for vulnerabilities
   - Code for injection vectors
   - Configuration for exposed secrets
   - Logs for sensitive data

## Security Checklist

Before deploying:

- [ ] All secrets in environment variables
- [ ] HTTPS/TLS enabled and enforced
- [ ] Security headers configured
- [ ] Input validation in place
- [ ] CSRF protection enabled
- [ ] Rate limiting configured
- [ ] Logging excludes sensitive data
- [ ] Dependencies updated
- [ ] Security scan passed
- [ ] Penetration testing completed

## Disclosure Policy

Once a vulnerability is fixed:

1. We will credit the reporter (if desired)
2. We will publish a security advisory
3. We will document the fix in CHANGELOG.md

## Contact

For security concerns:
- GitHub Security Advisory (preferred)
- Private issue to maintainers
- GitHub: @anon987654321

Thank you for helping keep pub3 secure.
