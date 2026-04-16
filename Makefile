.PHONY: help install lint lint-yaml lint-ansible validate test clean fmt fmt-check release

# Default target
help:
	@echo "Available targets:"
	@echo "  install       - Install Ansible and Galaxy dependencies"
	@echo "  lint          - Run all linters (YAML + Ansible)"
	@echo "  lint-yaml     - Run yamllint only"
	@echo "  lint-ansible  - Run ansible-lint only"
	@echo "  validate      - Validate playbook syntax"
	@echo "  test          - Run all tests (lint + validate + format check)"
	@echo "  fmt           - Format markdown files with prettier"
	@echo "  fmt-check     - Check markdown formatting"
	@echo "  clean         - Remove temporary files"
	@echo "  release       - Tag and push a release (usage: make release VERSION=1.0.1)"

# Install dependencies
install:
	@echo "Installing Ansible and dependencies..."
	@bash scripts/install-requirements.sh

# Run all linters
lint: lint-yaml lint-ansible

# Run yamllint
lint-yaml:
	@echo "Running yamllint..."
	@bash scripts/lint-all.sh yaml

# Run ansible-lint
lint-ansible:
	@echo "Running ansible-lint..."
	@bash scripts/lint-all.sh ansible

# Validate playbook syntax
validate:
	@echo "Validating playbook syntax..."
	@bash scripts/validate-playbooks.sh

# Format markdown files
fmt:
	@echo "Formatting markdown files..."
	@npx prettier --write '**/*.md'

# Check markdown formatting
fmt-check:
	@echo "Checking markdown formatting..."
	@npx prettier --check '**/*.md'

# Run all tests
test: lint validate fmt-check
	@echo "All tests passed!"

# Create and push a release tag — triggers the release workflow
# Usage: make release VERSION=1.0.1
release:
	@if [ -z "$(VERSION)" ]; then echo "[FAIL] VERSION is required: make release VERSION=0.0.2"; exit 1; fi
	@if ! echo "$(VERSION)" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$$'; then echo "[FAIL] VERSION must be semver (e.g. 0.0.2), got: $(VERSION)"; exit 1; fi
	@TAGS=$$(git tag 2>&1) || { echo "[FAIL] git tag failed: $$TAGS"; exit 1; }; \
	  if echo "$$TAGS" | grep -q "^$(VERSION)$$"; then echo "[FAIL] Tag $(VERSION) already exists"; exit 1; fi
	@echo "[OK] Tagging release $(VERSION)"
	git tag "$(VERSION)"
	git push origin "$(VERSION)"
	@echo "[OK] Release $(VERSION) pushed — GitHub Actions will create the release"

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -type f -name "*.retry" -delete
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@rm -rf /tmp/ansible* 2>/dev/null || true
	@echo "Cleanup complete"
