# Ansible Roles

Shared Ansible roles for infrastructure configuration.

## Available Roles

- **wazuh_agent** - Security monitoring agent
- **system_updates** - OS patching and maintenance
- **firmware_updates** - Firmware update management
- **signoz_otel_collector** - OpenTelemetry collector

## Documentation

Complete documentation is available in the central docs directory:

- [Roles Reference](../../../docs/ROLES.md) - Detailed role documentation
- [Quick Start](../../../docs/QUICK_START.md) - Getting started
- [Troubleshooting](../../../docs/TROUBLESHOOTING.md) - Common issues

## Role-Specific Details

Each role contains:

- `tasks/main.yml` - Main tasks
- `defaults/main.yml` - Default variables
- `handlers/main.yml` - Handlers (if applicable)
- `templates/` - Jinja2 templates (if applicable)

See the [Roles Reference](../../../docs/ROLES.md) for variable definitions,
usage examples, and requirements for each role.
