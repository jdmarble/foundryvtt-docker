#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

CONFIG_DIR="/data/Config"
ADMIN_KEY_FILE="${CONFIG_DIR}/admin.txt"
CONFIG_FILE="${CONFIG_DIR}/options.json"
# shellcheck disable=SC2034
# LOG_NAME used in sourced file
LOG_NAME="Launcher"
# shellcheck disable=SC1091
# disable following
source logging.sh

# ensure the config directory exists
log_debug "Ensuring ${CONFIG_DIR} directory exists."
mkdir -p "${CONFIG_DIR}"

if [[ "${CONTAINER_PRESERVE_CONFIG:-}" == "true" && -f "${CONFIG_FILE}" ]]; then
  log_warn "CONTAINER_PRESERVE_CONFIG is set: Not updating options.json"
else
  # Update configuration file
  log "Generating options.json file."
  ./set_options.js > "${CONFIG_FILE}"
fi

if [[ "${CONTAINER_PRESERVE_CONFIG:-}" == "true" && -f "${ADMIN_KEY_FILE}" ]];
then
  log_warn "CONTAINER_PRESERVE_CONFIG is set: Not updating admin.txt"
else
  # Save admin access key to file if set.  Delete file if unset.
  if [[ "${FOUNDRY_ADMIN_KEY:-}" ]]; then
    log "Setting 'Admin Access Key'."
    echo "${FOUNDRY_ADMIN_KEY}" | ./set_password.js > "${ADMIN_KEY_FILE}"
  else
    log_warn "No 'Admin Access Key' has been configured."
    rm "${ADMIN_KEY_FILE}" >& /dev/null || true
  fi
fi

if [ "$1" = "--shell" ]; then
  log_warn "Starting a shell as requested by argument --shell"
  /bin/sh
  exit $?
fi

# Spawn node with clean environment to prevent credential leaks
log "Starting Foundry Virtual Tabletop."
env -i HOME="$HOME" /usr/local/bin/node "$@"
