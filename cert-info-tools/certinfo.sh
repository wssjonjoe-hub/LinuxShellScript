#!/bin/bash

# Usage: ./certinfo.sh <domain> <ip>

if [ $# -ne 2 ]; then
    echo "Usage: $0 <domain> <ip>"
    exit 1
fi

domain="$1"
ip="$2"

echo "Domain: $domain"

echo | openssl s_client -showcerts -servername "$domain" -connect "$ip:443" 2>/dev/null \
| openssl x509 -inform pem -noout -serial -issuer -startdate -enddate