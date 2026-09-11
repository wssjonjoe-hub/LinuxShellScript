#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <domain> <ip>"
    echo "Example: $0 avetabiomics.com 216.198.79.1"
    exit 1
fi

DOMAIN="$1"
IP="$2"

if ! command -v whois >/dev/null 2>&1; then
    echo "Error: whois is not installed."
    echo "Install it with: sudo apt install whois"
    exit 1
fi

IP_WHOIS="$(whois "$IP" 2>/dev/null)"
DOMAIN_WHOIS="$(whois "$DOMAIN" 2>/dev/null)"

# Extract values from IP WHOIS data
NETRANGE="$(awk -F: '
    /^[[:space:]]*NetRange:/ {
        sub(/^[[:space:]]+/, "", $2)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
        print $2
        exit
    }
' <<< "$IP_WHOIS")"

CIDR="$(awk -F: '
    /^[[:space:]]*CIDR:/ {
        sub(/^[[:space:]]+/, "", $2)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
        print $2
        exit
    }
' <<< "$IP_WHOIS")"

NETNAME="$(awk -F: '
    /^[[:space:]]*NetName:/ {
        sub(/^[[:space:]]+/, "", $2)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
        print $2
        exit
    }
' <<< "$IP_WHOIS")"

ORGNAME="$(awk -F: '
    /^[[:space:]]*OrgName:/ {
        sub(/^[[:space:]]+/, "", $2)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
        print $2
        exit
    }
' <<< "$IP_WHOIS")"

# Extract domain WHOIS data
REGISTRAR="$(awk -F: '
    /^[[:space:]]*Registrar:/ {
        sub(/^[[:space:]]+/, "", $2)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
        print $2
        exit
    }
' <<< "$DOMAIN_WHOIS")"

NAME_SERVERS="$(awk -F: '
    /^[[:space:]]*Name Server:/ {
        value = $2
        sub(/^[[:space:]]+/, "", value)
        gsub(/[[:space:]]+$/, "", value)

        key = tolower(value)

        if (!seen[key]++) {
            print value
        }
    }
' <<< "$DOMAIN_WHOIS")"

# WHOIS generally reports the network organization, not a separate
# hosting-provider field. Use OrgName as the provider by default.
PROVIDER="${ORGNAME:-Unknown}"

# Optional friendly provider label for Vercel-hosted IPs.
if [[ "$ORGNAME" =~ [Vv]ercel ]]; then
    PROVIDER="Vercel (PaaS)/Amazon.com, Inc."
fi

echo "Domain: $DOMAIN"
echo "Provider: $PROVIDER"
echo "IP: $IP"
echo "NetRange:       ${NETRANGE:-Not found}"
echo "CIDR:           ${CIDR:-Not found}"
echo "NetName:        ${NETNAME:-Not found}"
echo "OrgName:        ${ORGNAME:-Not found}"
echo "Registrar: ${REGISTRAR:-Not found}"

if [[ -n "$NAME_SERVERS" ]]; then
    while IFS= read -r server; do
        echo "Name Server: $server"
    done <<< "$NAME_SERVERS"
else
    echo "Name Server: Not found"
fi
