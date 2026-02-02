#!/usr/bin/env bash
# Install Ansible and Galaxy dependencies for zti-config

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    error "Python 3 is not installed. Please install Python 3.8+ first."
    exit 1
fi

info "Python version: $(python3 --version)"

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    error "pip3 is not installed. Please install pip first."
    exit 1
fi

# Install Ansible
info "Installing Ansible..."
pip3 install --user ansible ansible-lint yamllint

# Verify Ansible installation
if ! command -v ansible &> /dev/null; then
    error "Ansible installation failed. Please check your PATH."
    exit 1
fi

info "Ansible version: $(ansible --version | head -n1)"

# Install Ansible Galaxy collections
info "Installing Ansible Galaxy collections..."
if [ -f "requirements.yml" ]; then
    ansible-galaxy collection install -r requirements.yml
else
    warn "requirements.yml not found, skipping Galaxy collections"
fi

# Check for collection-specific requirements
info "Checking for collection-specific Python requirements..."

for req_file in tools/ansible/collections/*/requirements-ansible.txt; do
    if [ -f "$req_file" ]; then
        info "Installing requirements from $req_file..."
        pip3 install --user -r "$req_file"
    fi
done

info "Installation complete!"
info ""
info "Next steps:"
info "  1. Verify installation: make test"
info "  2. Run a playbook: ansible-playbook tools/ansible/playbooks/01-base-security.yml"
info "  3. Check documentation: cat docs/QUICK_START.md"
