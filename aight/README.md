# Aight - Interactive Ruby REPL with LLM Integration

An intelligent Ruby REPL with LLM-powered code assistance and Starship prompt integration. Follows master.json v502.0.0 principles: zero trust input validation, OpenBSD pledge/unveil security, modern zsh patterns, evidence-based design, and reversible architecture.

## Features

### 1. Interactive Ruby REPL with LLM Integration
- **IRB-based REPL** with syntax highlighting
- **LLM-powered code completion** and explanation
- **Multi-line input support** with readline
- **Context-aware suggestions**
- **History with intelligent search** (stored in `~/.aight_history`)
- **Inline documentation lookup**

### 2. Starship Prompt Integration
- **Custom aight module** for Starship
- **Display current LLM model** in prompt
- **Show cognitive load** (7±2 tracking) with visual indicators
- **Active assistant indicator** (🤖)
- **Token count display** for long contexts
- **Security status** indicator (pledge/unveil state on OpenBSD)

### 3. REPL Commands

#### Code Evaluation
- `<ruby code>` - Execute any Ruby code

#### LLM-Powered Commands
- `.explain` - Ask LLM to explain last result
- `.refactor [code]` - Get refactoring suggestions
- `.test [code]` - Generate tests for code
- `.doc [code]` - Generate documentation
- `.security [code]` - Security analysis (zero trust principles)
- `.performance [code]` - Performance suggestions

#### Session Management
- `.history [n]` - Show last n commands (default: 10)
- `.clear` - Clear context and reset cognitive load
- `.context` - Show current session context
- `.model <name>` - Change LLM model

#### System
- `.help` - Show available commands
- `.exit` - Exit REPL

### 4. Shell Integration
- **Starship configuration generator** (`aight --starship`)
- **Modern zsh completion** (`aight --completions`)
- **OpenBSD-native path handling**
- **Session persistence** via history file

## Installation

### Prerequisites

```bash
# Ruby 3.2+
ruby --version

# Optional: OpenBSD pledge/unveil gems (OpenBSD only)
gem install pledge unveil

# Optional: LLM API access
export OPENAI_API_KEY="your-key-here"
# or
export ANTHROPIC_API_KEY="your-key-here"
```

### Install Aight

```bash
# Navigate to aight directory
cd /path/to/pub3/aight

# Make executable
chmod +x aight.rb

# Optional: Add to PATH
ln -s $(pwd)/aight.rb /usr/local/bin/aight
```

### Install Starship Integration

```bash
# Generate Starship configuration
./aight.rb --starship

# Add to your .zshrc:
export AIGHT_MODEL="gpt-4"
eval "$(starship init zsh)"
```

### Install Zsh Completions

```bash
# Install completions
./aight.rb --completions

# Add to your .zshrc (if not already present):
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit
```

## Usage

### Basic REPL

```bash
# Start REPL
./aight.rb

# Or with options
./aight.rb --model gpt-3.5-turbo --verbose
```

### Example Session

```ruby
# Start aight
$ ./aight.rb
🚀 Aight REPL v1.0.0
📦 Model: gpt-4
🔒 Security: pledge/unveil active
💡 Type .help for commands, .exit to quit

# Execute Ruby code
aight[gpt]> [1,2,3].map(&:succ)
=> [2, 3, 4]

# Explain the result
aight[gpt]> .explain
🤔 Analyzing result...
💡 This is an Array containing three integers [2, 3, 4]. It was created by 
mapping the successor method (&:succ) over the original array [1,2,3], 
incrementing each element by 1.

# Refactor code
aight[gpt]> .refactor def foo; if x then y else z end; end
🔄 Analyzing code for refactoring opportunities...
♻️ Use ternary operator for simple conditionals: `def foo; x ? y : z; end`

# Generate tests
aight[gpt]> .test def sum(a, b); a + b; end
🧪 Generating tests...
🧪 Suggested tests:
describe '#sum' do
  it 'adds two positive numbers' do
    expect(sum(2, 3)).to eq(5)
  end
  
  it 'handles negative numbers' do
    expect(sum(-1, 1)).to eq(0)
  end
end

# Check security
aight[gpt]> .security eval(user_input)
🔒 Analyzing security...
🛡️ Critical vulnerability: `eval(user_input)` allows arbitrary code execution.
Use safer alternatives like JSON.parse, YAML.safe_load, or allowlist-based
input validation. Follow zero trust principles.
```

### Cognitive Load Tracking

The REPL tracks cognitive load (7±2 items) and displays warnings:

- ` ` (empty) - Load: 0-2 (comfortable)
- `⚠️` - Load: 3-5 (moderate)
- `🔥` - Load: 6-7 (high)
- `💥` - Load: 8+ (overload, consider `.clear`)

### Security Features

On OpenBSD, aight uses pledge/unveil for security:

```ruby
# Pledges (system call restrictions)
- stdio: Standard I/O
- rpath/wpath/cpath: File operations
- proc/exec: Process execution
- inet/dns: Network (for LLM API calls)
- tty: Terminal control

# Unveil (filesystem visibility)
- /tmp: Temporary files (rwc)
- /usr/local/bin: Executables (rx)
- ~/: Home directory (rwc)
- <aight_dir>: Read-only (r)
```

## Configuration

### Environment Variables

```bash
# Set default LLM model
export AIGHT_MODEL="gpt-4"

# OpenAI API key
export OPENAI_API_KEY="sk-..."

# Anthropic API key
export ANTHROPIC_API_KEY="sk-ant-..."

# Session indicator for Starship
export AIGHT_SESSION="1"  # Auto-set by REPL
```

### Starship Prompt Customization

Edit `~/.config/starship/starship.toml`:

```toml
# Customize aight module appearance
[custom.aight]
format = "[$output]($style) "
style = "bold blue"

[custom.aight_model]
format = "[$output]($style) "
style = "cyan"

[custom.aight_load]
format = "[$output]($style) "
style = "yellow bold"
```

## Architecture

### File Structure

```
aight/
├── aight.rb                  # Main CLI entry point
├── lib/
│   ├── repl.rb              # REPL implementation
│   └── starship_module.rb   # Starship integration
├── config/
│   └── starship.toml        # Starship config template
├── completions/
│   └── _aight               # Zsh completions
└── README.md                # This file
```

### Design Principles (master.json v502.0.0)

1. **Zero Trust Input Validation**
   - All user input sanitized
   - LLM responses treated as untrusted
   - No arbitrary code execution from LLM suggestions

2. **OpenBSD Pledge/Unveil**
   - Minimal system call access
   - Restricted filesystem visibility
   - Security-first design

3. **Modern Zsh Patterns**
   - Native completion system
   - Context-aware suggestions
   - Performance-optimized caching

4. **Evidence-Based Design**
   - Cognitive load tracking (7±2 items)
   - Session metrics and monitoring
   - Actionable feedback

5. **Reversible Architecture**
   - All operations can be undone
   - Clear context management
   - History persistence

## Troubleshooting

### LLM API Not Working

```bash
# Check API keys
echo $OPENAI_API_KEY
echo $ANTHROPIC_API_KEY

# Test connectivity
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

### Completions Not Loading

```bash
# Verify completion file exists
ls -la ~/.zsh/completions/_aight

# Rebuild completion cache
rm -f ~/.zcompdump
autoload -Uz compinit && compinit

# Check fpath
echo $fpath | grep completions
```

### Starship Module Not Showing

```bash
# Check environment variables
env | grep AIGHT

# Verify Starship config
cat ~/.config/starship/starship.toml | grep aight

# Reload shell
source ~/.zshrc
```

## Development

### Running Tests

```bash
# Run Ruby linter
rubocop aight.rb lib/*.rb

# Run code quality checks
reek lib/*.rb
```

### Adding New REPL Commands

1. Add command to `process_command` method in `lib/repl.rb`
2. Implement command handler method
3. Update help text in `show_help`
4. Add to completions in `completions/_aight`

### Extending LLM Integration

The `query_llm` method in `lib/repl.rb` supports:
- OpenAI API (GPT-3.5, GPT-4)
- Anthropic API (Claude 3)
- Easy to extend for other providers

## License

Proprietary - See LICENSE file

## Contributing

See CONTRIBUTING.md in the root repository for guidelines.

## Security

Report security issues to security@example.com (see SECURITY.md)

## References

- [master.json v502.0.0](../master.json) - Project philosophy and principles
- [Starship Prompt](https://starship.rs/) - Cross-shell prompt
- [OpenBSD pledge/unveil](https://man.openbsd.org/pledge.2) - Security mechanisms
- [Ruby IRB](https://github.com/ruby/irb) - Interactive Ruby
