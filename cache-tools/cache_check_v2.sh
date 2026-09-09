#!/bin/bash

# Check if a domain name is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 domainnamegoeshere.com"
    exit 1
fi

domain="$1"
url="https://$domain"

# Fetch and filter headers
headers=$(curl -sI "$url" | grep -Ei '^(HTTP/|Date:|Location:|Server:|.*cache)')

# Print table header
printf "%-20s | %s\n" "Header" "Value"
printf "%-20s-+-%s\n" "$(printf -- '-%.0s' {1..20})" "$(printf -- '-%.0s' {1..60})"

# Loop through headers and display them in table format
while IFS= read -r line; do
    if [[ $line =~ ^HTTP/ ]]; then
        printf "%-20s | %s\n" "Status" "$line"
    elif [[ $line =~ ^([^:]+):[[:space:]]*(.*) ]]; then
        header="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        printf "%-20s | %s\n" "$header" "$value"
    fi
done <<< "$headers"