#!/bin/bash

# Check for exactly 2 arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <extension> <search_string>"
    echo "Example: $0 php casino"
    exit 1
fi

EXT="$1"
SEARCH_STR="$2"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Perform the search
results=$(rg -i -g "*.$EXT" -l "$SEARCH_STR" . 2>/dev/null)

if [ -z "$results" ]; then
    echo "---------------------------------------"
    echo "[$TIMESTAMP] NOT FOUND: '$SEARCH_STR' in *.$EXT"
    echo "---------------------------------------"
else
    echo "---------------------------------------"
    echo "[$TIMESTAMP] MATCHES FOUND:"
    echo "---------------------------------------"
    
    # Create the log entry
    {
        echo "--- Search: '$SEARCH_STR' in *.$EXT at $TIMESTAMP ---"
        echo "$results"
        echo ""
    } | tee -a suspect_results.txt # -a appends to the file instead of overwriting
    
    echo "---------------------------------------"
    echo "Results appended to: suspect_results.txt"
fi
