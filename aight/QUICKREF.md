# Aight REPL - Quick Reference
## Installation

```bash

cd /home/runner/work/pub3/pub3/aight

chmod +x aight.rb
```
## Usage
```bash

# Start REPL

./aight.rb
# With options
./aight.rb --model claude-3-opus --verbose

# Install completions
./aight.rb --completions

# Configure Starship
./aight.rb --starship

```
## REPL Commands
### Code Evaluation

- `<ruby code>` - Execute any Ruby code

### LLM Commands
- `.explain` - Explain last result

- `.refactor [code]` - Get refactoring suggestions
- `.test [code]` - Generate tests
- `.doc [code]` - Generate documentation
- `.security [code]` - Security analysis
- `.performance [code]` - Performance tips
### Session Commands
- `.history [n]` - Show last n commands

- `.clear` - Clear context
- `.context` - Show session info
- `.model <name>` - Change LLM model
- `.help` - Show help
- `.exit` - Exit REPL
## Cognitive Load Indicators
- ` ` (empty) - Load 0-2 (comfortable)

- `⚠️` - Load 3-5 (moderate)

- `🔥` - Load 6-7 (high, consider `.clear`)
- `💥` - Load 8+ (overload, use `.clear`)
## Environment Variables
```bash

export AIGHT_MODEL="gpt-4"              # Default model

export OPENAI_API_KEY="sk-..."          # OpenAI API
export ANTHROPIC_API_KEY="sk-ant-..."   # Anthropic API
```
## Starship Prompt
The prompt shows:

- 🤖 - REPL active

- Model name (e.g., gpt-4, claude-3)
- Cognitive load indicator
- 🔒/🔓 - Security status
- 📊 - Token count (if large)
## Examples
### Simple Evaluation

```ruby

aight[gpt]> [1,2,3].sum
=> 6
```
### Code Analysis
```ruby

aight[gpt]> def unsafe(x); eval(x); end
=> :unsafe
aight[gpt]> .security def unsafe(x); eval(x); end
🔒 Analyzing security...

🛡️ Critical: eval() allows arbitrary code execution
```
### Refactoring
```ruby

aight[gpt]> .refactor if x then y else z end
🔄 Analyzing code...
♻️ Use ternary: x ? y : z
```
## Files
```

aight/

├── aight.rb              # Main CLI
├── lib/
│   ├── repl.rb          # REPL engine
│   └── starship_module.rb # Starship integration
├── config/
│   └── starship.toml    # Starship template
├── completions/
│   └── _aight           # Zsh completions
├── README.md            # Full documentation
├── EXAMPLES.md          # 10 usage examples
├── QUICKREF.md          # This file
└── test_aight.rb        # Test suite
```
## Testing
```bash

# Run tests

./test_aight.rb
# Check syntax
ruby -c aight.rb lib/*.rb

# Lint code
rubocop aight.rb lib/*.rb

```
## Troubleshooting
### REPL won't start

```bash

chmod +x aight.rb
ruby -c aight.rb
```
### LLM not working
```bash

echo $OPENAI_API_KEY | head -c 10
# Should show: sk-...
```
### Completions not loading
```bash

# Add to .zshrc:
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit
```
### Starship not showing
```bash

# Add to .zshrc:
export AIGHT_MODEL="gpt-4"
eval "$(starship init zsh)"
```
## Master.json v502.0.0 Compliance
✅ Zero trust input validation

✅ OpenBSD pledge/unveil security

✅ Modern zsh patterns
✅ Evidence-based design (cognitive load)
✅ Reversible architecture (.clear, .history)
## Links
- [README.md](README.md) - Complete documentation

- [EXAMPLES.md](EXAMPLES.md) - Detailed examples

- [Starship](https://starship.rs/) - Cross-shell prompt
- [OpenBSD pledge](https://man.openbsd.org/pledge.2) - Security
