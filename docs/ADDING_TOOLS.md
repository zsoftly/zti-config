# Adding Configuration Management Tools

Guide for extending zti-config with new configuration management tools.

## Overview

The `tools/` directory is designed to support multiple configuration management
tools beyond Ansible.

## Directory Structure

```
tools/
├── ansible/          # Current - Ansible automation
├── terraform/        # Future - Infrastructure as Code
├── puppet/           # Future - Alternative CM tool
└── salt/             # Future - Alternative CM tool
```

## Adding a New Tool

### Step 1: Create Tool Directory

```bash
mkdir -p tools/your-tool/{modules,templates,docs}
```

### Step 2: Define Structure

Choose a structure appropriate for your tool. Example structures:

**Terraform:**

```
tools/terraform/
├── modules/          # Reusable modules
│   ├── vpc/
│   ├── ec2/
│   └── rds/
├── environments/     # Environment configs
│   ├── dev/
│   ├── staging/
│   └── prod/
├── examples/         # Example configurations
└── docs/             # Terraform-specific docs
```

**Puppet:**

```
tools/puppet/
├── modules/          # Puppet modules
│   ├── apache/
│   ├── mysql/
│   └── nginx/
├── manifests/        # Puppet manifests
├── hiera/            # Hiera data
└── docs/             # Puppet-specific docs
```

**Salt:**

```
tools/salt/
├── states/           # Salt states
│   ├── webserver/
│   ├── database/
│   └── loadbalancer/
├── pillars/          # Pillar data
├── formulas/         # Salt formulas
└── docs/             # Salt-specific docs
```

### Step 3: Add Configuration Files

Create tool-specific config files in the root:

**For Terraform:**

```bash
touch terraform.tfvars.example
touch .terraform-version
```

**For Puppet:**

```bash
touch Puppetfile
touch puppet.conf
```

**For Salt:**

```bash
touch salt-master.conf
touch salt-minion.conf
```

### Step 4: Create Documentation

Add tool-specific docs:

```bash
mkdir -p tools/your-tool/docs
touch tools/your-tool/docs/QUICK_START.md
touch tools/your-tool/docs/MODULES.md
touch tools/your-tool/docs/EXAMPLES.md
```

### Step 5: Add Utility Scripts

Create installation and validation scripts:

```bash
# In scripts/
touch scripts/install-your-tool.sh
touch scripts/validate-your-tool.sh
touch scripts/lint-your-tool.sh
```

Make them executable:

```bash
chmod +x scripts/*.sh
```

### Step 6: Update Makefile

Add targets for your tool:

```makefile
# In Makefile

.PHONY: install-terraform lint-terraform validate-terraform

install-terraform:
	@bash scripts/install-terraform.sh

lint-terraform:
	@bash scripts/lint-terraform.sh

validate-terraform:
	@bash scripts/validate-terraform.sh
```

### Step 7: Add CI/CD Workflows

Create GitHub Actions workflow:

```yaml
# .github/workflows/terraform-checks.yml
---
name: Terraform Checks

on:
  pull_request:
    paths:
      - "tools/terraform/**"
  push:
    branches: [main]
    paths:
      - "tools/terraform/**"

jobs:
  validate:
    name: Validate Terraform
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Format Check
        run: terraform fmt -check -recursive tools/terraform/

      - name: Terraform Validate
        run: |
          cd tools/terraform/
          terraform init -backend=false
          terraform validate
```

### Step 8: Update .gitignore

Add tool-specific ignores:

```gitignore
# Terraform
*.tfstate
*.tfstate.backup
*.tfvars
.terraform/
.terraform.lock.hcl

# Puppet
*.pem
vendor/

# Salt
*.pyc
.salt/
```

### Step 9: Update Main README

Add your tool to the main README:

```markdown
## Configuration Management Tools

### Ansible

Automation and configuration management.

See [tools/ansible/README.md](tools/ansible/README.md)

### Terraform

Infrastructure as Code for cloud resources.

See [tools/terraform/README.md](tools/terraform/README.md)
```

### Step 10: Update CONTRIBUTING.md

Add contribution guidelines for your tool:

```markdown
## Adding Terraform Modules

1. Create module directory in `tools/terraform/modules/`
2. Include main.tf, variables.tf, outputs.tf
3. Add module README.md
4. Create example usage
5. Update documentation
```

## Best Practices

### Consistency

- Follow similar structure to Ansible tools
- Use descriptive directory names
- Include comprehensive READMEs
- Add example usage

### Documentation

- Quick start guide
- Module/resource reference
- Examples and patterns
- Troubleshooting guide

### Testing

- Add linting checks
- Validate syntax
- Test examples
- CI/CD automation

### Integration

- Cross-reference with other tools when relevant
- Share common variables where possible
- Document tool interactions

## Example: Adding Terraform

Full example for adding Terraform support:

```bash
# 1. Create structure
mkdir -p tools/terraform/{modules,environments,examples,docs}

# 2. Add example module
mkdir -p tools/terraform/modules/wazuh-server
cat > tools/terraform/modules/wazuh-server/main.tf <<EOF
resource "aws_instance" "wazuh" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "Wazuh Server"
    Role = "Security Monitoring"
  }
}
EOF

# 3. Add example usage
cat > tools/terraform/examples/wazuh-deployment/main.tf <<EOF
module "wazuh" {
  source = "../../modules/wazuh-server"

  ami_id        = "ami-12345678"
  instance_type = "t3.medium"
}
EOF

# 4. Add documentation
cat > tools/terraform/docs/QUICK_START.md <<EOF
# Terraform Quick Start

## Installation

terraform init tools/terraform/

## Usage

terraform plan
terraform apply
EOF

# 5. Add to CI/CD (as shown in Step 7)

# 6. Update main README (as shown in Step 9)
```

## Questions?

- Open an issue to discuss your tool addition
- Tag with `enhancement` label
- Provide use case and rationale
- Include proposed structure

## Review Process

New tools will be reviewed for:

1. **Relevance** - Fits repository scope
2. **Structure** - Follows conventions
3. **Documentation** - Complete and clear
4. **Testing** - CI/CD integration
5. **Maintenance** - Long-term viability
