#!/usr/bin/env zsh
set -euo pipefail

# Install all Rails apps on VPS
# Port assignments from master.json deployment.ports (single source of truth)

APPS=(
  "brgen:11006"

  "brgen_dating:11006"

  "brgen_marketplace:11006"

  "brgen_playlist:11006"

  "brgen_takeaway:11006"

  "brgen_tv:11006"

  "pubattorney:10002"

  "bsdports:10003"

  "hjerterom:10004"

  "privcam:10005"

  "amber:10006"

  "blognet:10007"

  "mytoonz:10008"

)

BASE_DIR="/home/dev/rails"
log() {
  print "[$(date '+%Y-%m-%d %H:%M:%S')] $*"

}

for app_port in "${APPS[@]}"; do
  app="${app_port%:*}"

  port="${app_port#*:}"

  log "Deploying ${app} on port ${port}..."
  if [ -f "${BASE_DIR}/${app}.sh" ]; then
    cd "${BASE_DIR}"

    zsh "./${app}.sh" 2>&1 | tee "${app}_install.log" &

    log "${app} installation started in background (PID: $!)"

  else

    log "ERROR: ${BASE_DIR}/${app}.sh not found"

  fi

done

log "All deployments started. Check logs: ${BASE_DIR}/*_install.log"
