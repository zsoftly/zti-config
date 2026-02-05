# SSH Hardening Role

Comprehensive SSH security hardening role implementing defense-in-depth security controls for Linux systems.

## Description

This role secures SSH access through multiple layers of defense:

1. **Network Layer (UFW Firewall)** - Controls which networks/interfaces can reach SSH
2. **Application Layer (SSH Daemon)** - Configures SSH with secure settings and strong cryptography
3. **Prevention Layer (Fail2ban)** - Automatically bans IPs with too many failed login attempts
4. **Legal Layer (Login Banners)** - Displays legal/warning messages before and after login

The role follows security best practices and compliance standards (ISO 27001, SOC 2, CIS benchmarks).

## Requirements

- **OS:** Ubuntu/Debian Linux (tested on Ubuntu 22.04+)
- **Privileges:** Root/sudo access
- **Ansible:** 2.9 or higher
- **Collections:**
  - `community.general` (for UFW module)

Install required collections:

```bash
ansible-galaxy collection install community.general
```

## Supported Platforms

- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS
- Debian 11+

## Role Variables

### Required Variables

You MUST define SSH access controls in your inventory or playbook. Choose one or both:

```yaml
# Option 1: Allow SSH from specific IP addresses/subnets
ssh_allowed_sources:
  - "192.168.1.0/24" # LAN subnet
  - "10.0.0.0/8" # VPN subnet
  - "203.0.113.50/32" # Specific admin IP

# Option 2: Allow SSH on specific network interfaces
ssh_allowed_interfaces:
  - "eth0" # LAN interface
  - "tailscale0" # VPN interface
  - "wg0" # Wireguard interface
```

If neither is defined, SSH will be allowed from anywhere (not recommended for production).

### Optional Variables (Banner Configuration)

Customize login banners for your organization:

```yaml
# Banner settings
login_banner_enabled: true
login_banner_company: "YOUR ORGANIZATION"
login_banner_company_short: "YOUR ORG"
login_banner_address: "123 Main St, City, State 12345"
login_banner_classification: "INTERNAL USE ONLY"
login_banner_security_contact: "security@example.com"
```

### Optional Variables (SSH Daemon)

```yaml
# SSH daemon settings
ssh_port: 22 # SSH listening port
ssh_permit_root_login: "no" # Disable root login (recommended)
ssh_password_authentication: "yes" # Allow password auth (disable after key setup)
ssh_pubkey_authentication: "yes" # Allow key-based auth
ssh_max_auth_tries: 3 # Max authentication attempts
ssh_login_grace_time: 30 # Seconds before disconnecting if not authenticated
ssh_client_alive_interval: 300 # Send keepalive every 5 minutes
ssh_client_alive_count_max: 2 # Disconnect after 2 missed keepalives
```

### Optional Variables (Firewall)

```yaml
# Firewall settings
firewall_enabled: true # Enable UFW firewall
firewall_default_incoming: "deny" # Default incoming policy
firewall_default_outgoing: "allow" # Default outgoing policy
```

### Optional Variables (Fail2ban)

```yaml
# Fail2ban settings
fail2ban_enabled: true # Enable fail2ban
fail2ban_bantime: 3600 # Ban duration in seconds (1 hour)
fail2ban_findtime: 600 # Time window for counting failures (10 min)
fail2ban_maxretry: 5 # Max failures before ban

# Whitelist trusted networks from fail2ban (use with caution)
fail2ban_whitelist_lan: false # Set to true in lab/dev environments
fail2ban_trusted_subnets: # Subnets to whitelist (if enabled)
  - "192.168.1.0/24"
  - "10.0.0.0/8"
```

**Warning:** Only enable `fail2ban_whitelist_lan` in lab/dev environments. In production, keep it disabled for security compliance.

## Usage Examples

### Basic Usage - Allow SSH from Specific Subnet

```yaml
- name: Harden SSH Security
  hosts: servers
  become: true

  vars:
    # Allow SSH from LAN subnet only
    ssh_allowed_sources:
      - "192.168.1.0/24"

    # Customize banner
    login_banner_company: "Acme Corporation"
    login_banner_company_short: "Acme"
    login_banner_security_contact: "security@acme.com"

  roles:
    - role: ssh_hardening
```

### VPN-Only SSH Access

```yaml
- name: Harden SSH - VPN Only
  hosts: production
  become: true

  vars:
    # Only allow SSH through VPN interface
    ssh_allowed_interfaces:
      - "tailscale0"

    # Disable password authentication (keys only)
    ssh_password_authentication: "no"

    # Custom SSH port
    ssh_port: 2222

  roles:
    - role: ssh_hardening
```

### Lab Environment with Fail2ban Whitelist

```yaml
- name: Harden SSH - Lab Environment
  hosts: lab
  become: true

  vars:
    ssh_allowed_sources:
      - "192.168.1.0/24"

    # Whitelist LAN from fail2ban to prevent Ansible lockouts
    fail2ban_whitelist_lan: true
    fail2ban_trusted_subnets:
      - "192.168.1.0/24"

  roles:
    - role: ssh_hardening
```

### Multi-Interface Access (LAN + VPN)

```yaml
- name: Harden SSH - Multiple Interfaces
  hosts: servers
  become: true

  vars:
    # Allow SSH from both LAN and VPN
    ssh_allowed_sources:
      - "192.168.1.0/24" # LAN
      - "100.64.0.0/10" # Tailscale VPN

    # Or use interfaces
    ssh_allowed_interfaces:
      - "eth0" # LAN
      - "tailscale0" # VPN

  roles:
    - role: ssh_hardening
```

### Run with Tags

```bash
# Run only firewall configuration
ansible-playbook playbook.yml --tags firewall

# Run only SSH daemon hardening
ansible-playbook playbook.yml --tags sshd

# Run only fail2ban setup
ansible-playbook playbook.yml --tags fail2ban

# Run verification checks
ansible-playbook playbook.yml --tags verify
```

## What's Configured

### SSH Daemon Hardening (`/etc/ssh/sshd_config`)

- **Authentication:**
  - Root login disabled by default
  - Empty passwords disallowed
  - PAM enabled for additional security controls
  - Challenge-response authentication disabled

- **Brute Force Protection:**
  - Max 3 authentication attempts
  - 30-second login grace time
  - Connection rate limiting (MaxStartups: 10:30:60)

- **Session Security:**
  - 5-minute keepalive interval
  - Disconnect idle sessions after 10 minutes
  - X11 forwarding disabled
  - TCP/Agent forwarding disabled
  - Tunnel mode disabled

- **Cryptography:**
  - Modern ciphers only (ChaCha20-Poly1305, AES-GCM, AES-CTR)
  - Strong key exchange (Curve25519, DH-group16/18)
  - Secure MACs (HMAC-SHA2-512/256 with ETM)
  - Modern host keys (ED25519, RSA-SHA2)

- **Logging:**
  - Verbose logging enabled
  - AUTH facility for syslog

### UFW Firewall

- **Default Policies:**
  - Incoming: DENY (whitelist-based)
  - Outgoing: ALLOW
  - Loopback: ALLOW

- **SSH Access:**
  - Configured based on `ssh_allowed_sources` or `ssh_allowed_interfaces`
  - Restricts SSH to specific networks or interfaces
  - Prevents unauthorized network access

- **Connection Tracking:**
  - Established/related connections allowed
  - Stateful firewall rules

### Fail2ban

- **SSH Jail:**
  - Monitors `/var/log/auth.log` for failed login attempts
  - Default: 5 failures in 10 minutes = 1 hour ban
  - Aggressive mode (catches pre-auth failures)
  - Uses UFW for ban actions

- **SSH DDOS Jail:**
  - Protects against connection flooding
  - 10 attempts in 5 minutes = 24 hour ban

- **Whitelisting:**
  - Localhost always whitelisted
  - Optional trusted subnet whitelisting for lab environments

### Login Banners

- **Pre-authentication (`/etc/issue.net`):**
  - Displays before SSH login
  - Short legal warning
  - Discourages unauthorized access

- **Console Login (`/etc/issue`):**
  - Displays at local console
  - Same warning as SSH banner

- **Post-authentication (`/etc/motd`):**
  - Displays after successful login
  - Reminds users of monitoring and policies
  - Shows hostname and classification

## Security Considerations

### Production Deployment Checklist

- [ ] Define `ssh_allowed_sources` or `ssh_allowed_interfaces` (don't allow from anywhere)
- [ ] Set `ssh_permit_root_login: "no"`
- [ ] After key-based auth is set up, set `ssh_password_authentication: "no"`
- [ ] Keep `fail2ban_whitelist_lan: false` in production
- [ ] Customize login banners for your organization
- [ ] Test SSH access before logging out of current session
- [ ] Consider changing SSH port (`ssh_port`) for additional obscurity
- [ ] Document your SSH access policy for the team
- [ ] Keep backup SSH access method (console/BMC/IPMI)

### Defense-in-Depth Strategy

This role implements multiple security layers:

1. **Firewall (UFW)** - First line of defense at network layer
2. **SSH Config** - Application-level hardening with strong crypto
3. **Fail2ban** - Automatic response to brute force attacks
4. **Banners** - Legal deterrence and user notification

Even if one layer is bypassed, others provide protection.

### Compliance Alignment

This role helps meet requirements for:

- **ISO 27001:** Access control, cryptography, logging
- **SOC 2:** Access restrictions, authentication, monitoring
- **CIS Benchmarks:** SSH hardening recommendations
- **PCI DSS:** Strong authentication, encryption, monitoring

## Troubleshooting

### Locked Out of SSH

**Prevention:**

- Always test SSH in a new session before closing your current session
- Keep console/BMC/IPMI access as backup
- In lab environments, use `fail2ban_whitelist_lan: true`

**Recovery:**

1. Access server via console/BMC/IPMI
2. Check UFW rules: `sudo ufw status numbered`
3. Check fail2ban: `sudo fail2ban-client status sshd`
4. Temporarily disable firewall: `sudo ufw disable` (re-enable after testing)
5. Check SSH config: `sudo sshd -t`
6. Review logs: `sudo tail -f /var/log/auth.log`

### SSH Configuration Test Failed

```bash
# Test SSH config syntax
sudo sshd -t

# Check for syntax errors
sudo journalctl -u ssh

# Restore backup if needed
sudo cp /etc/ssh/sshd_config.orig /etc/ssh/sshd_config
sudo systemctl restart ssh
```

### Fail2ban Not Banning

```bash
# Check fail2ban status
sudo fail2ban-client status sshd

# Check fail2ban logs
sudo journalctl -u fail2ban

# Manually test ban
sudo fail2ban-client set sshd banip 192.0.2.1

# Unban IP
sudo fail2ban-client set sshd unbanip 192.0.2.1
```

### UFW Blocking Legitimate Traffic

```bash
# Check UFW rules
sudo ufw status verbose

# Add temporary rule
sudo ufw allow from 192.168.1.100 to any port 22

# Disable UFW temporarily (testing only)
sudo ufw disable

# Re-enable after fixing
sudo ufw enable
```

### Connection Drops After Login

This may be caused by idle timeout settings. Increase keepalive intervals:

```yaml
ssh_client_alive_interval: 600 # 10 minutes
ssh_client_alive_count_max: 3 # 30 minutes total
```

## Files Modified by This Role

| File/Directory             | Purpose                  | Backup Location             |
| -------------------------- | ------------------------ | --------------------------- |
| `/etc/ssh/sshd_config`     | SSH daemon configuration | `/etc/ssh/sshd_config.orig` |
| `/etc/ufw/`                | UFW firewall rules       | Managed by UFW              |
| `/etc/fail2ban/jail.local` | Fail2ban configuration   | None (templated)            |
| `/etc/issue`               | Console login banner     | Overwritten                 |
| `/etc/issue.net`           | SSH pre-auth banner      | Overwritten                 |
| `/etc/motd`                | Post-login message       | Overwritten                 |

## Testing

### Verify SSH Hardening

```bash
# Check SSH configuration
sudo sshd -t

# Verify SSH is listening
sudo ss -tlnp | grep ssh

# Check UFW status
sudo ufw status verbose

# Check fail2ban
sudo fail2ban-client status sshd

# Test SSH connection
ssh -v user@hostname

# Check cryptography being used
ssh -vv user@hostname 2>&1 | grep -i "cipher\|mac\|kex"
```

### Security Audit

```bash
# Check for weak SSH settings
sudo grep -E '(PermitRootLogin yes|PasswordAuthentication yes|PermitEmptyPasswords yes)' /etc/ssh/sshd_config

# Check SSH log for failed attempts
sudo grep "Failed password" /var/log/auth.log | tail -20

# Check fail2ban ban list
sudo fail2ban-client status sshd

# Review firewall rules
sudo ufw status numbered
```

## Resources

- **SSH Hardening Guide:** https://www.ssh.com/academy/ssh/hardening
- **UFW Documentation:** https://help.ubuntu.com/community/UFW
- **Fail2ban Manual:** https://www.fail2ban.org/wiki/index.php/Main_Page
- **CIS Ubuntu Benchmark:** https://www.cisecurity.org/benchmark/ubuntu_linux
- **Mozilla SSH Guidelines:** https://infosec.mozilla.org/guidelines/openssh

## License

This role is provided as-is for use in your infrastructure projects.

## Maintenance

- **Review monthly:** Check for new SSH vulnerabilities and update role accordingly
- **Update fail2ban:** Review banned IPs monthly, adjust thresholds if needed
- **Audit logs:** Regularly review `/var/log/auth.log` for suspicious activity
- **Test backups:** Ensure you can access systems if SSH is locked down
