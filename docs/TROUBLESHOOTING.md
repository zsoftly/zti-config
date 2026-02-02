# Troubleshooting Guide

Common issues and solutions for zti-config.

## Installation Issues

### Ansible Not Found After Install

**Problem:** `ansible-playbook` command not found

**Solution:**

```bash
# Add to PATH (bash)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Add to PATH (zsh)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Galaxy Collection Install Fails

**Problem:** `ansible-galaxy collection install` fails

**Solution:**

```bash
# Install with force to overwrite existing
ansible-galaxy collection install -r requirements.yml --force

# Check Galaxy connectivity
curl -I https://galaxy.ansible.com
```

## Playbook Execution Issues

### Permission Denied

**Problem:** Tasks fail with permission denied

**Solutions:**

1. Use `--ask-become-pass`:

```bash
ansible-playbook playbook.yml --ask-become-pass
```

2. Configure sudo in inventory:

```yaml
all:
  vars:
    ansible_become: true
    ansible_become_method: sudo
```

3. Check sudoers configuration on target hosts

### Connection Timeout

**Problem:** Cannot connect to target hosts

**Solutions:**

1. Verify SSH access:

```bash
ssh user@target-host
```

2. Check SSH key authentication:

```bash
ssh-copy-id user@target-host
```

3. Update inventory with correct user:

```yaml
target-host:
  ansible_host: 192.168.1.100
  ansible_user: your-username
```

### Python Not Found

**Problem:** `/usr/bin/python: not found`

**Solution:**

Add to inventory:

```yaml
all:
  vars:
    ansible_python_interpreter: /usr/bin/python3
```

## Role-Specific Issues

### Wazuh Agent

**Problem:** Agent not connecting to manager

**Solutions:**

1. Check manager address:

```bash
# On agent host
cat /var/ossec/etc/ossec.conf | grep address
```

2. Verify network connectivity:

```bash
telnet wazuh-manager 1514
telnet wazuh-manager 1515
```

3. Check agent logs:

```bash
tail -f /var/ossec/logs/ossec.log
```

### System Updates

**Problem:** Updates fail with lock error

**Solution:**

1. Wait for other package managers to finish
2. Remove stale locks:

```bash
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock*
```

### Firmware Updates

**Problem:** No firmware updates available

**Solutions:**

1. Check fwupd support:

```bash
fwupdmgr get-devices
```

2. Refresh metadata:

```bash
fwupdmgr refresh
```

3. Ensure laptop lid is open (critical for firmware updates)

## Syntax and Linting Issues

### YAML Lint Errors

**Problem:** yamllint reports errors

**Common fixes:**

1. Indentation (use 2 spaces):

```yaml
# Wrong
tasks:
- name: Task
    debug:
      msg: "Hello"

# Correct
tasks:
  - name: Task
    debug:
      msg: "Hello"
```

2. Line length (max 120 characters):

```yaml
# Split long lines
- name: >
    This is a very long task name that needs to be split across multiple lines
```

### Ansible Lint Warnings

**Problem:** ansible-lint reports warnings

**Common fixes:**

1. Use FQCN for modules (optional, can be skipped):

```yaml
# Old style (works but warned)
- name: Install package
  apt:
    name: nginx

# New style (preferred)
- name: Install package
  ansible.builtin.apt:
    name: nginx
```

2. Name all tasks:

```yaml
# Bad
- debug:
    msg: "Hello"

# Good
- name: Display greeting
  debug:
    msg: "Hello"
```

## Inventory Issues

### Hosts Not Found

**Problem:** `No hosts matched` error

**Solutions:**

1. Verify inventory syntax:

```bash
ansible-inventory --list -i inventory/hosts.yml
```

2. Check host groups:

```bash
ansible-inventory --graph -i inventory/hosts.yml
```

3. Ensure inventory path is correct in playbook

### Variable Not Defined

**Problem:** `Variable 'X' is not defined`

**Solutions:**

1. Check variable spelling
2. Define in inventory:

```yaml
all:
  vars:
    variable_name: value
```

3. Use defaults in roles (`defaults/main.yml`)

## Collection-Specific Issues

### Headscale

See [docs/TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)

### Authentik

See [docs/aws-sso-integration.md](../docs/aws-sso-integration.md)

## Performance Issues

### Slow Playbook Execution

**Solutions:**

1. Enable pipelining (already in ansible.cfg)
2. Increase forks:

```bash
ansible-playbook playbook.yml --forks 20
```

3. Use strategy plugins:

```yaml
- name: Fast execution
  hosts: all
  strategy: free # Don't wait for all hosts
```

## Getting Help

If you can't find a solution:

1. Check role-specific README files
2. Search GitHub issues
3. Open a new issue with:
   - Ansible version (`ansible --version`)
   - Playbook name
   - Full error message
   - Steps to reproduce

## Debug Mode

Run with maximum verbosity:

```bash
ansible-playbook playbook.yml -vvv
```

Check what Ansible sees:

```bash
# List all hosts
ansible all --list-hosts -i inventory/hosts.yml

# Test connectivity
ansible all -m ping -i inventory/hosts.yml

# Gather facts
ansible all -m setup -i inventory/hosts.yml
```
