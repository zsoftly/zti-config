#!/bin/bash
#
# Setup Python virtual environment for Ansible
#
# Usage: ./setup-venv.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEADSCALE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$HEADSCALE_DIR"

echo "[INFO] Creating Python virtual environment..."
python3 -m venv .venv

echo "[INFO] Activating virtual environment..."
source .venv/bin/activate

echo "[INFO] Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements-ansible.txt

echo "[INFO] Installing Ansible collections..."
ansible-galaxy collection install -r requirements.yml

echo ""
echo "[OK] Setup complete!"
echo ""
echo "To activate: source .venv/bin/activate"
echo "To run: ansible-playbook playbooks/headscale-install.yml"
