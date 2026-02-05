# zti-config

Configuration management roles and playbooks for MSP infrastructure tools.

## Quick Start

**Prerequisites:**

- Ansible 2.14+
- Python 3.8+

**Install:**

```bash
git clone https://github.com/example-org/zti-config.git
cd zti-config
make install     # Install Ansible and dependencies
npm install      # Install prettier (for markdown formatting)
```

**Run:**

```bash
# Security baseline
ansible-playbook tools/ansible/playbooks/01-base-security.yml -i inventory/hosts.yml

# Full stack deployment
ansible-playbook tools/ansible/playbooks/99-full-stack.yml -i inventory/hosts.yml
```

## What's Included

### Standalone Roles

- **wazuh_agent** - Security monitoring agent
- **system_updates** - OS patching and maintenance
- **firmware_updates** - Firmware update management
- **otel_collector** - OpenTelemetry collector for observability

### Service Collections

- **headscale** - VPN mesh network (6 roles + playbooks)
- **authentik** - Identity provider (16 roles + playbooks)

### Example Playbooks

Numbered playbooks show dependency order:

```
01-base-security.yml    - Wazuh security agent
02-system-updates.yml   - OS and firmware updates
03-monitoring.yml       - OpenTelemetry collector
04-vpn-mesh.yml        - Headscale VPN
05-identity.yml        - Authentik IdP
99-full-stack.yml      - Complete deployment
```

## Documentation

- [Quick Start](docs/QUICK_START.md) - Getting started guide
- [Roles Reference](docs/ROLES.md) - Available roles and usage
- [Collections](docs/COLLECTIONS.md) - Headscale and Authentik setup
- [Playbooks](docs/PLAYBOOKS.md) - Playbook examples and patterns
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Architecture](docs/ARCHITECTURE.md) - Repository design
- [Adding Tools](docs/ADDING_TOOLS.md) - Extension guide

## Repository Structure

```
zti-config/
├── tools/
│   └── ansible/              # Ansible configuration management
│       ├── roles/            # Standalone shared roles
│       ├── collections/      # Complete service projects
│       ├── playbooks/        # Example playbooks
│       ├── inventory/        # Sample inventories
│       └── docs/             # Detailed documentation
├── scripts/                  # Utility scripts
├── docs/                     # Architecture and guides
└── .github/                  # CI/CD workflows
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT
