# Code Style Guide

This guide defines the coding standards for the pub3 repository across Ruby, Shell (Zsh), and JavaScript.

## Philosophy

From `master.json`:
- **clarity > cleverness** - Write obvious code over clever code
- **consolidation > fragmentation** - Group related code, avoid file sprawl
- **evidence > opinion** - Base decisions on metrics and facts
- **execution > explanation** - Working code over extensive documentation

## Ruby Style (Rails 8.0.3)

### File Organization

Arrange code sections by importance:
1. **Constants** - Immutable configuration values
2. **Concerns** - Shared modules and mixins
3. **Validations** - Data integrity rules
4. **Associations** - Model relationships
5. **Scopes** - Query methods
6. **Callbacks** - Lifecycle hooks
7. **Public methods** - External interface
8. **Private methods** - Implementation details

### Naming Conventions

- **Classes/Modules**: `PascalCase`
- **Methods/Variables**: `snake_case`
- **Constants**: `SCREAMING_SNAKE`
- **Predicate methods**: End with `?`
- **Dangerous methods**: End with `!`

**Avoid generic names**: `thing`, `stuff`, `data`, `info`, `item`, `object`, `manager`, `helper`, `util`, `misc`

**Verb transformations** (prefer specific over generic):
- `get` → `fetch`
- `check` → `validate`
- `do` → `execute`
- `handle` → `process`
- `make` → `create`
- `build` → `construct`

### Method Structure

```ruby
def method_name(param1, param2)
  # 1. Guard clauses (return early)
  return nil unless param1.present?
  
  # 2. Setup (variable initialization)
  result = []
  
  # 3. Main logic
  result << process_data(param1, param2)
  
  # 4. Cleanup (if needed)
  
  # 5. Return
  result
end
```

### Complexity Limits

From `master.json core.limits`:
- **Method length**: Max 20 lines
- **Class length**: Max 300 lines
- **Parameters**: Max 3 per method
- **Chain depth**: Max 3 levels
- **Cyclomatic complexity**: Max 10
- **Duplication**: Max 3%

### Rails 8.0 Patterns

**Use Rails 8 built-ins**:
- `solid_queue` instead of Sidekiq/Resque
- `solid_cache` instead of Redis cache store
- `solid_cable` instead of Redis ActionCable
- Authentication generator instead of Devise

**Hotwire by default**:
- Turbo for page updates
- Stimulus for JavaScript behavior
- StimulusReflex for real-time interactions

## Shell Style (Zsh)

### Shebang & Safety

```zsh
#!/usr/bin/env zsh
set -euo pipefail
```

### Modern Zsh First

**Forbidden** (use Zsh equivalents):
- Backticks `` `cmd` `` → use `$(cmd)`
- `which` → use `command -v`
- `test` → use `[[ ]]`
- `seq` → use `{1..10}`
- `echo` / `printf` → use `print`

**Prefer Zsh built-ins**:
- Glob qualifiers: `**/*(.N)` (all files, nullglob)
- Parameter expansion: `${var#prefix}`, `${var%suffix}`
- Pattern matching: `[[ $x == *pattern* ]]`
- Input redirection: `$(<file)` instead of `cat file`
- Heredocs: `cat <<EOF` or `cat <<'EOF'` (no expansion)

### Patterns

```zsh
# Glob qualifiers
**/*(.N)        # All files, nullglob if none
**/*/           # All directories
**/*.rb         # All Ruby files recursively

# Parameter expansion
${var#prefix}   # Remove shortest prefix
${var##*/}      # Remove longest prefix (basename)
${var%suffix}   # Remove shortest suffix
${var/old/new}  # Replace first occurrence
${var//old/new} # Replace all occurrences

# Conditionals
[[ -d $dir ]]              # Directory exists
[[ -z $var ]]              # Variable empty
[[ $x == *pattern* ]]      # Pattern match

# Input/Output
content=$(<file)           # Read file
<(command)                 # Process substitution
=(command)                 # Create temp file with output
```

### Function Structure

```zsh
function_name() {
  # 1. Local variables
  local param="$1"
  
  # 2. Guards
  [[ -z "$param" ]] && return 1
  
  # 3. Main logic
  print "Processing: $param"
  
  # 4. Return
  return 0
}
```

## JavaScript Style (Stimulus 3.x)

### Stimulus Controller Lifecycle

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["element"]
  static values = { url: String }
  
  // 1. Initialize - setup constants, NO DOM access
  initialize() {
    this.someConstant = "value"
  }
  
  // 2. Connect - setup listeners, DOM manipulation, API calls
  connect() {
    this.element.addEventListener("custom-event", this.handleEvent)
  }
  
  // 3. Actions - event handlers
  handleEvent(event) {
    // Implementation
  }
  
  // 4. Disconnect - ALWAYS cleanup timers, listeners
  disconnect() {
    this.element.removeEventListener("custom-event", this.handleEvent)
  }
}
```

**Critical**: Always cleanup in `disconnect()` to prevent memory leaks.

### StimulusReflex Pattern

```javascript
// Client-side stimulation
this.stimulate('ReflexClass#method', element, options, ...args)

// Server receives in app/reflexes/reflex_class.rb
class ReflexClass < ApplicationReflex
  def method
    # Access: element, params, session, connection, current_user
    
    # Update DOM via morph
    morph('#selector', render(partial: 'path/to/partial'))
    
    # Or broadcast to others
    cable_ready.broadcast(...)
  end
end
```

**Round-trip**: 20-30ms over WebSocket via ActionCable

### Naming

- **Controllers**: `kebab-case_controller.js`
- **Actions**: `camelCase`
- **Targets**: `camelCase`
- **Values**: `camelCase`

## File Size & Complexity

From `master.json`:
- **Max file size**: 100KB (102,400 bytes)
- **Coverage target**: 90%
- **Duplication limit**: 3%

## Code Generation

### Heredoc Templates

All installer scripts use heredoc templates for consistency:

```zsh
cat > path/to/file.rb <<'EOF'
# Ruby code here
# No variable expansion (use 'EOF')
EOF

cat > path/to/file.erb <<EOF
<!-- ERB with variable expansion -->
<p><%= @variable %></p>
EOF
```

**Pattern**: Use `'EOF'` to prevent variable expansion when generating code that contains `$variables`.

## Protected Files

Never modify without explicit permission:
- `*.css`, `*.scss`, `*.sass`
- `app/assets/stylesheets/*`
- `.env.production`
- `config/master.key`
- `config/credentials/*.key`

## Quality Weights

Priority order (from `master.json core.weights`):
1. **Security**: 10 (highest)
2. **Duplication**: 10
3. **Complexity**: 9
4. **Coverage**: 8
5. **Style**: 7
6. **Cost**: 6
7. **Naming**: 5

## References

- Master configuration: `master.json`
- Shell patterns: `core.shell.patterns`
- Ruby standards: `standards.arrangement`
- Stimulus lifecycle: `dependencies.stimulus_reflex.lifecycle`
