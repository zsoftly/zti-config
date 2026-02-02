# Contributing to zti-config

Thank you for your interest in contributing! This guide will help you get
started.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/zti-config.git`
3. Install dependencies: `npm install` (for prettier formatting)
4. Create a branch following our branch strategy (see below)
5. Make your changes
6. Format markdown: `npm run fmt`
7. Test your changes: `make test`
8. Submit a pull request to `main`

## Branch Strategy

We use a simplified branch model with three types of branches:

### main

- Primary branch for stable code
- All pull requests merge here
- Protected branch (requires reviews and passing CI)
- Automatically deployed/released when ready

### issue/[issue-number]-brief-description

For feature development and bug fixes:

```bash
# Create issue branch from main
git checkout main
git pull origin main
git checkout -b issue/123-add-nginx-role

# Work on your changes
# Commit, push, create PR to main
```

**Examples:**

- `issue/45-add-prometheus-role`
- `issue/67-fix-wazuh-agent-enrollment`
- `issue/89-update-documentation`

### release/[version]

For release preparation:

```bash
# Create release branch from main
git checkout main
git pull origin main
git checkout -b release/1.2.0

# Update version numbers, CHANGELOG, etc.
# Create PR to main
# After merge, tag the release
```

**Examples:**

- `release/1.0.0`
- `release/1.1.0`
- `release/2.0.0-beta.1`

**Branch Rules:**

- Always branch from `main`
- Always PR back to `main`
- Delete branches after merge
- No long-lived feature branches

## Adding a New Role

1. Create the role directory structure:

```bash
mkdir -p tools/ansible/roles/your_role/{tasks,defaults,handlers,templates}
```

2. Add role files:
   - `tasks/main.yml` - Main task definitions
   - `defaults/main.yml` - Default variables
   - `handlers/main.yml` - Handlers (if needed)
   - `README.md` - Role documentation

3. Create an example playbook in `tools/ansible/playbooks/`

4. Update documentation:
   - Add role to `tools/ansible/docs/ROLES.md`
   - Update main `README.md` if it's a major addition

## Adding a Collection

Collections are complete Ansible projects for complex services:

1. Create collection directory:

```bash
mkdir -p tools/ansible/collections/your_service
```

2. Add project structure:

```
your_service/
├── roles/         # Multiple related roles
├── playbooks/     # Service-specific playbooks
├── vars/          # Variable files
├── inventory/     # Sample inventory
└── README.md      # Service documentation
```

3. Create integration playbook in `tools/ansible/playbooks/`

## Code Standards

### Ansible Best Practices

- Use YAML syntax for all playbooks and roles
- Follow Ansible naming conventions (lowercase with underscores)
- Add comments for complex logic
- Use meaningful variable names
- Include default values in `defaults/main.yml`

### Testing

Before submitting a PR, ensure all tests pass:

```bash
# Run all tests
make test

# Or run individual checks
make lint-yaml      # YAML linting
make lint-ansible   # Ansible linting
make validate       # Syntax check
```

### Linting and Formatting

Code must pass all quality checks:

**YAML Linting:**

- yamllint checks YAML syntax and style
- ansible-lint checks Ansible best practices
- Fix any warnings or errors before submitting

**Markdown Formatting:**

```bash
# Format all markdown files
make fmt

# Check formatting without changes
make fmt-check
```

Prettier ensures consistent markdown formatting across the repository (called
via `make` which uses `npx`).

## Commit Message Format

Use conventional commit format:

```
type(scope): description

[optional body]
[optional footer]
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `chore`: Maintenance tasks
- `test`: Adding or updating tests
- `refactor`: Code refactoring

**Examples:**

```
feat(roles): add nginx role for web servers
fix(wazuh): correct agent enrollment port
docs(playbooks): update 01-base-security example
```

## Pull Request Process

1. **Update documentation** if you're adding features
2. **Add tests** or update existing tests
3. **Run tests** locally before submitting: `make test`
4. **Update CHANGELOG.md** with your changes
5. **Write clear PR description** explaining what and why

### PR Checklist

- [ ] Code follows project style guidelines
- [ ] All tests pass (`make test`)
- [ ] Markdown formatted (`make fmt`)
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Commit messages follow conventional format
- [ ] PR title follows format: `type(scope): description`
- [ ] Branch follows naming convention (issue/XX or release/X.Y.Z)

## CI/CD Checks

All PRs must pass:

- **YAML Lint** - YAML syntax and style
- **Ansible Lint** - Ansible best practices
- **Syntax Check** - Playbook syntax validation
- **Security Scan** - Secret detection and security checks

## Questions?

- Open an issue with the `question` label
- Provide context and examples
- Be specific about what you need help with

## Code of Conduct

- Be respectful and constructive
- Welcome newcomers
- Focus on what is best for the community
- Show empathy towards other community members

Thank you for contributing to zti-config!
