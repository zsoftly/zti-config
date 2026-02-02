# Headscale Zero-Trust Implementation Post-Mortem

**Date:** 2026-01-11 **Duration:** ~4 hours **Outcome:** Successful, with
lessons learned

## Summary

Implemented zero-trust network segmentation for Headscale VPN. Multiple issues
were encountered due to making changes without proper planning and testing in
isolation.

## Issues Encountered

### 1. Split DNS Causing DERP Bootstrap Failure

**Symptom:** Windows client connected but showed `tx 4368 rx 0` - sending
packets but not receiving any.

**Root Cause:** Split DNS for `aws.example.com` routed the VPN server hostname
(`vpn.example.com`) through VPC DNS (`10.0.0.2`). But the VPN tunnel wasn't up
yet, so DNS failed - chicken and egg problem.

**Fix:** Disabled split DNS entirely. Services behind Cloudflare resolve
publicly via global DNS with Cloudflare fallback.

**Lesson:** VPN server domain must always be resolvable via public DNS before
the tunnel is established.

---

### 2. Noise Handshake Failure After Database Reset

**Symptom:**
`noise upgrade failed: chacha20poly1305: message authentication failed`

**Root Cause:** Server database was reset (Docker volumes deleted) but client
had cached keys from previous registration.

**Fix:** Delete stale node from headscale, re-register client with `--reset`
flag to force new key generation.

**Lesson:** Always document that clients must re-register after a database
reset. Consider adding a migration playbook.

---

### 3. Legacy Preauth Key Creation Useless with Zero-Trust

**Symptom:** Ansible playbook displayed a generic preauth key, but devices
registered with it had no access to anything.

**Root Cause:** Zero-trust model means devices without role tags have no ACL
permissions. A generic key without tags is useless.

**Fix:** Removed legacy preauth key creation from playbook. Added
`generate-key.yml` for role-based key generation with proper tags.

**Lesson:** Plan the access model before implementation. Don't leave legacy code
that contradicts the new design.

---

### 4. default_user_id Undefined Error

**Symptom:** Ansible playbook failed with `'default_user_id' is undefined`.

**Root Cause:** The variable was only set when the user already existed, but
subsequent tasks used it unconditionally.

**Fix:** Added `default_user_id is defined` condition to all dependent tasks.

**Lesson:** Test playbooks on fresh instances, not just existing ones. Edge
cases appear when state is clean.

---

### 5. Wazuh Agent Enrollment Skipped

**Symptom:** Agent kept retrying enrollment with "No authentication password
provided".

**Root Cause:** The `client.keys` file existed but was empty (0 bytes). The
Ansible condition checked file existence, not content, so enrollment was
skipped.

**Fix:** Changed condition from `not exists` to `not exists OR size == 0`.

**Lesson:** Check file content, not just existence. Empty files are a common
edge case.

---

### 6. VPC DNS Doesn't Respond to Ping

**Symptom:** `ping 10.0.0.2` times out, leading to belief that VPN routing was
broken.

**Root Cause:** AWS VPC DNS resolver only responds to DNS queries on port 53,
not ICMP ping.

**Fix:** Updated documentation to use `dig @10.0.0.2 google.com` for
verification instead of ping.

**Lesson:** Document expected behaviors, especially infrastructure quirks. Use
correct verification methods.

---

### 7. Headplane API Key Invalidated After Database Reset

**Symptom:** Headplane admin UI showed "The provided API key for OIDC
authentication is invalid."

**Root Cause:** When the headscale database was reset (Docker volumes deleted),
all API keys were deleted. The API key stored in the Ansible vault was from the
old database.

**Fix:**

1. Generate new API key:
   `docker compose exec headscale headscale apikeys create --expiration 999d`
2. Update `vault_headplane_api_key` in vault
3. Redeploy with `-t config` to update headplane config and restart

**Lesson:** Database reset invalidates ALL keys (preauth keys, API keys, client
keys). Document all secrets that need regeneration after reset.

---

## What Went Wrong

| Issue                     | Root Cause                                         |
| ------------------------- | -------------------------------------------------- |
| Multiple debugging cycles | Changes tested directly in sandbox without staging |
| Key mismatch errors       | Database reset without coordinating client cleanup |
| DNS bootstrap failure     | Split DNS not tested with VPN down                 |
| Wrong verification        | Assumptions about AWS behavior (VPC DNS ping)      |
| Admin UI broken           | API key invalidated but vault not updated          |

## Timeline

1. Started zero-trust implementation
2. Removed legacy preauth key code
3. Fixed `default_user_id` undefined error
4. Deployed to sandbox
5. Client connection failed - noise handshake error
6. Deleted node, re-registered - connection established
7. Routes not working - DERP relay issue discovered
8. Split DNS identified as cause
9. Disabled split DNS - connection working
10. Verified access to Cloudflare apps - working
11. Verified VPC DNS - ping failed, dig worked
12. Headplane admin UI broken - API key regenerated
13. Updated documentation

## Recommendations

### Before Implementation

1. **Use Claude Code plan mode** - Design changes before executing
2. **List dependencies** - What needs to work before the feature is enabled?
3. **Identify verification methods** - How will you test each component?

### During Implementation

4. **Test on fresh instances** - Don't assume existing state is valid
5. **Check file content, not just existence** - Empty files are common
6. **Document as you go** - Update docs with each discovery

### After Implementation

7. **Verify the verification** - Ensure test methods are correct for the
   infrastructure
8. **Write post-mortem** - Capture lessons for future reference

## Prevention Checklist

For future VPN/networking changes:

- [ ] VPN server domain resolvable via public DNS?
- [ ] Split DNS excludes bootstrap domains?
- [ ] Clients notified before database reset?
- [ ] Playbook tested on fresh instance?
- [ ] File checks verify content, not just existence?
- [ ] Verification uses correct protocols (DNS query vs ping)?

After database reset:

- [ ] Regenerate headscale API key for Headplane?
- [ ] Update `vault_headplane_api_key` in vault?
- [ ] All clients re-registered with new preauth keys?
- [ ] Subnet router re-registered and routes approved?

## Related Documentation

- [NETWORK-SEGMENTATION.md](NETWORK-SEGMENTATION.md) - DNS configuration
- [ONBOARDING.md](ONBOARDING.md) - Troubleshooting guide
- [README.md](../README.md) - Management commands
