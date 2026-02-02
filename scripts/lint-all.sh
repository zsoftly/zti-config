#!/usr/bin/env bash
# Run YAML and Ansible linters

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Usage
usage() {
    echo "Usage: $0 [yaml|ansible|all]"
    echo ""
    echo "Options:"
    echo "  yaml     - Run yamllint only"
    echo "  ansible  - Run ansible-lint only"
    echo "  all      - Run both linters (default)"
    exit 1
}

# Parse arguments
MODE="${1:-all}"

case "$MODE" in
    yaml)
        RUN_YAML=true
        RUN_ANSIBLE=false
        ;;
    ansible)
        RUN_YAML=false
        RUN_ANSIBLE=true
        ;;
    all)
        RUN_YAML=true
        RUN_ANSIBLE=true
        ;;
    *)
        usage
        ;;
esac

# Check for linters
if [ "$RUN_YAML" = true ] && ! command -v yamllint &> /dev/null; then
    error "yamllint not found. Install: pip install yamllint"
    exit 1
fi

if [ "$RUN_ANSIBLE" = true ] && ! command -v ansible-lint &> /dev/null; then
    error "ansible-lint not found. Install: pip install ansible-lint"
    exit 1
fi

# Run yamllint
if [ "$RUN_YAML" = true ]; then
    info "Running yamllint..."
    if yamllint .; then
        success "yamllint passed!"
    else
        error "yamllint failed!"
        exit 1
    fi
    echo ""
fi

# Run ansible-lint
if [ "$RUN_ANSIBLE" = true ]; then
    info "Running ansible-lint..."
    if ansible-lint; then
        success "ansible-lint passed!"
    else
        error "ansible-lint failed!"
        exit 1
    fi
    echo ""
fi

success "All linting checks passed!"
