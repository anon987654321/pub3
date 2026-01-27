# master.yml v0.6.1

Constitutional AI Governance for Ruby

A code quality enforcement system that applies constitutional AI principles through iterative scanning, evidence-based scoring, and automated remediation. Implements the preserve → improve → converge philosophy: preserve working code, improve quality through principled analysis, converge on stable excellence.

## Quick Start

```bash
# Installation
gem install syntax_tree diffy sqlite3

# Configuration
mkdir -p ~/.convergence
# Place master.yml in ~/.convergence/master.yml

# Basic usage
ruby cli.rb scan              # Scan for defects
ruby cli.rb evidence          # Calculate score
ruby cli.rb batch conservative # Automated improvement
ruby cli.rb dashboard         # Generate metrics
ruby cli.rb install-hook      # Git pre-commit hook
```

## Core Concepts

### Constitutional AI
Governance through defined principles and adversarial testing: principles (min 20), personas (min 6), adversarial tests (min 10), and self-preservation validation.

### Evidence Scoring
Multi-component quality metric: Tests 35%, Static 25%, Complexity 15%, Architecture 15%, Security 10%. Thresholds: Production ≥0.95, Development ≥0.90, Strict 1.00.

### Convergence Detection
Stability using 3-iteration window: system converges when score changes remain under 2% for three consecutive iterations.

## Commands

**scan** - AST-based defect detection: `ruby cli.rb scan [--verbose] [--json]`

**evidence** - Multi-component quality scoring: `ruby cli.rb evidence [--verbose]`

**batch [strategy]** - Automated improvement cycles:
- `conservative`: Safe, incremental fixes with validation
- `aggressive`: Faster, higher risk
- `continuous`: Run until convergence

**dashboard** - Generate HTML metrics visualization: `ruby cli.rb dashboard`

**install-hook** - Install git pre-commit hook: `ruby cli.rb install-hook`

**version** - Display version: `ruby cli.rb version`

**help** - Command reference: `ruby cli.rb help [command]`

## Configuration

```yaml
meta:
  version: "0.6.1"
  name: "project-name"

self_preservation:
  validate_on_start: true
  min_principles: 20
  min_personas: 6
  min_adversarial: 10

principles:
  - name: "No Injection Vulnerabilities"
    severity: "critical"
    enabled: true

catalog:
  defects:
    - id: "INJ001"
      name: "System Command Injection"
      pattern: "system\\(|exec\\(|`"
      severity: "critical"

severity:
  critical: 1.0
  high: 0.8
  medium: 0.5
  low: 0.2

evidence:
  weights:
    tests: 0.35
    static: 0.25
    complexity: 0.15
    architecture: 0.15
    security: 0.10
  thresholds:
    production: 0.95
    development: 0.90

personas:
  - name: "Security Auditor"
    focus: "vulnerabilities"

adversarial:
  - challenge: "Test coverage may not reflect runtime quality"
    counterpoint: "Integration tests validate behavior"

domain_constants:
  max_method_lines: 20
  max_class_lines: 300
  max_complexity: 10

batch_mode:
  conservative:
    max_changes_per_iteration: 5
    validation_required: true
```

Directory structure: `~/.convergence/` contains `master.yml`, `learning.db`, `logs/`, and `dashboard/`.

Configuration requires minimum 20 principles, 6 personas, and 10 adversarial tests.

## Detections

🔧 **Injection Vulnerabilities**: `system`, `exec`, `` ` ``, `spawn`, `IO.popen`, `IO.read`, `IO.write`, `eval`, `instance_eval`, `class_eval`, `module_eval`, `send`, `__send__`, `public_send`

🔧 **Hardcoded Secrets**: API keys, passwords, tokens in source code

🔧 **Magic Numbers**: Undocumented numeric literals

🔧 **Long Methods**: Methods exceeding 20 lines (configurable)

🔧 **God Classes**: Classes exceeding 300 lines (configurable)

🔧 **Undocumented Domain Constants**: Constants without explanatory comments

🔧 **Mass Assignment**: Unfiltered parameter passing

🔧 **Token Exposure**: Tokens in logs or errors

## Platform Support

Supported: Linux, macOS, OpenBSD (with `pledge`/`unveil`), Cygwin (Windows), Termux (Android)

Platform detection: `OPENBSD`, `TERMUX`, `CYGWIN`, `MACOS`, `LINUX` constants automatically set.

## Testing

Run: `ruby cli_test.rb`

25 tests across 8 classes: TestLog, TestValidator, TestMaster, TestScannerV2, TestEvidenceCalculatorV2, TestConvergenceDetector, TestBatchMode, TestShellTool

## Dependencies

**Required**: Ruby ≥2.7, syntax_tree

**Optional**: diffy, sqlite3, rubocop, flog

Install: `gem install syntax_tree diffy sqlite3 rubocop flog`

## Architecture

| Class | Responsibility |
|-------|---------------|
| Master | Configuration loading and validation |
| DefectBuilder | Defect detection rule management |
| ScannerV2 | AST-based code scanning |
| EvidenceCalculatorV2 | Multi-component quality scoring |
| ConvergenceDetector | Stability analysis (3-iteration window) |
| LearningDB | SQLite metrics persistence |
| BatchMode | Automated improvement orchestration |
| GitIntegration | Pre-commit hook management |
| MetricsDashboard | HTML report generation |
| ShellTool | Secure command execution (allowlist) |
| CLI | Command-line interface |

Modules: Log (unified logging), Validator (threshold enforcement), C (configuration paths)

## Examples

### Defect Detection

```bash
$ ruby cli.rb scan --verbose

Scanning: lib/api.rb
  INJ001: System Command Injection (line 42)
    system("curl #{url}")
  SEC003: Hardcoded API Key (line 8)
    API_KEY = "sk_live_abc123"

Scanning: app/models/user.rb
  ARCH002: God Class (342 lines)
  COMP001: Long Method: process_order (28 lines)

Total: 4 defects (1 critical, 1 high, 2 medium)
```

### Batch Improvement Workflow

```bash
$ ruby cli.rb batch conservative

Iteration 1:
  Evidence: 0.87 → 0.89 (+0.02)
  Fixed: 3 defects
  Remaining: 12 defects

Iteration 2:
  Evidence: 0.89 → 0.91 (+0.02)
  Fixed: 2 defects
  Remaining: 10 defects

Iteration 3:
  Evidence: 0.91 → 0.92 (+0.01)
  Fixed: 2 defects
  Converged: ✓ (3 iterations < 2% change)

Final Evidence: 0.92
```

### Custom Domain Constants

```yaml
domain_constants:
  max_method_lines: 15        # Stricter than default
  max_class_lines: 200        # Smaller classes
  max_complexity: 8           # Lower cyclomatic limit
  max_nesting_depth: 3        # Prevent deep nesting
```

## Security

**Shell Execution Allowlist**: ShellTool enforces strict command allowlist: `rubocop`, `flog`, `syntax_tree`, `git`. No user input interpolation.

**Credential Detection**: Patterns for passwords, API keys, tokens (e.g., `/sk_live_[a-zA-Z0-9]{24,}/`)

**Injection Prevention**: AST analysis detects system calls with interpolation, eval with external input, unfiltered parameters.

## Troubleshooting

**Configuration Not Found**: Create `~/.convergence/master.yml` or use `--config` flag

**Insufficient Principles**: Add more principles to meet minimum of 20

**Dependency Missing**: `gem install syntax_tree`

**Convergence Not Reached**: Adjust `domain_constants` or use `aggressive` strategy

**Log Files**: `~/.convergence/logs/` contains `scan_YYYYMMDD.log`, `batch_YYYYMMDD.log`, `errors.log`

## Flags

**Global**: `--verbose` (detailed output), `--dry-run` (show without applying), `--json` (machine-readable), `--config PATH` (custom config)

Examples:
```bash
ruby cli.rb scan --verbose --json > results.json
ruby cli.rb batch conservative --dry-run
```

## Contributing

Fork repository, create feature branch, add tests, run `ruby cli_test.rb`, ensure evidence ≥0.95, submit PR.

**Quality Gate**: Evidence ≥0.95, test coverage ≥90%, no critical/high defects, convergence within 10 iterations

**Code Style**: Methods ≤20 lines, classes ≤300 lines, complexity ≤10, document domain constants

## Roadmap

**Planned**: AI-powered fixes (LLM remediation), web dashboard (WebSocket updates), CI/CD integration (GitHub Actions, GitLab CI), multi-language support (Python, JavaScript, Go), team collaboration (shared DB), custom analyzers (plugin system)

**Version History**: 0.6.1 (current), 0.6.0 (convergence), 0.5.0 (batch strategies), 0.4.0 (evidence V2), 0.3.0 (Git integration)

---

**Project**: master.yml v0.6.1  
**License**: Proprietary  
**Ruby**: ≥2.7  
**Platform**: Linux, macOS, OpenBSD, Cygwin, Termux
