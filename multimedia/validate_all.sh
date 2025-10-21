#!/usr/bin/env bash
# multimedia/validate_all.sh
# Validates all multimedia subsystems against master.json standards
# Target: zsh (per master.json) but compatible with bash 5+

set -euo pipefail
shopt -s globstar nullglob 2>/dev/null || true  # Enable ** glob pattern

# Configuration
MASTER_JSON="../master.json"
MAX_FILE_SIZE=20480  # 20KB in bytes
ERRORS=0

# Colors for output (compatible with master.json emoji style)
print_header() { echo -e "\033[36m🔍 $1\033[0m"; }
print_ok() { echo -e "\033[32m✓ $1\033[0m"; }
print_warn() { echo -e "\033[33m⚠️  $1\033[0m"; }
print_error() { echo -e "\033[31m✗ $1\033[0m"; ERRORS=$((ERRORS + 1)); }

print_header "Validating Multimedia Subsystems"

# Check if we're in the multimedia directory
if [[ ! -d "dilla" ]] || [[ ! -d "postpro" ]] || [[ ! -d "repligen" ]] || [[ ! -d "tts" ]]; then
  print_error "Must run from multimedia/ directory"
  exit 1
fi

# Validate each subsystem
for subsys in dilla postpro repligen tts; do
  [[ -d "$subsys" ]] || continue
  
  print_header "Checking $subsys/"
  
  # Check README exists
  if [[ ! -f "$subsys/README.md" ]]; then
    print_error "$subsys: missing README.md"
  else
    print_ok "$subsys: README.md present"
  fi
  
  # Validate Ruby files  
  ruby_count=0
  seen_files=""
  for rb in "$subsys"/**/*.rb "$subsys"/*.rb; do
    [[ -f "$rb" ]] || continue
    # Skip if already seen
    if [[ " $seen_files " == *" $rb "* ]]; then
      continue
    fi
    seen_files="$seen_files $rb"
    ruby_count=$((ruby_count + 1))
    
    # Check file size (20KB limit from master.json)
    size=0
    if [[ "$OSTYPE" == "darwin"* ]]; then
      size=$(stat -f%z "$rb" 2>/dev/null || echo 0)
    else
      size=$(stat -c%s "$rb" 2>/dev/null || echo 0)
    fi
    
    if [[ $size -gt $MAX_FILE_SIZE ]]; then
      # Documented exceptions
      if [[ "$rb" == "postpro/postpro.rb" ]]; then
        print_warn "$rb: exceeds 20KB limit (${size} bytes) - documented exception"
      elif [[ "$rb" == repligen/archive/* ]]; then
        print_warn "$rb: exceeds 20KB limit (${size} bytes) - archived version"
      else
        print_error "$rb: exceeds 20KB limit (${size} bytes)"
      fi
    fi
    
    # Check for backup files
    if [[ "$rb" == *_backup.rb ]] || [[ "$rb" == *_old.rb ]] || [[ "$rb" == *.bak.rb ]]; then
      print_error "$rb: backup file violates policy"
    fi
    
    # Basic Ruby syntax check
    if command -v ruby &>/dev/null; then
      if ruby -c "$rb" &>/dev/null 2>&1; then
        : # Valid syntax, no output
      else
        print_error "$rb: syntax error"
      fi
    fi
  done
  
  [[ $ruby_count -gt 0 ]] && print_ok "$subsys: $ruby_count Ruby files checked"
  
  # Check for log files in repo
  for log in "$subsys"/**/*.log "$subsys"/*.log; do
    [[ -f "$log" ]] && print_warn "$log: log file should be gitignored"
  done
  
  # Check for binary archives
  for archive in "$subsys"/**/*.tar.gz "$subsys"/**/*.zip "$subsys"/**/*.tgz "$subsys"/*.tar.gz "$subsys"/*.zip "$subsys"/*.tgz; do
    [[ -f "$archive" ]] && print_warn "$archive: binary archive should be gitignored or in releases"
  done
  
  # Check for .gitignore if output directories exist
  if [[ -d "$subsys/output" ]] && [[ ! -f "$subsys/.gitignore" ]]; then
    print_warn "$subsys: has output/ but no .gitignore"
  fi
done

# Check for top-level multimedia README
print_header "Checking Top-Level Documentation"
if [[ -f "README.md" ]]; then
  print_ok "multimedia/README.md present"
  
  # Check that it mentions all subsystems
  for subsys in dilla postpro repligen tts; do
    if grep -q "$subsys" README.md; then
      print_ok "README.md documents $subsys"
    else
      print_warn "README.md missing $subsys documentation"
    fi
  done
else
  print_error "multimedia/README.md missing"
fi

# Check validation script itself
print_header "Self-Check"
if [[ -x "validate_all.sh" ]]; then
  print_ok "validate_all.sh is executable"
else
  print_warn "validate_all.sh not executable (run: chmod +x validate_all.sh)"
fi

# Check for shell compatibility
if [[ -f "validate_all.sh" ]]; then
  if head -1 validate_all.sh | grep -q "bash"; then
    print_warn "validate_all.sh: uses bash (master.json prefers zsh on target system)"
  fi
fi

# Summary
print_header "Validation Summary"
if [[ $ERRORS -eq 0 ]]; then
  print_ok "All multimedia subsystems valid ✨"
  exit 0
else
  print_error "Found $ERRORS errors"
  echo -e "\033[33m💡 Run from multimedia/ directory with: ./validate_all.sh\033[0m"
  exit 1
fi
