# Ansible Collections

Complete Ansible projects for multi-role services.

## Available Collections

- **headscale** - VPN mesh network (Tailscale alternative)
- **authentik** - Identity provider (SSO, LDAP, SAML, OIDC)

## Documentation

Complete documentation is available in the central docs directory:

- [Collections Guide](../../../docs/COLLECTIONS.md) - Detailed collection
  documentation
- [Quick Start](../../../docs/QUICK_START.md) - Getting started
- [Playbooks](../../../docs/PLAYBOOKS.md) - Usage patterns
- [Troubleshooting](../../../docs/TROUBLESHOOTING.md) - Common issues

## Collection Structure

Each collection contains:

- `roles/` - Multiple related roles
- `playbooks/` - Service-specific playbooks
- `vars/` - Configuration variables
- `inventory/` - Sample inventory
- `docs/` - Service-specific documentation (if applicable)

See the [Collections Guide](../../../docs/COLLECTIONS.md) for detailed setup
instructions and configuration options.
