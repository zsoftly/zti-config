# Wazuh Agent Role

Shared Ansible role for installing and configuring the Wazuh agent on Linux systems. Agents connect to Wazuh manager and send security events, logs, system inventory, and (optionally) Docker events.

The rendered `ossec.conf` enables the full Wazuh XDR module set by default: File Integrity Monitoring, rootkit detection, Security Configuration Assessment (SCA), system inventory (syscollector), log collection, and Active Response. Docker monitoring is opt-in via `wazuh_docker_monitoring_enabled`.

## Requirements

- Linux (Ubuntu/Debian/RHEL/CentOS/Fedora/Amazon Linux)
- Architecture: ARM64 (aarch64) or AMD64 (x86_64)
- Network access to Wazuh manager (ports 1514, 1515 via Traefik NLB)
- Root/sudo privileges

## Supported Platforms

| OS Family | Distributions                      | Architectures |
| --------- | ---------------------------------- | ------------- |
| Debian    | Ubuntu, Debian                     | ARM64, AMD64  |
| RedHat    | RHEL, CentOS, Fedora, Amazon Linux | ARM64, AMD64  |

## Role Variables

### Required

None - defaults work for standard deployments.

### Optional

```yaml
# Wazuh manager connection (defaults to sbx via Traefik NLB)
wazuh_manager_address: "wazuh.example.com"
wazuh_manager_port: 1514
wazuh_manager_enrollment_port: 1515

# Agent identification
wazuh_agent_name: "{{ inventory_hostname }}" # Uses hostname by default

# Agent version
wazuh_agent_version: "4.14.1-1"

# Agent behavior
wazuh_agent_notify_time: 10 # Time between agent checks (seconds)
wazuh_agent_time_reconnect: 60 # Time before reconnection attempts (seconds)

# Capabilities (enable/disable features)
wazuh_sca_enabled: true # Security Configuration Assessment
wazuh_syscollector_enabled: true # System inventory collection
wazuh_rootcheck_enabled: true # Rootkit detection
wazuh_vulnerability_detection_enabled: true # Vulnerability scanning
wazuh_openscap_enabled: false # OpenSCAP (requires extra setup)

# Custom application logs
wazuh_custom_localfiles:
  - location: "/var/log/myapp/*.log"
    log_format: "syslog"

# Service management
wazuh_agent_service_state: "started"
wazuh_agent_service_enabled: true

# Remote commands (default: disabled for security)
wazuh_remote_commands_enabled: false # Allow manager to run commands on agent

# Docker monitoring (docker-listener wodle). Enable on hosts running Docker. Requires python3-docker and the `wazuh` user in the `docker` group — both handled by the invoking playbook.
wazuh_docker_monitoring_enabled: false
```

## Usage

### Include in Playbook

```yaml
- name: Install Wazuh Agent
  hosts: all
  become: true

  roles:
    - role: wazuh_agent
```

### Include with Custom Variables

```yaml
- name: Install Wazuh Agent with custom config
  hosts: webservers
  become: true

  vars:
    wazuh_custom_localfiles:
      - location: "/var/log/nginx/access.log"
        log_format: "syslog"
      - location: "/var/log/nginx/error.log"
        log_format: "syslog"

  roles:
    - role: wazuh_agent
```

### Include with Tags

```yaml
post_tasks:
  - name: Install Wazuh Agent
    when: wazuh_agent_enabled | default(false)
    ansible.builtin.include_role:
      name: wazuh_agent
      apply:
        tags: [wazuh, security]
    tags: [wazuh, security, always]
```

## What's Monitored

### File Integrity Monitoring (FIM)

Scan every 12h (`frequency=43200`), scan on start, realtime sync every 5m.

| Path        | Description           |
| ----------- | --------------------- |
| `/etc`      | System configuration  |
| `/usr/bin`  | User binaries         |
| `/usr/sbin` | System binaries       |
| `/bin`      | Essential binaries    |
| `/sbin`     | System admin binaries |
| `/boot`     | Boot files            |

Exclusions: `/etc/mtab`, `/etc/hosts.deny`, `/etc/mail/statistics`, `/etc/random-seed`, `/etc/random.seed`, `/etc/adjtime`, `/etc/prelink.cache`, and any path matching `.log$|.swp$`. NFS, `/dev`, `/proc`, `/sys` are skipped.

### Log Analysis

**Ubuntu/Debian:**

- `/var/log/syslog` - System logs
- `/var/log/auth.log` - Authentication logs
- `/var/log/dpkg.log` - Package management
- `/var/log/kern.log` - Kernel logs

**RHEL/CentOS/Fedora:**

- `/var/log/messages` - System logs
- `/var/log/secure` - Authentication logs
- `/var/log/audit/audit.log` - Audit logs

### System Inventory (syscollector)

Scan every 1h, scan on start.

- Hardware information
- Operating system details
- Network interfaces and configuration
- Installed packages
- Running processes
- Open ports (listening only)

### Security Assessment

- Rootkit detection (rootcheck) — scan every 12h, checks files, trojans, /dev, /sys, running PIDs, open ports, network interfaces
- Security Configuration Assessment (SCA) — CIS benchmarks, scan every 12h
- Vulnerability detection — driven by manager-side CVE feed

### Docker Monitoring (optional)

Enable with `wazuh_docker_monitoring_enabled: true`. Uses the Wazuh `docker-listener` wodle to subscribe to the Docker daemon event stream.

Captured events: container create/start/stop/kill/die, image pull/delete, exec_create/exec_start (shells opened in running containers), volume mount/unmount, network create/connect/disconnect.

### Active Response

Enabled by default. Allows the manager to trigger response commands (e.g. `firewall-drop`, `disable-account`, `restart-wazuh`) on the agent when matching rules fire.

### Client Buffer

- Queue size: 5000 events
- Rate limit: 500 events/sec

Prevents the agent from overwhelming the manager during log bursts; overflow is queued locally and drained when the manager catches up.

## How It Works

### 1. Agent Enrollment (One-Time)

```mermaid
sequenceDiagram
    participant A as Wazuh Agent
    participant T as Traefik NLB
    participant M as Wazuh Manager

    A->>T: Enroll via agent-auth (port 1515)
    T->>M: Forward enrollment request
    M->>M: Generate agent key
    M-->>T: Return agent key
    T-->>A: Return agent key
    A->>A: Store key in /var/ossec/etc/client.keys
    Note over A: Agent is now registered
```

### 2. Event Forwarding (Continuous)

```mermaid
sequenceDiagram
    participant L as System Logs
    participant A as Wazuh Agent
    participant T as Traefik NLB
    participant M as Wazuh Manager

    loop Every 10 seconds
        L->>A: Monitor logs & system events
        A->>A: Analyze & correlate events
        A->>T: Send events (port 1514, encrypted)
        T->>M: Forward events
        M->>M: Process & store in dashboard
    end
```

**Key Points:**

- Enrollment happens once, stores key in `/var/ossec/etc/client.keys`
- All traffic routed through Traefik NLB at `wazuh.example.com`
- Communication encrypted with AES using agent key
- Agent sends heartbeat every 10 seconds (configurable)

## Troubleshooting

### Check Agent Status

```bash
systemctl status wazuh-agent
```

### View Agent Logs

```bash
# Real-time logs
tail -f /var/ossec/logs/ossec.log

# Agent connection status
grep -i "connected to" /var/ossec/logs/ossec.log

# Enrollment status
cat /var/ossec/etc/client.keys
```

### Test Connection to Manager

```bash
# Test connectivity to manager
telnet wazuh.example.com 1514
telnet wazuh.example.com 1515

# Check agent connection status in logs
grep -i "connected to" /var/ossec/logs/ossec.log | tail -5
```

### Manual Re-enrollment

```bash
# Stop agent
systemctl stop wazuh-agent

# Remove old key
rm /var/ossec/etc/client.keys

# Re-enroll (run as root)
/var/ossec/bin/agent-auth -m wazuh.example.com -p 1515

# Start agent
systemctl start wazuh-agent
```

### Common Issues

**Agent can't connect to manager:**

- Check security group allows ports 1514/1515 from agent's IP/VPC
- Verify DNS resolution: `dig wazuh.example.com`
- Check NLB health: Traefik pods must be healthy

**Agent not appearing in dashboard:**

- Wait 1-2 minutes after enrollment
- Check `/var/ossec/etc/client.keys` exists and has content
- Verify agent service is running: `systemctl status wazuh-agent`
- Check logs for errors: `tail -f /var/ossec/logs/ossec.log`

**Permission denied on log files:**

- Agent runs as `wazuh` user
- Ensure wazuh user can read monitored logs: `ls -l /var/log/auth.log`
- Add wazuh user to appropriate group (usually `adm` for logs)

## Files

| Path                           | Description          |
| ------------------------------ | -------------------- |
| `/var/ossec/bin/wazuh-control` | Agent control script |
| `/var/ossec/etc/ossec.conf`    | Agent configuration  |
| `/var/ossec/etc/client.keys`   | Agent enrollment key |
| `/var/ossec/logs/ossec.log`    | Agent logs           |
| `/var/ossec/queue/`            | Event queue          |

## Security

- Agent communication is encrypted with AES
- Manager validates agent identity via pre-shared keys
- File integrity monitoring detects unauthorized changes
- Rootkit detection identifies malicious software
- Vulnerability scanning identifies outdated packages

## Version History

| Version | Notes                                          |
| ------- | ---------------------------------------------- |
| 4.14.1  | Current stable release                         |
| 4.14.0  | Improved SCA policies, vulnerability detection |
| 4.13.x  | Enhanced cloud security monitoring             |

## Manual Installation (Windows/macOS)

For Windows and macOS endpoints, see the
[Wazuh documentation](https://documentation.wazuh.com/current/installation-guide/wazuh-agent/index.html).
