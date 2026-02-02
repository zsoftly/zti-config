# WireGuard to Headscale Migration Plan

Migration from WireGuard VPN to Headscale with rollback procedures.

## Current State

| Component  | WireGuard       | Headscale            |
| ---------- | --------------- | -------------------- |
| Private IP | 10.0.10.10      | 10.0.10.11           |
| Public IP  | 198.51.100.2    | 198.51.100.1         |
| VPN CIDR   | 10.250.0.0/23   | 100.64.0.0/10        |
| Domain     | vpn.example.com | vpn.example.com      |
| Status     | Active (legacy) | Ready for production |

## Pre-Migration Checklist

- [ ] All Headscale fixes applied (VPN route, SG, iptables)
- [ ] Terraform applied for network layer (`01_net`)
- [ ] Terraform applied for server layer (`03_srv`)
- [ ] Ansible playbook run successfully
- [ ] At least one test client connected and verified
- [ ] VPC resource access tested from Headscale client

## Migration Steps

### Phase 1: Enable Headscale VPC Routing (No Disruption)

```bash
# 1. Apply Terraform network changes (SG rules)
cd terraform/03_compute/01_headscale/01_net
terraform plan
terraform apply

# 2. Apply Terraform server changes (VPN route)
cd ../03_srv
terraform plan
terraform apply

# 3. Run Ansible to update iptables
cd ansible/headscale
export HEADSCALE_ANSIBLE_VAULT_PASS="your-vault-password"
ansible-playbook playbooks/headscale-install.yml \
  --vault-password-file <(echo "$HEADSCALE_ANSIBLE_VAULT_PASS")
```

### Phase 2: Test Headscale VPC Access

```bash
# From a Headscale-connected client:

# Test DNS resolution
nslookup jenkins.sbx.example.com

# Test private subnet access (Jenkins on 10.0.10.100)
ping 10.0.10.100
ssh ec2-user@10.0.10.100

# Test other private resources
curl http://10.0.10.100:8080  # Jenkins web UI
```

### Phase 3: Migrate Clients

| Step | Action                                      | Rollback                   |
| ---- | ------------------------------------------- | -------------------------- |
| 1    | Notify users of migration window            | N/A                        |
| 2    | Migrate 1-2 pilot users first               | Revert to WireGuard config |
| 3    | Verify pilot users can access all resources | Check SG/routing           |
| 4    | Migrate remaining users in batches          | Per-user rollback          |
| 5    | Monitor for 24-48 hours                     | Full rollback if needed    |

**Client migration command:**

```bash
# Disconnect from WireGuard first
wg-quick down wg0

# Connect to Headscale with split tunneling (accept advertised routes)
tailscale up --login-server https://vpn.example.com --accept-routes
```

**IMPORTANT**: The `--accept-routes` flag is required for split tunneling.
Without it, clients won't receive the VPC and Cloudflare routes.

### Phase 4: Disable WireGuard (After Validation)

```bash
# 1. Remove VPN route from private route tables
cd terraform/03_compute/02_vpn/cac1
# Edit to disable route or destroy

# 2. Stop WireGuard service (keep instance for rollback)
# SSH to WireGuard server:
sudo systemctl stop wg-quick@wg0
sudo systemctl disable wg-quick@wg0

# 3. Update DNS (optional - point old domain to Headscale)
# vpn.example.com → 198.51.100.1
```

### Phase 5: Cleanup (After 2-Week Validation)

```bash
# Only after confirming no rollback needed:

# 1. Destroy WireGuard infrastructure
cd terraform/03_compute/02_vpn/cac1
terraform destroy

# 2. Release WireGuard EIP
# (handled by terraform destroy)

# 3. Remove WireGuard Ansible code (optional - keep for reference)
# mv ansible/wireguard ansible/wireguard.deprecated
```

## Rollback Procedures

### Rollback Level 1: Single Client

If one client has issues:

```bash
# On the client:
tailscale down
wg-quick up wg0
```

### Rollback Level 2: Headscale Routing Issue

If Headscale clients can't reach VPC:

```bash
# 1. Check route table
aws ec2 describe-route-tables --filters "Name=tag:Name,Values=*private*"

# 2. Verify route exists for 100.64.0.0/10 → Headscale ENI

# 3. Check security group
aws ec2 describe-security-groups --group-ids sg-xxx

# 4. Check iptables on Headscale server
sudo iptables -t nat -L -n -v
sudo iptables -L FORWARD -n -v
```

### Rollback Level 3: Full Rollback to WireGuard

If Headscale is fundamentally broken:

```bash
# 1. Re-enable WireGuard service
ssh wireguard-server
sudo systemctl start wg-quick@wg0

# 2. Notify users to switch back
# Client command:
tailscale down
wg-quick up wg0

# 3. Disable Headscale VPN route (optional)
cd terraform/03_compute/01_headscale/03_srv
# Set enable_vpn_route = false
terraform apply
```

### Rollback Level 4: DNS Failover

If using shared domain and need instant failover:

```bash
# Update Cloudflare DNS to point to WireGuard
cd terraform/05_cloudflare/ec2/sbx
# Change headscale IP to wireguard IP
terraform apply

# TTL is 300s, so propagation takes ~5 minutes
```

## Validation Checklist

### After Phase 1 (Terraform/Ansible)

- [ ] Route table has 100.64.0.0/10 → Headscale ENI
- [ ] Security group allows all protocols from VPC
- [ ] iptables shows selective masquerade rule
- [ ] iptables shows FORWARD rule for tailscale0

### After Phase 2 (Testing)

- [ ] Headscale client gets VPN IP (100.64.x.x)
- [ ] Client can ping Headscale server (100.64.0.1)
- [ ] Client can ping VPC DNS (10.0.0.2)
- [ ] Client can reach private subnet resources
- [ ] Client can access internet via VPN

### After Phase 3 (Client Migration)

- [ ] All users connected to Headscale
- [ ] No complaints about connectivity
- [ ] Monitoring shows healthy connections
- [ ] Backup/OTEL metrics flowing

### After Phase 4 (WireGuard Disabled)

- [ ] WireGuard service stopped
- [ ] No active WireGuard connections
- [ ] WireGuard route removed from route table

## Timing Recommendations

| Phase   | Duration  | Window                       |
| ------- | --------- | ---------------------------- |
| Phase 1 | 30 min    | Any time                     |
| Phase 2 | 1 hour    | Business hours (for testing) |
| Phase 3 | 2-4 hours | Low-traffic period           |
| Phase 4 | 15 min    | After 24-48h validation      |
| Phase 5 | 15 min    | After 2 weeks                |

## Emergency Contacts

- Infrastructure Team: #platform-team (Slack)
- On-call: Check PagerDuty rotation
