# Playbooks Guide

Example playbooks and usage patterns.

## Numbered Playbooks

Playbooks are numbered to show dependency order:

### 01-base-security.yml

**Purpose:** Install Wazuh security agent

**Dependencies:** None

**Hosts:** All servers

**Usage:**

```bash
ansible-playbook tools/ansible/playbooks/01-base-security.yml \
  -i inventory/hosts.yml
```

**When to run:**

- First step in new server setup
- Adding servers to monitoring
- Re-enrolling failed agents

---

### 02-system-updates.yml

**Purpose:** OS and firmware updates

**Dependencies:** None (can run independently)

**Hosts:** All servers

**Usage:**

```bash
ansible-playbook tools/ansible/playbooks/02-system-updates.yml \
  -i inventory/hosts.yml
```

**When to run:**

- Monthly maintenance window
- Security patch deployment
- Before major upgrades

---

### 03-monitoring.yml

**Purpose:** Deploy SigNoz OTEL collector

**Dependencies:** None

**Hosts:** Monitoring group

**Usage:**

```bash
ansible-playbook tools/ansible/playbooks/03-monitoring.yml \
  -i inventory/hosts.yml
```

**When to run:**

- Setting up observability stack
- Adding new monitoring endpoints
- Upgrading collector version

---

### 04-vpn-mesh.yml

**Purpose:** Deploy Headscale VPN mesh

**Dependencies:** 01-base-security.yml recommended

**Hosts:** Headscale group

**Usage:**

```bash
ansible-playbook tools/ansible/playbooks/04-vpn-mesh.yml \
  -i inventory/hosts.yml
```

**When to run:**

- Initial VPN setup
- Adding new VPN server
- Disaster recovery

---

### 05-identity.yml

**Purpose:** Configure Authentik IdP

**Dependencies:**

- 01-base-security.yml recommended
- 04-vpn-mesh.yml for network connectivity

**Hosts:** Authentik group

**Usage:**

```bash
ansible-playbook tools/ansible/playbooks/05-identity.yml \
  -i inventory/hosts.yml
```

**When to run:**

- Initial SSO setup
- Adding new identity providers
- Updating authentication policies

---

### 99-full-stack.yml

**Purpose:** Deploy complete infrastructure

**Dependencies:** Orchestrates all playbooks (01-05)

**Hosts:** All groups

**Usage:**

```bash
ansible-playbook tools/ansible/playbooks/99-full-stack.yml \
  -i inventory/hosts.yml
```

**When to run:**

- Complete infrastructure deployment
- Disaster recovery
- New environment setup

**Execution order:**

1. Security baseline (01)
2. System updates (02)
3. Monitoring (03)
4. VPN mesh (04)
5. Identity provider (05)

---

## Common Patterns

### Check Mode (Dry Run)

Test without making changes:

```bash
ansible-playbook playbook.yml --check --diff
```

### Limit to Specific Hosts

Run on subset of inventory:

```bash
# Single host
ansible-playbook playbook.yml --limit server01

# Host group
ansible-playbook playbook.yml --limit web-servers

# Multiple hosts
ansible-playbook playbook.yml --limit "server01,server02"
```

### Using Tags

Run specific tasks:

```bash
# Run only security tasks
ansible-playbook playbook.yml --tags security

# Skip firmware updates
ansible-playbook playbook.yml --skip-tags firmware

# Multiple tags
ansible-playbook playbook.yml --tags "security,updates"
```

### Extra Variables

Override variables at runtime:

```bash
ansible-playbook playbook.yml \
  -e "wazuh_manager_address=wazuh.prod.example.com"
```

### Verbose Output

Debug playbook execution:

```bash
ansible-playbook playbook.yml -v    # Basic verbose
ansible-playbook playbook.yml -vv   # More verbose
ansible-playbook playbook.yml -vvv  # Debug level
```

### Parallel Execution

Control parallelism:

```bash
# Run on 5 hosts at a time
ansible-playbook playbook.yml --forks 5

# Serial execution (one at a time)
ansible-playbook playbook.yml --forks 1
```

## Custom Playbooks

### Simple Custom Playbook

```yaml
---
- name: Custom Server Setup
  hosts: web-servers
  become: true

  roles:
    - wazuh_agent
    - system_updates

  tasks:
    - name: Install nginx
      ansible.builtin.apt:
        name: nginx
        state: present
```

### Multi-Stage Playbook

```yaml
---
# Stage 1: Security
- name: Security Baseline
  hosts: all
  become: true
  roles:
    - wazuh_agent

# Stage 2: Updates
- name: System Maintenance
  hosts: all
  become: true
  roles:
    - system_updates

# Stage 3: Application
- name: Deploy Application
  hosts: app-servers
  become: true
  tasks:
    - name: Deploy app
      # ... custom tasks
```

### Conditional Execution

```yaml
---
- name: Conditional Setup
  hosts: all
  become: true

  roles:
    - role: wazuh_agent
      when: enable_security | default(true)

    - role: firmware_updates
      when: ansible_virtualization_role == "host"
```

## Best Practices

1. **Follow numbering** - Respect dependencies
2. **Use check mode** - Test before applying
3. **Tag strategically** - Enable selective execution
4. **Limit scope** - Test on subset first
5. **Version control** - Track playbook changes
6. **Document changes** - Comment complex logic
7. **Handle failures** - Use error handling
8. **Idempotency** - Ensure repeatable execution

## Next Steps

- [Roles Reference](ROLES.md) - Available roles
- [Collections](COLLECTIONS.md) - Multi-role services
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues
