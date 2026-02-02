.PHONY: help install lint lint-yaml lint-ansible validate test clean fmt fmt-check

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

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -type f -name "*.retry" -delete
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@rm -rf /tmp/ansible* 2>/dev/null || true
	@echo "Cleanup complete"
