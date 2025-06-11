#!/bin/bash

# Source utility functions
source ./utils.sh

# Function to validate MAC address
validate_mac() {
    local mac="$1"
    if [[ $mac =~ ^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to normalize MAC address (uppercase with colons)
normalize_mac() {
    local mac="$1"
    mac=$(echo "$mac" | tr '-' ':' | tr 'a-f' 'A-F')
    echo "$mac"
}