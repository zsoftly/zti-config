# Authentik Identity Provider

> **Full documentation has moved to
> [`/docs/authentication/authentik.md`](/docs/authentication/authentik.md)**

## Quick Start

```bash
cd aws/ansible/authentik
ansible-playbook playbooks/configure.yml --tags all \
  --vault-password-file <(echo "$AUTHENTIK_ANSIBLE_VAULT_PASS")
```

See [full documentation](/docs/authentication/authentik.md) for details.
