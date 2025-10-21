#!/usr/bin/env bash
set -euo pipefail

# Validate all Rails installers against master.json
# Checks for:
# - @common.sh sourcing
# - Port consistency with master.json
# - README existence
# - Basic script structure
#
# Note: This validation script uses bash for portability,
# but the installers themselves are zsh scripts (as intended)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MASTER_JSON="${SCRIPT_DIR}/../master.json"
ERRORS=0
WARNINGS=0

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

log_error() {
  echo -e "${RED}✗${NC} $*"
  ((ERRORS++))
}

log_warning() {
  echo -e "${YELLOW}⚠${NC}  $*"
  ((WARNINGS++))
}

log_success() {
  echo -e "${GREEN}✓${NC} $*"
}

log_info() {
  echo -e "ℹ $*"
}

echo -e "\n╔════════════════════════════════════════════════════════╗"
echo -e "║  Rails Installer Validation                           ║"
echo -e "╚════════════════════════════════════════════════════════╝\n"

# Check master.json exists
if [[ ! -f "$MASTER_JSON" ]]; then
  log_error "master.json not found at $MASTER_JSON"
  exit 1
fi

log_success "master.json found"

# Validate JSON syntax
if ! jq empty "$MASTER_JSON" 2>/dev/null; then
  log_error "master.json has invalid JSON syntax"
  exit 1
fi

log_success "master.json has valid JSON syntax"

# Get ports from master.json
declare -A PORTS
while IFS=: read -r app port; do
  PORTS[$app]=$port
done < <(jq -r '.deployment.ports | to_entries[] | "\(.key):\(.value)"' "$MASTER_JSON")

echo -e "\n━━━ Canonical Ports from master.json ━━━"
for app in "${!PORTS[@]}"; do
  echo -e "  ${app}: ${PORTS[$app]}"
done

echo -e "\n━━━ Validating Installers ━━━\n"

# Track which installers we found
FOUND_INSTALLERS=()

# Check each .sh file in rails directory
for installer in "${SCRIPT_DIR}"/*.sh; do
  [[ ! -f "$installer" ]] && continue
  [[ "$(basename "$installer")" == "__install_all.sh" ]] && continue
  [[ "$(basename "$installer")" == "validate_installers.sh" ]] && continue
  
  app_name="$(basename "$installer" .sh)"
  FOUND_INSTALLERS+=("$app_name")
  
  echo -e "Checking ${app_name}.sh..."
  
  # Check 1: Shebang
  if ! head -1 "$installer" | grep -q '#!/usr/bin/env zsh'; then
    log_warning "$app_name: non-standard shebang (expected #!/usr/bin/env zsh)"
  fi
  
  # Check 2: set -euo pipefail
  if ! head -10 "$installer" | grep -q 'set -euo pipefail'; then
    log_warning "$app_name: missing 'set -euo pipefail'"
  fi
  
  # Check 3: Sources @common.sh (or old __shared.sh)
  if ! grep -q 'source.*@common.sh' "$installer" && \
     ! grep -q '\. .*@common.sh' "$installer" && \
     ! grep -q 'source.*__shared.sh' "$installer" && \
     ! grep -q '\. .*__shared.sh' "$installer"; then
    log_error "$app_name: does not source @common.sh or __shared.sh"
  else
    log_success "$app_name: sources shared utilities"
  fi
  
  # Check 4: Has corresponding README (optional but recommended)
  readme="${SCRIPT_DIR}/${app_name}_README.md"
  if [[ ! -f "$readme" ]]; then
    log_warning "$app_name: missing ${app_name}_README.md"
  else
    log_success "$app_name: has README"
  fi
  
  # Check 5: Port matches master.json (if app is in ports registry)
  if [[ -n "${PORTS[$app_name]:-}" ]]; then
    port="${PORTS[$app_name]}"
    
    # Skip null and extends entries
    if [[ "$port" == "null" || "$port" == extends:* ]]; then
      log_info "$app_name: port is $port (skipping validation)"
    else
      # Check if port appears in installer script
      if grep -q ":${port}\b" "$installer" || grep -q "PORT.*${port}" "$installer"; then
        log_success "$app_name: port $port matches master.json"
      else
        log_error "$app_name: port mismatch (master.json: $port, not found in script)"
      fi
    fi
  else
    log_warning "$app_name: not in master.json deployment.ports"
  fi
  
  # Check 6: File is executable
  if [[ ! -x "$installer" ]]; then
    log_warning "$app_name: not executable (run: chmod +x $installer)"
  fi
  
  echo ""
done

# Check for installers in master.json that don't have .sh files
echo -e "━━━ Checking master.json installers ━━━\n"

MISSING_INSTALLERS=()
while read -r installer_name; do
  if [[ ! -f "${SCRIPT_DIR}/${installer_name}.sh" ]]; then
    MISSING_INSTALLERS+=("$installer_name")
    log_error "master.json references $installer_name but ${installer_name}.sh not found"
  fi
done < <(jq -r '.deployment.installers[].n' "$MASTER_JSON")

# Summary
echo -e "\n╔════════════════════════════════════════════════════════╗"
echo -e "║  Validation Summary                                    ║"
echo -e "╚════════════════════════════════════════════════════════╝\n"

log_info "Found ${#FOUND_INSTALLERS[@]} installer scripts"
log_info "Found ${#PORTS[@]} port assignments in master.json"

if [[ ${#MISSING_INSTALLERS[@]} -gt 0 ]]; then
  log_error "${#MISSING_INSTALLERS[@]} installer(s) missing: ${MISSING_INSTALLERS[*]}"
fi

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo -e "${GREEN}✓ All installers validated successfully!${NC}\n"
  exit 0
elif [[ $ERRORS -eq 0 ]]; then
  echo -e "${YELLOW}⚠ Validation complete with $WARNINGS warning(s)${NC}\n"
  exit 0
else
  echo -e "${RED}✗ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}\n"
  exit 1
fi
