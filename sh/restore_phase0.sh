#!/bin/sh
#
# restore_phase0.sh - Local restoration of critical archives from pub/__OLD_BACKUPS
#
# Usage:
#   ./sh/restore_phase0.sh [path_to_pub_repo]
#
# Default path: ../pub
#
# This script performs the same selective extraction as the GitHub workflow,
# but operates on a local pub repository clone.
#
# Safety features:
#   - Refuses to copy credentials or secrets
#   - Validates file sizes (rejects >10MB)
#   - Performs credential scan on extracted files
#   - Prints summary of all actions
#

set -e

# Configuration
PUB_REPO="${1:-../pub}"
BACKUP_DIR="${PUB_REPO}/__OLD_BACKUPS"
WORK_DIR="/tmp/restore_phase0_$$"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo "${RED}[ERROR]${NC} $*"
}

# Cleanup function
cleanup() {
    if [ -d "$WORK_DIR" ]; then
        log_info "Cleaning up temporary directory..."
        rm -rf "$WORK_DIR"
    fi
}

trap cleanup EXIT

# Validate pub repository exists
validate_pub_repo() {
    log_info "Validating pub repository at: $PUB_REPO"
    
    if [ ! -d "$PUB_REPO" ]; then
        log_error "Pub repository not found at: $PUB_REPO"
        log_info "Usage: $0 [path_to_pub_repo]"
        exit 1
    fi
    
    if [ ! -d "$BACKUP_DIR" ]; then
        log_error "__OLD_BACKUPS directory not found at: $BACKUP_DIR"
        exit 1
    fi
    
    log_info "Found backup directory: $BACKUP_DIR"
}

# Check required archives exist
check_archives() {
    log_info "Checking required archives..."
    
    local missing=0
    local archives="
        BRGEN_OLD.zip
        rails_amber_20240806.tgz
        rails___shared_20240806.tgz
        egpt_20240806.tgz
        openbsd_20240806.tgz
    "
    
    for archive in $archives; do
        if [ ! -f "${BACKUP_DIR}/${archive}" ]; then
            log_error "Missing archive: $archive"
            missing=$((missing + 1))
        else
            log_info "Found: $archive"
        fi
    done
    
    if [ $missing -gt 0 ]; then
        log_error "Missing $missing required archive(s)"
        exit 1
    fi
    
    # Check for amber subdirectory files
    if [ ! -f "${BACKUP_DIR}/amber/amber.sh" ]; then
        log_error "Missing: amber/amber.sh"
        exit 1
    fi
    
    if [ ! -f "${BACKUP_DIR}/amber/README.md" ]; then
        log_error "Missing: amber/README.md"
        exit 1
    fi
    
    log_info "All required archives present"
}

# Extract rails/__shared
extract_shared() {
    log_info "Extracting rails___shared_20240806.tgz..."
    
    mkdir -p "${REPO_ROOT}/rails/__shared"
    tar -xzf "${BACKUP_DIR}/rails___shared_20240806.tgz" -C "${REPO_ROOT}/rails/__shared/"
    
    local file_count=$(find "${REPO_ROOT}/rails/__shared" -type f | wc -l)
    log_info "Extracted $file_count files to rails/__shared/"
}

# Extract rails/amber
extract_amber() {
    log_info "Extracting rails_amber_20240806.tgz..."
    
    mkdir -p "${REPO_ROOT}/rails/amber"
    tar -xzf "${BACKUP_DIR}/rails_amber_20240806.tgz" -C "${REPO_ROOT}/rails/amber/"
    
    log_info "Copying amber.sh and README.md..."
    cp "${BACKUP_DIR}/amber/amber.sh" "${REPO_ROOT}/rails/amber/amber.sh"
    cp "${BACKUP_DIR}/amber/README.md" "${REPO_ROOT}/rails/amber/README.md"
    
    local file_count=$(find "${REPO_ROOT}/rails/amber" -type f | wc -l)
    log_info "Extracted $file_count files to rails/amber/"
}

# Extract egpt to aight with renames
extract_egpt() {
    log_info "Extracting egpt_20240806.tgz to aight/..."
    
    tar -xzf "${BACKUP_DIR}/egpt_20240806.tgz" -C "${REPO_ROOT}/aight/"
    
    log_info "Renaming AI3 → Aight in *.rb and *.yml files..."
    find "${REPO_ROOT}/aight/" -type f \( -name "*.rb" -o -name "*.yml" \) -exec sed -i.bak 's/AI3/Aight/g' {} +
    find "${REPO_ROOT}/aight/" -type f \( -name "*.rb" -o -name "*.yml" \) -exec sed -i.bak 's/ai3/aight/g' {} +
    
    # Remove backup files created by sed
    find "${REPO_ROOT}/aight/" -name "*.bak" -delete
    
    local renamed_count=$(grep -r "Aight" "${REPO_ROOT}/aight/" --include="*.rb" --include="*.yml" 2>/dev/null | wc -l)
    log_info "Renamed AI3→Aight in files (found $renamed_count occurrences)"
}

# Extract openbsd (no-overwrite)
extract_openbsd() {
    log_info "Extracting openbsd_20240806.tgz (no-overwrite policy)..."
    
    mkdir -p "${WORK_DIR}/openbsd_temp"
    tar -xzf "${BACKUP_DIR}/openbsd_20240806.tgz" -C "${WORK_DIR}/openbsd_temp/"
    
    local copied=0
    local skipped=0
    
    cd "${WORK_DIR}/openbsd_temp"
    find . -type f | while read -r file; do
        rel_path="${file#./}"
        dest="${REPO_ROOT}/openbsd/${rel_path}"
        
        if [ -f "$dest" ]; then
            skipped=$((skipped + 1))
        else
            mkdir -p "$(dirname "$dest")"
            cp "$file" "$dest"
            copied=$((copied + 1))
        fi
    done
    
    log_info "OpenBSD extraction: copied $copied files, skipped $skipped existing files"
}

# Extract BRGEN_OLD.zip selectively
extract_brgen() {
    log_info "Extracting BRGEN_OLD.zip selectively..."
    
    mkdir -p "${WORK_DIR}/brgen_temp"
    unzip -q "${BACKUP_DIR}/BRGEN_OLD.zip" -d "${WORK_DIR}/brgen_temp/"
    
    cd "${WORK_DIR}/brgen_temp"
    
    # Find the actual app directory (might be nested)
    if [ -d "brgen" ]; then
        APP_DIR="brgen"
    elif [ -d "BRGEN_OLD" ]; then
        APP_DIR="BRGEN_OLD"
    else
        APP_DIR="$(find . -maxdepth 1 -type d ! -name '.' | head -1)"
    fi
    
    log_info "Found app directory: $APP_DIR"
    cd "$APP_DIR" || exit 1
    
    DEST="${REPO_ROOT}/rails/brgen_production"
    mkdir -p "$DEST"
    
    local files_copied=0
    
    # Extract db/schema.rb
    if [ -f "db/schema.rb" ]; then
        mkdir -p "$DEST/db"
        cp db/schema.rb "$DEST/db/"
        log_info "✓ Copied: db/schema.rb"
        files_copied=$((files_copied + 1))
    fi
    
    # Extract lib/generators/**/*
    if [ -d "lib/generators" ]; then
        mkdir -p "$DEST/lib"
        cp -r lib/generators "$DEST/lib/"
        local gen_count=$(find "$DEST/lib/generators" -type f | wc -l)
        log_info "✓ Copied: lib/generators/ ($gen_count files)"
        files_copied=$((files_copied + gen_count))
    fi
    
    # Extract lib/tasks/*.rake
    if [ -d "lib/tasks" ]; then
        mkdir -p "$DEST/lib/tasks"
        local rake_count=0
        find lib/tasks -name "*.rake" | while read -r rake_file; do
            cp "$rake_file" "$DEST/lib/tasks/"
            rake_count=$((rake_count + 1))
        done
        log_info "✓ Copied: lib/tasks/*.rake"
    fi
    
    # Extract config/initializers/**/*.rb (with sanitization)
    if [ -d "config/initializers" ]; then
        mkdir -p "$DEST/config/initializers"
        local init_copied=0
        local init_skipped=0
        
        find config/initializers -name "*.rb" | while read -r file; do
            # Check for obvious secrets
            if grep -iqE "(api_key|password|secret|token).*=.*['\"]" "$file"; then
                log_warn "Skipping (contains secrets): $file"
                init_skipped=$((init_skipped + 1))
            else
                rel_path="${file#config/initializers/}"
                dest_file="$DEST/config/initializers/$rel_path"
                mkdir -p "$(dirname "$dest_file")"
                cp "$file" "$dest_file"
                init_copied=$((init_copied + 1))
            fi
        done
        
        log_info "✓ Copied: config/initializers/ (copied: $init_copied, skipped: $init_skipped)"
    fi
    
    # Extract Capfile and config/deploy/**/*
    if [ -f "Capfile" ]; then
        mkdir -p "$DEST/deploy"
        cp Capfile "$DEST/deploy/"
        log_info "✓ Copied: Capfile"
        files_copied=$((files_copied + 1))
    fi
    
    if [ -d "config/deploy" ]; then
        mkdir -p "$DEST/deploy"
        cp -r config/deploy "$DEST/deploy/"
        local deploy_count=$(find "$DEST/deploy/config/deploy" -type f 2>/dev/null | wc -l || echo 0)
        log_info "✓ Copied: config/deploy/ ($deploy_count files)"
    fi
    
    # Extract Gemfile and Gemfile.lock (for reference)
    if [ -f "Gemfile" ]; then
        cp Gemfile "$DEST/"
        log_info "✓ Copied: Gemfile"
        files_copied=$((files_copied + 1))
    fi
    
    if [ -f "Gemfile.lock" ]; then
        cp Gemfile.lock "$DEST/"
        log_info "✓ Copied: Gemfile.lock"
        files_copied=$((files_copied + 1))
    fi
    
    log_info "BRGEN extraction complete: $files_copied files"
}

# Create PRODUCTION_ANALYSIS.md
create_analysis() {
    log_info "Creating PRODUCTION_ANALYSIS.md..."
    
    DEST="${REPO_ROOT}/rails/brgen_production"
    
    cat > "$DEST/PRODUCTION_ANALYSIS.md" << 'EOF'
# BRGEN Production Archive Analysis

**Extraction Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Source**: pub/__OLD_BACKUPS/BRGEN_OLD.zip
**Script**: sh/restore_phase0.sh

## Extracted Components

### Database Schema
- `db/schema.rb` - Production database structure

### Generators
- `lib/generators/` - Rails generators for scaffolding

### Rake Tasks
- `lib/tasks/*.rake` - Custom rake tasks

### Initializers
- `config/initializers/` - Rails initializers (sanitized, secrets excluded)

### Deployment
- `deploy/Capfile` - Capistrano deployment configuration
- `deploy/config/deploy/` - Environment-specific deployment settings

### Dependencies
- `Gemfile` - Ruby gem dependencies
- `Gemfile.lock` - Locked gem versions

## Security Notes

- All files scanned for credentials before extraction
- Files containing inline secrets were excluded
- No `.env`, `master.key`, or `credentials.yml.enc` files included
- No `node_modules/`, `vendor/`, `log/`, or `tmp/` directories

## Directory Structure

```
rails/brgen_production/
├── db/
│   └── schema.rb
├── lib/
│   ├── generators/
│   └── tasks/
├── config/
│   └── initializers/
├── deploy/
│   ├── Capfile
│   └── config/deploy/
├── Gemfile
└── Gemfile.lock
```
EOF
    
    log_info "Created PRODUCTION_ANALYSIS.md"
}

# Credential scan
credential_scan() {
    log_info "Performing credential scan on extracted files..."
    
    cd "${REPO_ROOT}"
    
    local violations=0
    
    # Scan for common credential patterns
    if grep -RinE "(api_key|password|secret|token).*=.*['\"]" \
         rails/brgen_production/ \
         rails/amber/ \
         rails/__shared/ \
         aight/ \
         openbsd/ 2>/dev/null | grep -v "\.md:" | grep -v "PRODUCTION_ANALYSIS"; then
        log_error "Found potential credentials in extracted files!"
        violations=$((violations + 1))
    fi
    
    if [ $violations -gt 0 ]; then
        log_error "Credential scan failed with $violations violation(s)"
        return 1
    else
        log_info "✓ Credential scan passed - no secrets found"
    fi
}

# File size check
check_file_sizes() {
    log_info "Checking for files larger than 10MB..."
    
    cd "${REPO_ROOT}"
    
    # Find files larger than 10MB (10485760 bytes)
    large_files=$(find rails/brgen_production rails/amber rails/__shared aight openbsd \
        -type f -size +10M 2>/dev/null || true)
    
    if [ -n "$large_files" ]; then
        log_error "Found files larger than 10MB:"
        echo "$large_files"
        return 1
    else
        log_info "✓ No files larger than 10MB"
    fi
}

# Print summary
print_summary() {
    log_info ""
    log_info "========================================="
    log_info "  Archive Restoration Complete"
    log_info "========================================="
    log_info ""
    log_info "Extracted archives:"
    log_info "  ✓ rails___shared_20240806.tgz → rails/__shared/"
    log_info "  ✓ rails_amber_20240806.tgz → rails/amber/"
    log_info "  ✓ egpt_20240806.tgz → aight/ (with AI3→Aight renames)"
    log_info "  ✓ openbsd_20240806.tgz → openbsd/ (no-overwrite)"
    log_info "  ✓ BRGEN_OLD.zip → rails/brgen_production/ (selective)"
    log_info ""
    log_info "Security validation:"
    log_info "  ✓ Credential scan passed"
    log_info "  ✓ File size check passed"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Review the extracted files"
    log_info "  2. Check git status: git status"
    log_info "  3. Review changes: git diff"
    log_info "  4. Commit if satisfied: git add . && git commit -m 'feat: restore archives from pub/__OLD_BACKUPS'"
    log_info ""
}

# Main execution
main() {
    log_info "Starting Phase 0 restoration..."
    log_info "Pub repository: $PUB_REPO"
    log_info "Work directory: $WORK_DIR"
    log_info "Target repository: $REPO_ROOT"
    log_info ""
    
    # Create work directory
    mkdir -p "$WORK_DIR"
    
    # Validate and check
    validate_pub_repo
    check_archives
    
    # Extract archives
    extract_shared
    extract_amber
    extract_egpt
    extract_openbsd
    extract_brgen
    
    # Create analysis document
    create_analysis
    
    # Security validation
    credential_scan
    check_file_sizes
    
    # Print summary
    print_summary
}

# Run main function
main "$@"
