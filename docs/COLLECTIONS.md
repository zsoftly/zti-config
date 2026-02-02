# Collections Guide

Complete Ansible projects for complex multi-role services.

## What are Collections?

Collections in zti-config are complete Ansible projects that include:

- Multiple related roles
- Service-specific playbooks
- Configuration variables
- Sample inventories
- Service-specific documentation

Unlike standalone roles, collections manage entire services end-to-end.

## Available Collections

### Headscale VPN Mesh

**Location:** `tools/ansible/collections/headscale/`

**Purpose:** Self-hosted VPN mesh network (Tailscale alternative)

**Includes:**

- 6 roles (docker, headscale, backup, management, prerequisites, system_config)
- 7 playbooks (install, update, backup, status, reset, generate-key,
  wazuh-install)
- Configuration templates and variables
- Service-specific documentation in collection directory

**Quick Start:**

```bash
ansible-playbook tools/ansible/playbooks/04-vpn-mesh.yml \
  -i inventory/hosts.yml
```

**Details:** See `tools/ansible/collections/headscale/` for:

- Role-specific configuration in `roles/*/defaults/main.yml`
- Playbooks for different operations
- Variables in `vars/headscale.yml`
- Inventory example in `inventory/`

---

### Authentik Identity Provider

**Location:** `tools/ansible/collections/authentik/`

**Purpose:** Open-source identity provider (SSO, LDAP, SAML, OIDC)

**Includes:**

- 16 numbered roles (groups, users, security, LDAP, OIDC, SAML, proxy, branding,
  etc.)
- 7 playbooks (configure-all, configure-groups, configure-oidc, configure-ldap,
  etc.)
- Brand assets (logos, icons) in `files/`
- Service-specific documentation in collection directory

**Quick Start:**

```bash
ansible-playbook tools/ansible/playbooks/05-identity.yml \
  -i inventory/hosts.yml
```

**Details:** See `tools/ansible/collections/authentik/` for:

- Role-specific configuration in `roles/*/defaults/main.yml`
- Playbooks for different configurations
- Variables in `vars/` directory
- Example users and groups

---

## Using Collections

### Option 1: Via Integration Playbooks

Use the numbered playbooks in `tools/ansible/playbooks/`:

```bash
# Headscale
ansible-playbook tools/ansible/playbooks/04-vpn-mesh.yml

# Authentik
ansible-playbook tools/ansible/playbooks/05-identity.yml
```

### Option 2: Direct Playbook Execution

Run collection playbooks directly:

```bash
# Headscale install
ansible-playbook tools/ansible/collections/headscale/playbooks/headscale-install.yml

# Authentik configuration
ansible-playbook tools/ansible/collections/authentik/playbooks/configure-all.yml
```

### Option 3: Custom Playbook

Import collection roles in your own playbook:

```yaml
---
- name: Custom Headscale Setup
  hosts: vpn
  become: true

  roles:
    - role: tools/ansible/collections/headscale/roles/prerequisites
    - role: tools/ansible/collections/headscale/roles/docker
    - role: tools/ansible/collections/headscale/roles/headscale
```

## Collection Structure

Standard collection layout:

```
collection_name/
├── roles/              # Multiple related roles
│   ├── 01_role/
│   ├── 02_role/
│   └── ...
├── playbooks/          # Service-specific playbooks
│   ├── install.yml
│   ├── configure.yml
│   └── ...
├── vars/               # Configuration variables
│   ├── main.yml
│   └── vault.yml
├── inventory/          # Sample inventory
│   └── hosts.yml
├── files/              # Static files (icons, configs)
├── scripts/            # Helper scripts
├── docs/               # Service-specific docs (optional)
└── README.md           # Collection documentation
```

## Configuration Management

### Variables

Collections use layered variable precedence:

1. `defaults/main.yml` in each role (lowest priority)
2. `vars/*.yml` in collection root
3. `inventory/hosts.yml` variables
4. Playbook vars
5. Command-line extra vars (highest priority)

### Secrets

Use Ansible Vault for sensitive data:

```bash
# Encrypt secrets
ansible-vault encrypt tools/ansible/collections/*/vars/vault.yml

# Run with vault password
ansible-playbook playbook.yml --ask-vault-pass
```

## Dependencies

### Headscale Dependencies

- Docker and Docker Compose
- Caddy (for HTTPS)
- Network access (ports 443, 3478)

### Authentik Dependencies

- Python 3.8+
- Authentik API access
- PostgreSQL (managed separately)

## Best Practices

1. **Review collection directory** - Check README and vars files
2. **Understand defaults** - Review `roles/*/defaults/main.yml`
3. **Use vault for secrets** - Never commit unencrypted secrets
4. **Test in staging** - Collections modify complex systems
5. **Follow numbering** - Respect role order in Authentik (01-16)

## Collection-Specific Configuration

### Headscale Configuration

Key variables in `tools/ansible/collections/headscale/vars/headscale.yml`:

- Domain configuration
- OIDC settings
- Backup configuration
- Network settings

### Authentik Configuration

Key variables in `tools/ansible/collections/authentik/vars/`:

- `authentik.yml` - Base Authentik URL and API path
- `groups.yml` - Group definitions
- `users.yml` - User definitions
- `oidc-providers.yml` - OIDC application configuration
- `security-policies.yml` - Security policies

## Next Steps

- [Playbooks Guide](PLAYBOOKS.md) - Usage patterns and examples
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues
- [Quick Start](QUICK_START.md) - Getting started guide
