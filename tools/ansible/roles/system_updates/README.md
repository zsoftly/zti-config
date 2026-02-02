# System Updates Role

Ansible role for monthly OS patching and firmware updates on lab laptops.
Deploys a standalone script that can run with or without Ansible.

## Purpose

- **OS Patching:** Apply security updates and package upgrades
- **Firmware Updates:** Update UEFI/BIOS, SSD, Intel ME, etc.
- **Dual-Use:** Script works standalone or via Ansible
- **Emergency Access:** Can run updates manually when Ansible isn't available

## How It Works

This role deploys a shell script to `/usr/local/bin/monthly-system-update.sh`
that:

1. Updates OS packages (apt update, apt upgrade)
2. Removes unnecessary packages (apt autoremove)
3. Checks for firmware updates (fwupd)
4. Applies firmware updates if available
5. Generates detailed reports
6. Optionally reboots (with countdown)

**The script can be run in two ways:**

### Option 1: Via Ansible (Recommended)

```bash
ansible-playbook playbooks/system-update-full.yml --tags system-updates \
  --ask-pass --ask-become-pass
```

- Ansible deploys latest script version
- Runs script on all hosts
- Collects reports centrally
- Handles reboot orchestration
- Updates are logged in Ansible output

### Option 2: Manual Execution (Fallback)

```bash
# SSH to the host
ssh example-lab-01

# Run the script directly (no Ansible needed)
sudo /usr/local/bin/monthly-system-update.sh

# Options available:
sudo /usr/local/bin/monthly-system-update.sh --check-only   # Dry run
sudo /usr/local/bin/monthly-system-update.sh --no-reboot   # Skip reboot
sudo /usr/local/bin/monthly-system-update.sh --help        # Show help
```

**When to use manual execution:**

- Ansible is unavailable
- Emergency patching needed
- Testing updates on single host
- Network/VPN issues prevent Ansible access

## Requirements

- Ubuntu/Debian-based Linux
- Root/sudo privileges
- Internet connection (for package repos and LVFS)
- **IMPORTANT: Laptop lids must be OPEN for firmware updates**

## Usage

### Include in Playbook

```yaml
- name: Monthly System Updates
  hosts: lab
  become: true

  roles:
    - role: system_updates
```

### Run Monthly Update Playbook

**Complete workflow (recommended):**

```bash
# Setup
source .venv/bin/activate

# Run complete workflow (OS + firmware + reboot + verify)
ansible-playbook playbooks/system-update-full.yml --tags system-updates-full \
  --ask-pass --ask-become-pass

# Options
--tags system-updates-check    # Check for updates only
--tags system-updates-apply    # Apply updates only
--tags system-updates-reboot   # Reboot and verify only
--limit <hostname>             # Single host
-e use_lan_fallback=true       # LAN fallback (when VPN is down)
```

**Check-only mode:**

```bash
# Preview what updates are available (no changes made)
ansible-playbook playbooks/system-update-full.yml --check --diff \
  --ask-pass --ask-become-pass
```

## What Gets Updated

### OS Packages

- Security updates
- Package upgrades (stable releases only)
- Kernel updates (if available)
- System libraries
- Installed applications

**Sources:**

- Ubuntu/Debian official repositories
- Configured PPAs (if any)

### Firmware Updates

- **UEFI/BIOS** - System firmware (Lenovo, Dell, HP, etc.)
- **Intel ME** - Management Engine firmware
- **NVMe SSDs** - Storage controller firmware
- **Thunderbolt** - Controllers and docks
- **USB-C** - Hubs and docking stations
- **Embedded Controllers** - Laptop EC firmware

**Source:**

- LVFS (Linux Vendor Firmware Service)

## Reports Generated

### Ansible Report

When run via Ansible, output includes:

```
example-lab-01: OS=Updated Firmware=Updated Reboot=Required Report=/var/log/system-updates/...
```

### On-Server Report

Every run generates a detailed markdown report:

```bash
# Location
/var/log/system-updates/<timestamp>-<hostname>-report.md

# Contents
- Summary table (OS/firmware updates)
- List of packages updated
- Firmware device list
- Reboot status
- Next steps
```

### Logs

Full execution logs saved to:

```
/var/log/system-updates/<timestamp>-<hostname>.log
```

## Manual Script Usage Examples

```bash
# Check what updates are available (dry run)
sudo /usr/local/bin/monthly-system-update.sh --check-only

# Apply updates but don't reboot
sudo /usr/local/bin/monthly-system-update.sh --no-reboot

# Apply updates and auto-reboot after 60 seconds
sudo /usr/local/bin/monthly-system-update.sh

# View help
sudo /usr/local/bin/monthly-system-update.sh --help
```

## Reboot Behavior

**Ansible Mode:**

- Never auto-reboots (use dedicated reboot playbook)
- Sets `system_updates_reboot_needed` fact

**Manual Mode:**

- Auto-reboots after 60-second countdown (unless `--no-reboot`)
- Can be cancelled with Ctrl+C during countdown

## Monthly Process

### 1. Assign Monthly Owner

Rotate ownership each month (see
[SYSTEM_UPDATE_LOG.md](../../eks-anywhere-lab/docs/SYSTEM_UPDATE_LOG.md))

### 2. Run Updates (First Week of Month)

**Via Ansible (recommended):**

```bash
ansible-playbook playbooks/system-update-full.yml --tags system-updates-full \
  --ask-pass --ask-become-pass
```

**Via Manual Script (fallback):**

```bash
# On each host
ssh example-lab-01
sudo /usr/local/bin/monthly-system-update.sh
```

### 3. Review Reports

```bash
# Via Ansible - check playbook output

# Via Manual - view report on server
ls -lt /var/log/system-updates/ | head -5
cat /var/log/system-updates/<latest-report>.md
```

### 4. Reboot if Required

```bash
# Via Ansible playbook
ansible-playbook playbooks/system-update-verify-reboot.yml

# Via Manual
sudo reboot
```

### 5. Verify After Reboot

```bash
# Check OS packages
apt list --upgradable

# Check firmware
fwupdmgr get-devices
```

### 6. Update Log

Update `docs/SYSTEM_UPDATE_LOG.md` with:

- Date of update
- Your name
- Updates applied
- Any issues

## Troubleshooting

### Script Not Found

```bash
# Redeploy script via Ansible
ansible-playbook playbooks/system-update-full.yml --tags system-updates,setup
```

### Permission Denied

```bash
# Fix permissions
sudo chmod +x /usr/local/bin/monthly-system-update.sh
```

### Updates Failed - Device Busy (Firmware)

1. Close all applications
2. Retry: `sudo /usr/local/bin/monthly-system-update.sh`

### Updates Failed - Lid Closed (Firmware)

**Most common firmware update issue**

1. Physically open laptop lids in lab
2. Retry: `sudo /usr/local/bin/monthly-system-update.sh`

### Held Packages (OS)

Some packages may be held back:

```bash
# Check held packages
apt-mark showhold

# Manually upgrade if safe
sudo apt-get install <package-name>
```

## Security

- **OS Updates:** Signed by package maintainers
- **Firmware Updates:** Cryptographically signed by vendors via LVFS
- **Script:** Managed by Ansible, version controlled
- **Logs:** Readable only by root

## Migration from firmware_updates Role

This role replaces the old `firmware_updates` role with expanded functionality:

**Backward compatibility:**

- `/var/log/firmware-updates/` symlinked to `/var/log/system-updates/`
- Old playbooks continue to work
- Same tag structure maintained

**New features:**

- OS patching included
- Standalone script deployment
- Manual execution capability
- Combined reports

## Files and Directories

| Path                                      | Description               |
| ----------------------------------------- | ------------------------- |
| `/usr/local/bin/monthly-system-update.sh` | Standalone update script  |
| `/var/log/system-updates/`                | Update reports and logs   |
| `/var/log/firmware-updates/`              | Symlink to system-updates |
| `/var/run/reboot-required`                | OS reboot flag            |
| `/var/lib/fwupd/pending.db`               | Pending firmware updates  |

## Resources

- **Ansible Role:** [system_updates](../system_updates/README.md)
- **Playbooks:**
  [playbooks/system-update-\*.yml](../../eks-anywhere-lab/playbooks/)
- **fwupd Documentation:** https://fwupd.org/
- **Ubuntu Security Updates:** https://ubuntu.com/security/notices
