# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.2] - 2026-04-26

### Fixed

- **wazuh_agent** — `wazuh_custom_localfiles` is now actually consumed by
  `ossec.conf.j2`. The variable was documented in the role README since
  0.0.1 but the template never iterated over it, so any custom localfile
  blocks set by the calling playbook (for example
  `/var/log/headscale/*.log` on the headscale gateway) were silently
  dropped on every reconcile and lost from the agent-reported data.

### Added

- **wazuh_agent** — Default `wazuh_custom_localfiles: []` declared in
  `defaults/main.yml`, with a documented schema covering `location`,
  `log_format`, and the optional `command`, `alias`, and `frequency` keys
  for command-format localfiles. Behavior is unchanged when the variable
  is not set by the consumer.

## [0.0.1] - 2026-04-16

### Added

#### Standalone Roles

- **ssh_hardening** — Defense-in-depth SSH hardening for Ubuntu/Debian systems
  - SSH daemon hardening: port, root login, password auth, max auth tries, grace time,
    session limits, connection rate limiting, keepalives, X11/TCP/agent forwarding controls
  - Modern cryptography: ChaCha20-Poly1305, AES-GCM, Curve25519 key exchange, ED25519 host keys,
    HMAC-SHA2-512/256 with ETM
  - UFW firewall: configurable default policies, source IP/interface allowlists for SSH
  - fail2ban: SSH jail, DDoS jail, configurable ban time/findtime/maxretry, LAN whitelist support
  - Login banners: pre-auth (`/etc/issue.net`), console (`/etc/issue`), post-auth (`/etc/motd`)
    with configurable company name, address, data classification, and security contact
  - Tags: `ssh`, `banner`, `firewall`, `fail2ban`, `sshd`, `verify`

- **wazuh_agent** — Wazuh security monitoring agent for endpoint protection and compliance
  - Package install from official Wazuh repository on Debian and RedHat families (ARM64/AMD64)
  - Manager enrollment via `agent-auth` with optional password and group assignment
  - ossec.conf template: FIM (12h, realtime sync), rootcheck, SCA, syscollector (1h),
    log analysis (syslog, auth.log, dpkg.log, kern.log), active response, client buffer
  - Docker monitoring: `wazuh_docker_monitoring_enabled` enables `docker-listener` wodle;
    role installs `python3-docker` and adds `wazuh` user to `docker` group automatically
  - Remote commands: `wazuh_remote_commands_enabled` controls manager-initiated command acceptance
  - Idempotent enrollment: re-enrolls only when `client.keys` is missing or empty
  - Tags: `wazuh`, `security`, `monitoring`

- **system_updates** — Monthly OS patching and firmware updates with standalone script support
  - APT-based package updates: security patches, upgrades, kernel updates, autoremove
  - Firmware updates via fwupd: UEFI/BIOS, NVMe, Thunderbolt, embedded controller, Intel ME
  - Standalone shell script deployed to `/usr/local/bin/monthly-system-update.sh` with
    `--check-only`, `--no-reboot`, `--help` options and per-run logs under `/var/log/system-updates/`
  - Markdown report generation with before/after firmware inventory and reboot status
  - `system_updates_auto_apply` and `system_updates_auto_reboot` controls
  - Tags: `system-updates`, `setup`, `run`, `report`, `reboot`

- **firmware_updates** — Firmware update management using Linux Vendor Firmware Service (LVFS)
  - fwupd-based updates: UEFI/BIOS, Thunderbolt controllers and docks, USB-C hubs,
    NVMe SSDs, embedded controllers, TPM, network cards
  - Configurable: `firmware_auto_update`, `firmware_force_refresh`, `firmware_assume_yes`,
    `firmware_no_reboot_check`, `firmware_log_dir`
  - Hardware inventory capture before and after updates; reboot requirement detection
  - Tags: `firmware`, `install`, `service`, `check`, `refresh`, `update`, `report`, `reboot`

- **otel_collector** — OpenTelemetry Collector for observability with any OTLP-compatible backend
  - Supports SigNoz, Grafana Cloud, Datadog, New Relic, Honeycomb, and custom OTLP endpoints
  - Host metrics: CPU, memory, disk I/O, network, filesystem, system load
  - Docker metrics and container log collection (optional)
  - Log collection from configurable paths with regex filtering
  - Memory limiting, send queue tuning, gRPC keepalive configuration
  - Architecture support: x86_64 and aarch64
  - Binary at `/usr/local/bin/otelcol-contrib`, config at `/etc/otel-collector/config.yml`
  - Tags: `otel`, `monitoring`, `install`

#### Service Collections

- **headscale** — Self-hosted VPN mesh network (Tailscale-compatible) deployed via Docker Compose
  - Roles: `prerequisites`, `docker`, `system_config`, `headscale`, `management`, `backup`
  - Configurable: version pinning, IPv4/IPv6 prefixes, DNS servers, magic DNS domain,
    DERP relay, Prometheus metrics endpoint, pre-auth key generation
  - Automated backups: configurable cron schedule and local retention
  - Playbooks: `headscale-install.yml`, `headscale-update.yml`, `headscale-backup.yml`,
    `headscale-reset.yml`, `headscale-status.yml`, `generate-key.yml`, `wazuh-install.yml`

- **authentik** — Complete open-source identity provider with SSO, MFA, and Linux endpoint integration
  - 18 numbered roles executed in dependency order:
    `01_groups`, `02_users`, `03_security`, `04_ldap`, `05_oidc`, `06_google_oauth`,
    `07_proxy`, `08_launchers`, `09_scim_defaults`, `10_saml`, `11_branding`,
    `12_notifications`, `13_aws_scim`, `14_password_auth`, `15_ssh_password_flow`,
    `16_conditional_mfa`, `17_endpoint_agent`, `18_endpoint_pam_exec`
  - Protocol support: LDAP, OIDC, SAML, OAuth2 (Google), reverse proxy
  - Linux endpoint integration: NSS (passwd/group/shadow), SSH authorized_keys provisioning,
    sudo group assignment, PAM exec wrapper with local auth fallback
  - SCIM provisioning with AWS integration
  - Conditional MFA policies, custom branding, notification channels
  - Playbooks: `configure-all.yml`, `configure-groups.yml`, `configure-oidc.yml`,
    `configure-ldap.yml`, `configure-google-oauth.yml`, `configure-security.yml`,
    `configure-ssh-endpoints.yml`, `configure.yml`

#### Example Playbooks

- `01-base-security.yml` — Wazuh agent deployment
- `02-system-updates.yml` — OS patching and firmware updates
- `03-monitoring.yml` — OpenTelemetry collector deployment
- `04-vpn-mesh.yml` — Headscale VPN mesh deployment
- `05-identity.yml` — Authentik identity provider configuration
- `06-ssh-hardening.yml` — SSH hardening with Authentik endpoint agent
- `99-full-stack.yml` — Full infrastructure stack (orchestrates 01–06)

#### CI/CD and Tooling

- GitHub Actions: `lint.yml` (yamllint, ansible-lint, syntax check),
  `pr-checks.yml` (conventional commit titles, CHANGELOG check, per-role lint,
  playbook validation, doc link checking), `security.yml` (Gitleaks secret detection,
  vault file scanning, Python dependency auditing, weekly schedule),
  `markdown-format.yml` (Prettier), `release.yml` (GitHub Release on numeric tags)
- Makefile targets: `install`, `lint`, `lint-yaml`, `lint-ansible`, `validate`, `test`,
  `fmt`, `fmt-check`, `clean`, `release`
- Scripts: `install-requirements.sh`, `lint-all.sh`, `validate-playbooks.sh`
- Documentation: `QUICK_START.md`, `ROLES.md`, `COLLECTIONS.md`, `PLAYBOOKS.md`,
  `ARCHITECTURE.md`, `TROUBLESHOOTING.md`, `ADDING_TOOLS.md`

[0.0.1]: https://github.com/zsoftly/zti-config/releases/tag/0.0.1
