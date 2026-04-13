# 18_endpoint_pam_exec

Configures SSH password authentication on Linux hosts via Authentik's flow executor API using `pam_exec.so`. Works on **all host types** — KVM compute nodes, Proxmox bare-metal, VMs, LXC containers — without an enterprise license.

## Why this role exists (root cause)

`libpam-authentik` ships a native `pam_authentik.so` module that talks to `ak-agent` over a Unix socket at `~/.local/share/authentik/agent.sock`.

That socket is created by `ak-agent`, which is a **user-level systemd service** — it only starts when a user session opens.

On headless servers no user session exists at boot, so `ak-agent` never starts and `pam_authentik.so` silently returns `PAM_IGNORE`.

PAM then falls through to `pam_unix`, which fails because Authentik users carry password hash `x` (no local password). Login denied.

This role replaces `pam_authentik.so` with `pam_exec.so` calling a Python script (`/opt/authentik-pam-auth.py`) that authenticates directly against the Authentik flow API over HTTPS. No socket, no user session dependency.

## PAM stack deployed

```
# /etc/pam.d/common-auth
auth [success=2 default=ignore] pam_exec.so expose_authtok quiet /opt/authentik-pam-auth.py
auth [success=1 default=ignore] pam_unix.so try_first_pass
auth requisite                  pam_deny.so
auth required                   pam_permit.so
auth optional                   pam_cap.so
```

Authentik auth succeeds → skip 2 lines → `pam_permit`.  
Authentik auth fails → try local `pam_unix` (fallback for service accounts).  
Both fail → `pam_deny`.

## Variables

| Variable                             | Default                       | Required | Description                                                                        |
| ------------------------------------ | ----------------------------- | -------- | ---------------------------------------------------------------------------------- |
| `authentik_url`                      | —                             | **yes**  | Authentik server URL, must use `https://`                                          |
| `authentik_flow_slug`                | `ssh-password-authentication` | no       | Flow slug to authenticate against                                                  |
| `authentik_pam_exec_uid_threshold`   | `1001`                        | no       | UIDs below this skip Authentik and go straight to pam_unix                         |
| `authentik_pam_exec_skip_ssl_verify` | `false`                       | no       | Skip TLS verification — never enable in production                                 |
| `vault_authentik_token`              | undefined                     | no       | Authentik API token; if set, role verifies/creates the flow automatically          |
| `endpoint_pam_exec_skip_flow_check`  | `false`                       | no       | Set `true` when the flow already exists and no API token is available in inventory |

## How to run — by host type

All three playbooks use the same role. The only difference is which playbook wraps it and which tag to pass.

### KVM compute nodes (comp-\*)

```bash
cd $HOME/zsoftly/iaas/ansible/cloudstack
ansible-playbook playbooks/000-bootstrap.yml \
  --limit comp-XX \
  --tags authentik,pam-exec \
  --vault-password-file ~/.vault_pass
```

### Proxmox bare-metal (infra-\*)

```bash
cd $HOME/zsoftly/iaas/ansible/proxmox
ansible-playbook playbooks/01-harden-proxmox-host.yml \
  --limit infra-XX \
  --tags pam-exec \
  --vault-password-file ~/.vault_pass
```

### VMs / LXC (Dokploy, monitoring, etc.)

```bash
cd $HOME/zsoftly/iaas/ansible/proxmox
ansible-playbook playbooks/10-bootstrap-ops.yml \
  --limit <vm-hostname> \
  --tags authentik,pam-exec \
  --vault-password-file ~/.vault_pass
```

## `MaxAuthTries` policy and SSH client setup

Servers are hardened to `MaxAuthTries 3`. This is intentional — 3 failed attempts in a 30-minute window triggers a fail2ban ban. Another admin can unban via `fail2ban-client unban <ip>`.

**Problem:** The SSH client tries loaded identity files first. If your agent has 2+ keys loaded, all 3 attempts are consumed on key tries before reaching the password prompt.

**Fix — add to your `~/.ssh/config` on your laptop/workstation:**

```
Host infra-01 infra-02 infra-03 comp-* *.zcp.zsoftly.ca
    PreferredAuthentications keyboard-interactive,password
```

This tells the SSH client to go straight to the interactive/password prompt without wasting auth attempts on key offers. Only needed for Authentik users who do not have an SSH public key in `~/.ssh/authorized_keys` on the target.

## Troubleshooting

**`Permission denied (publickey,password)`** — PAM script may have failed silently. Check auth logs on the target:

```bash
sudo journalctl -u ssh --since "5 min ago" | grep authentik
sudo grep authentik /var/log/auth.log | tail -20
```

**`Too many authentication failures`** — SSH client burnt all 3 tries on key offers before reaching password. See `MaxAuthTries` section above.

**`Received disconnect ... Too many authentication failures`** — same as above.

**PAM script returns non-zero but Authentik UI shows login** — check that `/opt/authentik-pam-auth.py` is owned by root and mode `0700`:

```bash
ls -la /opt/authentik-pam-auth.py
# -rwx------ 1 root root ...
```

**Flow does not exist** — set `vault_authentik_token` in the vault and re-run without `endpoint_pam_exec_skip_flow_check: true`. The role will create the `ssh-password-authentication` flow automatically.

## Idempotency

The role is fully idempotent. Re-running after the initial apply is a no-op (all tasks report `ok`). Safe to include in any periodic hardening run.
