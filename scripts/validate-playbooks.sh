#!/usr/bin/env bash
# Validate Ansible playbook syntax

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

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    error "ansible-playbook not found. Please install Ansible first."
    exit 1
fi

# Find all playbooks
PLAYBOOKS=$(find tools/ansible/playbooks -name "*.yml" -type f)
COLLECTION_PLAYBOOKS=$(find tools/ansible/collections/*/playbooks -name "*.yml" -type f 2>/dev/null || true)

# Combine playbooks
ALL_PLAYBOOKS="$PLAYBOOKS $COLLECTION_PLAYBOOKS"

# Count
TOTAL=$(echo "$ALL_PLAYBOOKS" | wc -w)
PASSED=0
FAILED=0

info "Validating $TOTAL playbooks..."
echo ""

# Validate each playbook
for playbook in $ALL_PLAYBOOKS; do
    echo -n "Checking $(basename "$playbook")... "

    if ansible-playbook --syntax-check "$playbook" &> /dev/null; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}FAIL${NC}"
        ((FAILED++))

        # Show error
        echo ""
        error "Syntax error in $playbook:"
        ansible-playbook --syntax-check "$playbook" 2>&1 | tail -n 10
        echo ""
    fi
done

echo ""
echo "========================================="
echo "  Validation Results"
echo "========================================="
echo "  Total:  $TOTAL"
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"
echo "========================================="

if [ "$FAILED" -gt 0 ]; then
    error "Validation failed! Please fix the errors above."
    exit 1
else
    success "All playbooks passed syntax validation!"
    exit 0
fi
