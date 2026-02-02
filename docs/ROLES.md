# Roles Reference

Complete reference for all available Ansible roles.

## Standalone Roles

### wazuh_agent

**Purpose:** Install and configure Wazuh security monitoring agent

**Location:** `tools/ansible/roles/wazuh_agent/`

**Platforms:** Ubuntu, Debian, RHEL, CentOS, Fedora, Amazon Linux

**Key Variables:**

```yaml
wazuh_manager_address: "wazuh.example.com"
wazuh_manager_port: 1514
wazuh_agent_version: "4.14.1-1"
```

**Usage:**

```yaml
- hosts: all
  roles:
    - wazuh_agent
```

---

### system_updates

**Purpose:** Monthly OS patching and system maintenance

**Location:** `tools/ansible/roles/system_updates/`

**Platforms:** Ubuntu, Debian

**Key Features:**

- OS package updates
- Firmware updates via fwupd
- Automatic report generation
- Standalone script deployment

**Usage:**

```yaml
- hosts: all
  roles:
    - system_updates
```

---

### firmware_updates

**Purpose:** Firmware update management via fwupd

**Location:** `tools/ansible/roles/firmware_updates/`

**Platforms:** Ubuntu, Debian (with UEFI support)

**Key Features:**

- UEFI/BIOS updates
- NVMe SSD firmware
- Thunderbolt controllers
- Embedded controllers

**Usage:**

```yaml
- hosts: laptops
  roles:
    - firmware_updates
```

---

### signoz_otel_collector

**Purpose:** Install and configure SigNoz OpenTelemetry collector

**Location:** `tools/ansible/roles/signoz_otel_collector/`

**Platforms:** Linux (systemd-based)

**Key Variables:**

```yaml
signoz_endpoint: "http://signoz-server:4317"
otel_collector_version: "latest"
```

**Usage:**

```yaml
- hosts: monitoring
  roles:
    - signoz_otel_collector
```

---

## Role Dependencies

Visual dependency graph:

```
No dependencies:
  ├── wazuh_agent
  ├── system_updates
  ├── firmware_updates
  └── signoz_otel_collector

These roles can be deployed independently in any order.
```

## Using Roles

### In a Playbook

```yaml
---
- name: Configure servers
  hosts: all
  become: true

  roles:
    - role: wazuh_agent
      tags: [security]

    - role: system_updates
      tags: [updates]
```

### With Variables

```yaml
---
- name: Configure monitoring
  hosts: monitoring
  become: true

  roles:
    - role: signoz_otel_collector
      vars:
        signoz_endpoint: "http://custom-server:4317"
      tags: [monitoring]
```

### With Tags

```yaml
# Run only security roles
ansible-playbook playbook.yml --tags security

# Skip updates
ansible-playbook playbook.yml --skip-tags updates
```

## Role Structure

Standard role layout:

```
role_name/
├── tasks/
│   └── main.yml       # Main task file
├── defaults/
│   └── main.yml       # Default variables
├── handlers/
│   └── main.yml       # Handlers (optional)
├── templates/
│   └── *.j2           # Jinja2 templates
└── files/
    └── *              # Static files
```

## Role Details

For detailed variable definitions, platform-specific notes, and troubleshooting:

1. Navigate to the role directory: `tools/ansible/roles/<role_name>/`
2. Review the role's defaults: `defaults/main.yml`
3. Check the tasks: `tasks/main.yml`
4. Review templates (if any): `templates/`

## Best Practices

1. **Use defaults** - Roles work with default values
2. **Override carefully** - Only change variables you need
3. **Test first** - Use `--check` mode before applying
4. **Tag wisely** - Use tags for selective execution
5. **Read defaults** - Check `defaults/main.yml` for all options

## Next Steps

- [Collections](COLLECTIONS.md) - Multi-role service collections
- [Playbooks](PLAYBOOKS.md) - Example playbooks
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues
