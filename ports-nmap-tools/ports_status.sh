#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 [IP address]"
    exit 1
fi

IP="$1"

# Define associative arrays for port mapping
declare -A PORT_NAMES=(
    [21]="FTP"
    [22]="SSH"
    [2082]="cPanel"
    [2083]="cPanel/SSL"
    [3389]="RDP"
    [8443]="Plesk/SSL"
    [8880]="Plesk"
)

PORTS="21,22,2082,2083,3389,8443,8880"

# Run nmap and store relevant lines
mapfile -t RESULTS < <(nmap -sT -v -Pn "$IP" -p "$PORTS" | grep -E '^([0-9]+)/(tcp|udp)')

# Print table header
printf "%-8s %-10s %s\n" "PORT" "STATUS" "SERVICE"
echo "-------------------------------------------"

# Process each result line
for port in 21 22 2082 2083 3389 8443 8880; do
    # Find line for this port
    line=$(printf "%s\n" "${RESULTS[@]}" | grep "^$port/")
    if [ -n "$line" ]; then
        # Parse status (open/closed/filtered)
        status=$(echo "$line" | awk '{print $2}')
        printf "%-8s %-10s %s\n" "${port}/tcp" "$status" "${PORT_NAMES[$port]}"
    else
        printf "%-8s %-10s %s\n" "${port}/tcp" "unknown" "${PORT_NAMES[$port]}"
    fi
done

echo "-------------------------------------------"