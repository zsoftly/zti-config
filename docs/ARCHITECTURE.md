# Architecture

Design decisions and structure of zti-config repository.

## Repository Design

### Goals

1. **Future-proof** - Support multiple configuration management tools
2. **Modular** - Roles and collections can be used independently
3. **DRY** - No documentation repetition across files
4. **Open Source** - Share MSP best practices with community

### Principles

- **Separation of concerns** - Tools organized by type (ansible, terraform,
  etc.)
- **Clear dependencies** - Numbered playbooks show execution order
- **Self-documenting** - README files at all levels
- **CI/CD first** - Quality gates enforce best practices

## Directory Structure

```
zti-config/
├── tools/                    # Configuration management tools
│   └── ansible/             # Ansible-specific content
│       ├── roles/           # Standalone shared roles
│       ├── collections/     # Multi-role service projects
│       ├── playbooks/       # Example playbooks
│       ├── inventory/       # Sample inventories
│       └── docs/            # Ansible documentation
│
├── scripts/                 # Cross-tool utilities
│   ├── install-requirements.sh
│   ├── validate-playbooks.sh
│   └── lint-all.sh
│
├── docs/                    # High-level documentation
│   ├── ARCHITECTURE.md      # This file
│   └── ADDING_TOOLS.md      # Extension guide
│
├── .github/                 # CI/CD automation
│   ├── workflows/           # GitHub Actions
│   └── ISSUE_TEMPLATE/      # Issue templates
│
├── ansible.cfg              # Ansible configuration
├── requirements.yml         # Galaxy dependencies
├── Makefile                 # Automation tasks
├── README.md                # Overview
├── CONTRIBUTING.md          # Contribution guidelines
└── CHANGELOG.md             # Version history
```

## Design Patterns

### Roles vs Collections

**Roles** (standalone):

- Single-purpose
- No dependencies
- Reusable across projects
- Example: wazuh_agent, system_updates

**Collections** (projects):

- Multiple related roles
- Complete service setup
- Includes playbooks and vars
- Example: headscale, authentik

### Playbook Numbering

Numbered prefixes indicate dependency order:

```
01-XX.yml  - No dependencies (can run first)
02-XX.yml  - No dependencies (can run in parallel with 01)
03-XX.yml  - No dependencies (can run in parallel with 01-02)
04-XX.yml  - May depend on 01 (security baseline)
05-XX.yml  - May depend on 01, 04 (security + network)
99-XX.yml  - Orchestration (runs all in order)
```

## Configuration Layering

Variables are resolved in this order (highest priority wins):

1. Command-line extra vars (`-e`)
2. Playbook vars
3. Inventory vars
4. Collection vars (`vars/*.yml`)
5. Role defaults (`defaults/main.yml`)

## Documentation Strategy

### DRY Documentation

Each file has a specific purpose - no duplication:

**README.md** - Quick start, overview, links to detailed docs

**CONTRIBUTING.md** - How to contribute (roles, collections, PRs)

**CHANGELOG.md** - Version history

**docs/** - All documentation (architecture, guides, references)

**tools/ansible/roles/README.md** - Role directory overview with links to docs

**tools/ansible/collections/README.md** - Collection directory overview with
links to docs

**tools/ansible/roles/\*/defaults/main.yml** - Role variables and configuration

**tools/ansible/collections/\*/vars/** - Collection-specific variables

### Link Strategy

- Main README links to detailed docs
- Detailed docs link to role/collection READMEs
- Cross-reference related topics
- Always use relative links

## CI/CD Pipeline

### Pull Request Checks

1. **YAML Lint** - Syntax and style
2. **Ansible Lint** - Best practices
3. **Syntax Check** - Playbook validation
4. **Security Scan** - Secret detection

### Automated Workflows

**lint.yml** - Runs on all PRs and pushes

**security.yml** - Runs on main branch and weekly

**pr-checks.yml** - Validates PR format and file changes

## Security Model

### Secrets Management

- Use Ansible Vault for sensitive data
- Never commit unencrypted secrets
- Vault files use `**/vault.yml` naming pattern
- `.gitignore` excludes vault files

### CI/CD Security

- Gitleaks scans for committed secrets
- Vault encryption validation
- Dependency security checks
- No secrets in issue templates

## Scaling Strategy

### Adding New Tools

Future expansion for other configuration management:

```
tools/
├── ansible/        # Current
├── terraform/      # Future: Infrastructure as Code
├── puppet/         # Future: Alternative CM
└── salt/           # Future: Alternative CM
```

See [ADDING_TOOLS.md](ADDING_TOOLS.md) for implementation guide.

### Adding New Roles

1. Create role in `tools/ansible/roles/`
2. Follow standard structure (tasks, defaults, handlers, templates)
3. Add comprehensive README
4. Create example playbook
5. Update documentation

### Adding New Collections

1. Create directory in `tools/ansible/collections/`
2. Include roles, playbooks, vars
3. Add service README
4. Create integration playbook
5. Update documentation

## Testing Strategy

### Local Testing

```bash
make test        # All tests
make lint        # Linting only
make validate    # Syntax check only
```

### CI/CD Testing

- Automated on all PRs
- Blocks merge if tests fail
- Fast feedback loop

### Manual Testing

- Check mode (`--check`)
- Limited hosts (`--limit`)
- Tag-based testing (`--tags`)

## Future Enhancements

### Planned

- Molecule testing framework
- Integration tests
- Performance benchmarks
- Multi-platform support

### Under Consideration

- Terraform modules
- Kubernetes manifests
- Docker Compose files
- Packer templates

## Design Decisions

### Why Numbered Playbooks?

Makes dependency order explicit and visible.

### Why Collections AND Roles?

Collections for complex services, roles for simple components.

### Why tools/ Directory?

Future-proof for multiple configuration management tools.

### Why Separate docs/?

High-level architecture separate from tool-specific guides.

## Contributing to Design

Open an issue to discuss:

- New design patterns
- Structural changes
- Tool additions
- Documentation improvements
