#!/bin/bash

# Source configuration and utility functions
source ./config.sh
source ./utils.sh

# Function to load MAC history
load_mac_history() {
    if [[ -f "$CONFIG_FILE" ]]; then
        cat "$CONFIG_FILE"
    fi
}

# Function to save MAC to history
save_mac_to_history() {
    local mac="$1"
    local name="$2"
    local timestamp=$(get_timestamp)
    
    # If no name provided, generate one
    if [[ -z "$name" ]]; then
        name="Device_$(get_compact_timestamp)"
    fi
    
    # Create temp file for new history
    local temp_file=$(mktemp)
    
    # Add new entry at the top
    echo "$mac|$name|$timestamp|1" > "$temp_file"
    
    # Add existing entries (excluding the same MAC if it exists)
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS='|' read -r existing_mac existing_name existing_time auth_count; do
            if [[ "$existing_mac" != "$mac" ]]; then
                echo "$existing_mac|$existing_name|$existing_time|$auth_count" >> "$temp_file"
            else
                # If MAC exists, increment auth count
                ((auth_count++))
                echo "$mac|$name|$timestamp|$auth_count" > "$temp_file.tmp"
                cat "$temp_file" >> "$temp_file.tmp"
                mv "$temp_file.tmp" "$temp_file"
                sed -i '2d' "$temp_file"  # Remove the duplicate entry we just added
            fi
        done < "$CONFIG_FILE"
    fi
    
    # Keep only the first MAX_HISTORY entries
    head -n "$MAX_HISTORY" "$temp_file" > "$CONFIG_FILE"
    rm -f "$temp_file"
}

# Function to show MAC history
show_mac_history() {
    if [[ ! -f "$CONFIG_FILE" || ! -s "$CONFIG_FILE" ]]; then
        print_info "No MAC addresses in history"
        return
    fi
    
    echo
    echo "=== MAC Address History (Last $MAX_HISTORY) ==="
    echo
    
    local counter=1
    while IFS='|' read -r mac name timestamp auth_count; do
        echo "${counter}. $name"
        echo "   MAC: $mac"
        echo "   Last Used: $timestamp"
        echo "   Auth Count: ${auth_count:-1}"
        echo
        ((counter++))
    done < "$CONFIG_FILE"
}