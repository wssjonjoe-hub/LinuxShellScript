#!/bin/bash

# Usage: ./dig_forward_reverse.sh domains.txt

if [ -z "$1" ]; then
    echo "Usage: $0 domains.txt"
    exit 1
fi

DOMAINS_FILE="$1"

echo "----------------------------------------------------------------------------------------------------------"
printf "%-30s %-20s %-16s %-40s\n" "Domain" "Host/webserver" "Firewall IP" "PTR (Reverse DNS)"
echo "----------------------------------------------------------------------------------------------------------"

while read -r domain; do
    # Skip blank lines and comments
    [[ -z "$domain" || "$domain" =~ ^# ]] && continue

    dig "$domain" +noall +answer | awk '$4=="A" || $4=="AAAA" {print $1, $5}' | while read -r name ip; do
        ptr=$(dig -x "$ip" +short | tr -d '\n')
        if [ -z "$ptr" ]; then
            ptr="No PTR record found"
        fi

        output_domain="$domain"
        if [[ "$ptr" == *"sucuri.net." ]]; then
            # Lookup sucuriip.domain, but keep the original domain in the Domain column
            host_webserver=$(dig "sucuriip.$domain" +short | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1)
            if [ -z "$host_webserver" ]; then
                host_webserver="No IP found"
            fi
            firewall_ip="$ip"
        else
            host_webserver="$ip"
            firewall_ip=""
        fi

        printf "%-30s %-20s %-16s %-40s\n" "$output_domain" "$host_webserver" "$firewall_ip" "$ptr"
    done
done < "$DOMAINS_FILE"

echo "----------------------------------------------------------------------------------------------------------"