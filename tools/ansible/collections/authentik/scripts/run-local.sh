#!/usr/bin/env bash
#
# Setup local environment for Authentik Ansible playbooks
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTHENTIK_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="${AUTHENTIK_DIR}/.venv"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

AWS_PROFILE="${AWS_PROFILE:-sbx}"

check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI not found"
        exit 1
    fi

    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 not found"
        exit 1
    fi

    log_info "[OK] Prerequisites met"
}

setup_ansible() {
    log_info "Setting up Python venv and Ansible..."

    if [ ! -d "$VENV_DIR" ]; then
        python3 -m venv "$VENV_DIR"
    fi

    source "${VENV_DIR}/bin/activate"

    pip install --quiet --upgrade pip
    pip install --quiet -r "${AUTHENTIK_DIR}/requirements-ansible.txt"

    log_info "Installing Ansible collections..."
    ansible-galaxy collection install -r "${AUTHENTIK_DIR}/requirements.yml" --force > /dev/null 2>&1
    log_info "[OK] Ansible ready"
}

verify_aws() {
    log_info "Verifying AWS credentials..."

    export AWS_PROFILE
    export AWS_DEFAULT_REGION="${AWS_REGION:-ca-central-1}"

    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        log_warn "AWS credentials expired. Running SSO login..."
        if ! aws sso login --profile "$AWS_PROFILE"; then
            log_error "SSO login failed"
            exit 1
        fi
    fi

    IDENTITY=$(aws sts get-caller-identity --query 'Arn' --output text)
    log_info "[OK] Authenticated: $IDENTITY"
}

print_usage() {
    echo ""
    echo "=========================================="
    echo "Setup complete. Run ansible commands:"
    echo "=========================================="
    echo ""
    echo "# Activate venv:"
    echo "source ${VENV_DIR}/bin/activate"
    echo "export AWS_PROFILE=${AWS_PROFILE} AWS_DEFAULT_REGION=ca-central-1"
    echo ""
    echo "# Run all configuration:"
    echo "cd ${AUTHENTIK_DIR}"
    echo "ansible-playbook playbooks/configure-all.yml"
    echo ""
    echo "# Run specific tasks:"
    echo "ansible-playbook playbooks/configure-groups.yml"
    echo "ansible-playbook playbooks/configure-ldap.yml"
    echo "ansible-playbook playbooks/configure-oidc.yml"
    echo ""
}

main() {
    log_info "Authentik Ansible Setup"
    echo ""
    check_prerequisites
    setup_ansible
    verify_aws
    print_usage
}

main
