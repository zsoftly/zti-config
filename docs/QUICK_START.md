# Quick Start Guide

Get started with zti-config in minutes.

## Installation

### 1. Clone Repository

```bash
git clone https://github.com/example-org/zti-config.git
cd zti-config
```

### 2. Install Dependencies

```bash
make install
```

This installs:

- Ansible
- ansible-lint and yamllint
- Required Ansible Galaxy collections

### 3. Configure Inventory

Copy and customize the sample inventory:

```bash
cp tools/ansible/inventory/sample-hosts.yml tools/ansible/inventory/hosts.yml
# Edit hosts.yml with your server details
```

## Basic Usage

### Run a Single Role

Deploy Wazuh security agent:

```bash
ansible-playbook tools/ansible/playbooks/01-base-security.yml \
  -i tools/ansible/inventory/hosts.yml
```

### Run Multiple Roles

Deploy system updates and firmware:

```bash
ansible-playbook tools/ansible/playbooks/02-system-updates.yml \
  -i tools/ansible/inventory/hosts.yml
```

### Deploy Full Stack

Run all configurations in dependency order:

```bash
ansible-playbook tools/ansible/playbooks/99-full-stack.yml \
  -i tools/ansible/inventory/hosts.yml
```

## Common Options

### Check Mode (Dry Run)

```bash
ansible-playbook playbook.yml --check
```

### Limit to Specific Hosts

```bash
ansible-playbook playbook.yml --limit web-servers
```

### Use Tags

```bash
# Run only security-related tasks
ansible-playbook playbook.yml --tags security

# Skip firmware updates
ansible-playbook playbook.yml --skip-tags firmware
```

### Verbose Output

```bash
ansible-playbook playbook.yml -v    # Verbose
ansible-playbook playbook.yml -vv   # More verbose
ansible-playbook playbook.yml -vvv  # Debug
```

## Next Steps

- [Roles Reference](ROLES.md) - Learn about available roles
- [Collections](COLLECTIONS.md) - Set up Headscale and Authentik
- [Playbooks](PLAYBOOKS.md) - Advanced playbook usage
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues

## Getting Help

- Check [Troubleshooting](TROUBLESHOOTING.md) for common issues
- Review role-specific READMEs in `roles/*/README.md`
- Open an issue on GitHub
