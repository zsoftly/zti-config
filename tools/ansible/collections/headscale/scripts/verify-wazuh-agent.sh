#!/usr/bin/env bash
#
# Wazuh Agent Verification Script
# Checks agent installation, connectivity, and enrollment status
#
# Usage: ./scripts/verify-wazuh-agent.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print section header
print_header() {
    echo -e "\n${BLUE}================================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================================================${NC}\n"
}

# Print check result
print_check() {
    local status=$1
    local message=$2

    if [[ "$status" == "OK" ]]; then
        echo -e "[${GREEN}OK${NC}] $message"
    elif [[ "$status" == "WARN" ]]; then
        echo -e "[${YELLOW}WARN${NC}] $message"
    else
        echo -e "[${RED}FAIL${NC}] $message"
    fi
}

print_header "WAZUH AGENT VERIFICATION"

# Check 1: Agent binary exists
print_header "1. Installation Check"
if [[ -f /var/ossec/bin/wazuh-control ]]; then
    print_check "OK" "Wazuh agent binary found"

    # Get version
    version=$(/var/ossec/bin/wazuh-control info | grep "WAZUH_VERSION" | cut -d'"' -f2 || echo "unknown")
    echo "   Version: $version"
else
    print_check "FAIL" "Wazuh agent binary not found"
    echo "   Expected: /var/ossec/bin/wazuh-control"
    exit 1
fi

# Check 2: Service status
print_header "2. Service Status"
if systemctl is-active --quiet wazuh-agent; then
    print_check "OK" "Wazuh agent service is running"

    # Get service uptime
    uptime=$(systemctl status wazuh-agent | grep "Active:" | sed 's/.*Active: //' || echo "unknown")
    echo "   Status: $uptime"
else
    print_check "FAIL" "Wazuh agent service is not running"
    echo "   Start with: sudo systemctl start wazuh-agent"
    exit 1
fi

if systemctl is-enabled --quiet wazuh-agent; then
    print_check "OK" "Service is enabled (auto-start on boot)"
else
    print_check "WARN" "Service is not enabled"
    echo "   Enable with: sudo systemctl enable wazuh-agent"
fi

# Check 3: Configuration file
print_header "3. Configuration Check"
if [[ -f /var/ossec/etc/ossec.conf ]]; then
    print_check "OK" "Configuration file exists"

    # Extract manager address
    manager=$(grep -oP '(?<=<address>).*?(?=</address>)' /var/ossec/etc/ossec.conf | head -1)
    echo "   Manager: $manager"

    # Extract port
    port=$(grep -oP '(?<=<port>).*?(?=</port>)' /var/ossec/etc/ossec.conf | head -1)
    echo "   Port: $port"
else
    print_check "FAIL" "Configuration file not found"
    exit 1
fi

# Check 4: Enrollment status
print_header "4. Enrollment Check"
if [[ -f /var/ossec/etc/client.keys ]]; then
    print_check "OK" "Enrollment key file exists"

    # Check if file has content
    if [[ -s /var/ossec/etc/client.keys ]]; then
        print_check "OK" "Agent is enrolled with manager"

        # Extract agent ID and name (don't show the key)
        agent_info=$(head -1 /var/ossec/etc/client.keys | cut -d' ' -f1-2)
        echo "   Agent: $agent_info"
    else
        print_check "FAIL" "Enrollment key file is empty"
        echo "   Re-enroll with: sudo /var/ossec/bin/agent-auth -m siem.example.com -p 1515"
        exit 1
    fi
else
    print_check "FAIL" "Enrollment key file not found"
    echo "   Enroll with: sudo /var/ossec/bin/agent-auth -m siem.example.com -p 1515"
    exit 1
fi

# Check 5: Connectivity to manager
print_header "5. Manager Connectivity"
if [[ -f /var/ossec/logs/ossec.log ]]; then
    # Check for recent connection messages (last 50 lines)
    if tail -50 /var/ossec/logs/ossec.log | grep -q "Connected to the server"; then
        print_check "OK" "Agent successfully connected to manager"

        # Show last connection time
        last_connect=$(grep "Connected to the server" /var/ossec/logs/ossec.log | tail -1 | awk '{print $1, $2}')
        echo "   Last connected: $last_connect"
    else
        print_check "WARN" "No recent connection messages in logs"
        echo "   Check: tail -f /var/ossec/logs/ossec.log"
    fi

    # Check for errors
    if tail -50 /var/ossec/logs/ossec.log | grep -qi "error\|unable to connect"; then
        print_check "WARN" "Errors detected in recent logs"
        echo "   Review errors: grep -i error /var/ossec/logs/ossec.log | tail -10"
    fi
else
    print_check "WARN" "Log file not found or empty"
fi

# Check 6: Network connectivity test
print_header "6. Network Connectivity Test"
manager_host="siem.example.com"

# Test DNS resolution
if host "$manager_host" > /dev/null 2>&1; then
    print_check "OK" "DNS resolution successful"
    manager_ip=$(host "$manager_host" | grep "has address" | head -1 | awk '{print $4}')
    echo "   Resolved: $manager_host -> $manager_ip"
else
    print_check "FAIL" "DNS resolution failed for $manager_host"
    exit 1
fi

# Test connectivity to agent port (1514)
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$manager_host/1514" 2>/dev/null; then
    print_check "OK" "Network connectivity to manager port 1514 successful"
else
    print_check "FAIL" "Cannot connect to manager port 1514"
    echo "   Troubleshoot:"
    echo "   - Check VPN connection (if remote)"
    echo "   - Verify security group allows outbound TCP 1514, 1515"
    echo "   - Test: telnet $manager_host 1514"
fi

# Test connectivity to enrollment port (1515)
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$manager_host/1515" 2>/dev/null; then
    print_check "OK" "Network connectivity to manager port 1515 successful"
else
    print_check "WARN" "Cannot connect to manager port 1515 (needed for enrollment only)"
fi

# Check 7: System resources
print_header "7. Resource Usage"
if command -v ps &> /dev/null; then
    # Get Wazuh agent process info
    if pgrep -x wazuh-agentd > /dev/null; then
        mem_usage=$(ps aux | grep wazuh-agentd | grep -v grep | awk '{print $4}')
        cpu_usage=$(ps aux | grep wazuh-agentd | grep -v grep | awk '{print $3}')

        print_check "OK" "Agent process running"
        echo "   Memory: ${mem_usage}%"
        echo "   CPU: ${cpu_usage}%"
    else
        print_check "WARN" "Agent process not found"
    fi
fi

# Final summary
print_header "SUMMARY"
echo -e "${GREEN}Wazuh agent verification complete.${NC}\n"
echo "Next steps:"
echo "  1. Verify agent appears in dashboard:"
echo "     https://siem.example.com"
echo "     Navigate to: Agents -> Agents Management"
echo ""
echo "  2. Monitor agent logs:"
echo "     sudo tail -f /var/ossec/logs/ossec.log"
echo ""
echo "  3. Check agent status:"
echo "     sudo systemctl status wazuh-agent"
echo ""
