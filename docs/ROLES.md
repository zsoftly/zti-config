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

### otel_collector

**Purpose:** Install and configure OpenTelemetry collector (works with any OTLP backend)

**Location:** `tools/ansible/roles/otel_collector/`

**Platforms:** Linux (systemd-based)

**Key Variables:**

```yaml
otel_endpoint: "otel-backend.example.com:4317"
otel_collector_version: "0.142.0"
otel_insecure: true
```

**Supported Backends:**

- SigNoz (open-source)
- Grafana Cloud
- Datadog
- New Relic
- Honeycomb
- Any OTLP-compatible endpoint

**Usage:**

```yaml
- hosts: monitoring
  roles:
    - otel_collector
```

---

### ssh_hardening

**Purpose:** SSH security hardening with defense-in-depth controls

**Location:** `tools/ansible/roles/ssh_hardening/`

**Platforms:** Ubuntu, Debian

**Key Features:**

- UFW firewall (network-layer SSH access control)
- SSH daemon hardening (strong crypto, session limits)
- Fail2ban (brute force protection)
- Login banners (legal deterrence)
- Authentik agent integration (optional)

**Usage:**

```yaml
- hosts: endpoints
  roles:
    - ssh_hardening
```

---

## Collection Roles

### Authentik SSH Endpoint Roles

These roles live in `tools/ansible/collections/authentik/roles/` and configure
Linux servers to authenticate SSH users against authentik. No enterprise license
required.

### 15_ssh_password_flow

**Purpose:** Create SSH password authentication flow in authentik via API

**Location:** `tools/ansible/collections/authentik/roles/15_ssh_password_flow/`

**Key Variables:**

```yaml
authentik_url: "https://auth.example.com"
authentik_flow_slug: "ssh-password-authentication"
```

**Runs on:** localhost (API calls only)

---

### 17_endpoint_agent

**Purpose:** Install authentik agent, enroll device, configure NSS and sudo

**Location:** `tools/ansible/collections/authentik/roles/17_endpoint_agent/`

**Key Variables:**

```yaml
authentik_url: "https://auth.example.com"
authentik_domain_name: "zsoftly-linux"
vault_authentik_agent_enrollment_token: "..."  # from vault
endpoint_sudo_nopasswd: false
endpoint_ssh_key_exclusive: true
```

**Key Features:**

- Removes SSSD if present (replaced by authentik agent)
- Installs authentik agent packages from official repository
- Enrolls device to authentik domain
- Configures NSS (passwd, group, shadow) for authentik user resolution
- Provisions SSH authorized_keys for authentik users
- Configures sudo for `linux-users` group

---

### 18_endpoint_pam_exec

**Purpose:** PAM exec authentication against authentik flow executor API

**Location:** `tools/ansible/collections/authentik/roles/18_endpoint_pam_exec/`

**Key Variables:**

```yaml
authentik_url: "https://auth.example.com"
authentik_flow_slug: "ssh-password-authentication"
authentik_pam_exec_uid_threshold: 1001       # UIDs below this use local auth
authentik_pam_exec_skip_ssl_verify: false     # never enable in production
```

**Key Features:**

- Deploys Python PAM script to `/opt/authentik-pam-auth.py`
- Configures `common-auth` with pam_exec + pam_unix fallback
- Removes conflicting `pam_authentik.so` entries (from libpam-authentik)
- Enables PasswordAuthentication and KbdInteractiveAuthentication in sshd
- Adds `pam_mkhomedir` for auto home directory creation
- Validates sshd config and script permissions

---

## Role Dependencies

Visual dependency graph:

```
No dependencies:
  ├── wazuh_agent
  ├── system_updates
  ├── firmware_updates
  ├── otel_collector
  └── ssh_hardening

Authentik SSH (ordered):
  15_ssh_password_flow  (localhost, API only)
  └── 17_endpoint_agent  (requires authentik + enrollment token)
      └── 18_endpoint_pam_exec  (requires agent installed)
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
    - role: otel_collector
      vars:
        otel_endpoint: "otel-backend.example.com:4317"
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
