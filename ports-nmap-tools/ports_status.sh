#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then
    printf 'Usage: %s [IP address or hostname]\n' "$0" >&2
    exit 1
fi

TARGET="$1"

if ! command -v nmap >/dev/null 2>&1; then
    printf 'Error: nmap is not installed or not in PATH.\n' >&2
    exit 1
fi

# ============================================================
# EDIT THIS SECTION ONLY
#
# Format:
#   "PORT|SERVICE NAME"
# ============================================================
PORT_DEFINITIONS=(
    "21|FTP"
    "22|SSH"
    "2082|cPanel"
    "2083|cPanel/SSL"
    "3389|RDP"
    "8443|Plesk/SSL"
    "8880|Plesk"

    # Add additional ports here, for example:
    # "25|SMTP"
    # "80|HTTP"
    # "443|HTTPS"
    # "3306|MySQL"
)
# ============================================================


# Build the port list and service-name lookup automatically
declare -a PORTS
declare -A PORT_NAMES

for definition in "${PORT_DEFINITIONS[@]}"; do
    IFS='|' read -r port service <<< "$definition"

    PORTS+=("$port")
    PORT_NAMES["$port"]="$service"
done

# Convert the port array into: 21,22,2082,2083,...
PORT_SPEC=$(IFS=,; printf '%s' "${PORTS[*]}")

# Run Nmap and store port results
mapfile -t RESULTS < <(
    nmap -sT -Pn "$TARGET" -p "$PORT_SPEC" |
        grep -E '^[0-9]+/tcp[[:space:]]'
)

# Print table header
printf '%-8s %-10s %s\n' "PORT" "STATUS" "SERVICE"
printf '%s\n' "-------------------------------------------"

# Display results in the same order as PORT_DEFINITIONS
for port in "${PORTS[@]}"; do
    line=$(
        printf '%s\n' "${RESULTS[@]}" |
            grep -m1 "^${port}/tcp[[:space:]]"
    )

    if [[ -n "$line" ]]; then
        status=$(awk '{print $2}' <<< "$line")
    else
        status="unknown"
    fi

    printf '%-8s %-10s %s\n' \
        "${port}/tcp" \
        "$status" \
        "${PORT_NAMES[$port]}"
done

printf '%s\n' "-------------------------------------------"
