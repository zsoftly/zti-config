# OpenTelemetry Collector Role

Shared Ansible role for installing the OpenTelemetry Collector on EC2 instances.
Sends metrics and logs to any OTLP-compatible backend via gRPC.

## Supported Backends

This role works with any OpenTelemetry-compatible observability platform:

- **SigNoz** - Open-source APM and observability
- **Grafana Cloud** - Managed Prometheus, Loki, Tempo
- **Datadog** - Commercial APM and monitoring
- **New Relic** - Application performance monitoring
- **Honeycomb** - Observability for distributed systems
- **Any OTLP endpoint** - Standard OpenTelemetry Protocol

## Requirements

- Linux (Ubuntu/Debian/RHEL/Fedora)
- ARM64 or AMD64 architecture
- Network access to OTLP endpoint (typically port 4317 for gRPC)

## Role Variables

### Required

```yaml
otel_endpoint: "otel-backend.example.com:4317" # OTLP gRPC endpoint (host:port)
```

### Optional

```yaml
# TLS settings
otel_insecure: true # Set false if using TLS

# Service identification (displayed in observability backend UI)
otel_service_name: "{{ inventory_hostname }}"
otel_service_environment: "sbx"

# Collector version
otel_collector_version: "0.142.0"

# Collection interval
otel_metrics_interval: "60s"

# Enable/disable collectors
otel_logs_enabled: true
otel_docker_metrics: true

# Host metrics to collect
otel_host_metrics:
  cpu: true
  memory: true
  disk: true
  network: true
  filesystem: true
  load: true

# Log paths to collect
otel_log_paths:
  - "/var/log/syslog"
  - "/var/log/auth.log"
```

## Usage

### Include in Playbook

```yaml
- name: Install OTEL Collector
  hosts: all
  become: true

  vars:
    otel_endpoint: "otel-backend.example.com:4317"
    otel_service_name: "my-service"
    otel_service_environment: "sbx"

  roles:
    - role: otel_collector
```

### Include with Tags

```yaml
post_tasks:
  - name: Install OpenTelemetry Collector
    when: otel_enabled | default(false)
    ansible.builtin.include_role:
      name: otel_collector
      apply:
        tags: [otel, monitoring]
    tags: [otel, monitoring, always]
```

## What's Collected

### Host Metrics (hostmetrics receiver)

| Metric                      | Description             |
| --------------------------- | ----------------------- |
| `system.cpu.utilization`    | CPU usage percentage    |
| `system.memory.utilization` | Memory usage percentage |
| `system.disk.*`             | Disk I/O operations     |
| `system.filesystem.*`       | Filesystem usage        |
| `system.network.*`          | Network bytes/packets   |
| `system.load.*`             | System load averages    |

### Docker Metrics (docker_stats receiver)

Requires `otel_docker_metrics: true` and Docker installed.

| Metric                         | Description            |
| ------------------------------ | ---------------------- |
| `container.cpu.usage.total`    | Container CPU usage    |
| `container.memory.usage.total` | Container memory usage |
| `container.network.io.usage.*` | Container network I/O  |
| `container.blockio.*`          | Container disk I/O     |

### Logs (filelog receiver)

Collects raw log lines from configured paths. Default:

- `/var/log/syslog`
- `/var/log/auth.log`

## Troubleshooting

### Check Status

```bash
systemctl status otel-collector
```

### View Logs

```bash
journalctl -u otel-collector -f
```

### Check Metrics

```bash
# Collector internal metrics
curl -s localhost:8888/metrics | grep otelcol

# Check receivers are working
curl -s localhost:8888/metrics | grep otelcol_receiver_accepted
```

### Common Issues

**Connection refused to OTEL endpoint:**

- Check security group allows port 4317 from this instance
- Verify endpoint is correct (include port)
- Check `otel_insecure` matches your TLS config

**Docker metrics not collected:**

- Ensure `otel_docker_metrics: true`
- Check otel-collector user is in docker group: `groups otel-collector`
- Restart collector after Docker group change

**Logs not collected:**

- Check otel-collector user is in adm group: `groups otel-collector`
- Verify log paths exist and are readable

## Files

| Path                                         | Description             |
| -------------------------------------------- | ----------------------- |
| `/usr/local/bin/otelcol-contrib`             | Collector binary        |
| `/etc/otel-collector/config.yml`             | Collector configuration |
| `/var/lib/otel-collector/`                   | Collector state         |
| `/etc/systemd/system/otel-collector.service` | Systemd service         |

## Version History

| Version | Notes                                  |
| ------- | -------------------------------------- |
| 0.142.0 | Docker API 1.44 default, latest stable |
| 0.116.0 | Previous version, API 1.25 default     |
