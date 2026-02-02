#!/bin/bash
# Headscale Health Check Runner
# Run periodically via cron or external scheduler
#
# Usage:
#   ./scripts/healthcheck.sh              # Check and repair
#   ./scripts/healthcheck.sh --check      # Check only (no changes)
#   ./scripts/healthcheck.sh --upgrade    # Include package upgrades
#
# Cron example (daily at 3 AM):
#   0 3 * * * /opt/ansible/headscale/scripts/healthcheck.sh >> /var/log/headscale-healthcheck.log 2>&1
#
# Required: HEADSCALE_ANSIBLE_VAULT_PASS environment variable
#   Export in cron: 0 3 * * * HEADSCALE_ANSIBLE_VAULT_PASS="xxx" /path/to/healthcheck.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }

# Check vault password
if [[ -z "$HEADSCALE_ANSIBLE_VAULT_PASS" ]]; then
    error "HEADSCALE_ANSIBLE_VAULT_PASS environment variable not set"
fi

# Parse arguments
TAGS="repair"
case "${1:-}" in
    --check)
        TAGS="check"
        log "Running in CHECK mode (no changes)"
        ;;
    --upgrade)
        TAGS="repair,upgrade"
        log "Running with UPGRADE mode (includes package updates)"
        ;;
    *)
        log "Running in REPAIR mode (will fix issues)"
        ;;
esac

cd "$ANSIBLE_DIR"

# Activate virtual environment if exists
if [[ -f ".venv/bin/activate" ]]; then
    source .venv/bin/activate
fi

log "Starting Headscale health check..."

ansible-playbook playbooks/headscale-healthcheck.yml \
    --vault-password-file <(echo "$HEADSCALE_ANSIBLE_VAULT_PASS") \
    --tags "$TAGS"

EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
    log "${GREEN}Health check completed successfully${NC}"
else
    log "${RED}Health check failed with exit code $EXIT_CODE${NC}"
fi

exit $EXIT_CODE
