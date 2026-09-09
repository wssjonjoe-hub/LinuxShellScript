#!/bin/bash

# Check if a domain name is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 domainnamegoeshere.com"
    exit 1
fi

domain="$1"
url="https://$domain"

# Fetch and filter headers
curl -sI "$url" | grep -Ei '^(HTTP/|Date:|Location:|Server:|.*cache)'