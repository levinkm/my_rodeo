#!/bin/bash

# Source configuration, utility, and MAC utilities
source ./config.sh
source ./utils.sh
source ./mac_utils.sh
source ./history.sh

# Function to authenticate device
authenticate_device() {
    local mac_address="$1"
    local device_name="$2"
    
    # Validate MAC address
    if ! validate_mac "$mac_address"; then
        print_error "Invalid MAC address format: $mac_address"
        return 1
    fi
    
    # Normalize MAC address
    mac_address=$(normalize_mac "$mac_address")
    
    print_info "Authenticating device: ${device_name:-$mac_address}"
    print_info "MAC Address: $mac_address"
    
    # Build the authentication URL
    local auth_url="${BASE_URL}?interface_mode=${INTERFACE_MODE}&pagetype=${PAGETYPE}&wired_auth=${WIRED_AUTH}&interface=${INTERFACE}&staIp=${STA_IP}&staMac=${mac_address}&url=${URL_PARAM}&bas_port=${BAS_PORT}&bas_http_port=${BAS_HTTP_PORT}"
    
    # Make the authentication request
    local response
    response=$(curl -s -w "%{http_code}" -o /tmp/auth_response.html "$auth_url" 2>/dev/null)
    local http_code="${response: -3}"
    
    if [[ "$http_code" == "200" ]]; then
        # Check response content for success indicators
        local response_content=$(cat /tmp/auth_response.html 2>/dev/null)
        
        if echo "$response_content" | grep -qi "success\|authenticated\|welcome"; then
            print_success "Authentication successful"
            save_mac_to_history "$mac_address" "$device_name"
            rm -f /tmp/auth_response.html
            return 0
        elif echo "$response_content" | grep -qi "already"; then
            print_success "Device already authenticated"
            save_mac_to_history "$mac_address" "$device_name"
            rm -f /tmp/auth_response.html
            return 0
        else
            print_error "Authentication failed - Check portal response"
            print_info "Response preview: $(echo "$response_content" | head -c 200)..."
            rm -f /tmp/auth_response.html
            return 1
        fi
    else
        print_error "HTTP Error: $http_code"
        rm -f /tmp/auth_response.html
        return 1
    fi
}

# Function to authenticate from history
authenticate_from_history() {
    local index="$1"
    
    if [[ ! -f "$CONFIG_FILE" || ! -s "$CONFIG_FILE" ]]; then
        print_error "No MAC addresses in history"
        return 1
    fi
    
    local counter=1
    while IFS='|' read -r mac name timestamp auth_count; do
        if [[ "$counter" == "$index" ]]; then
            authenticate_device "$mac" "$name"
            return $?
        fi
        ((counter++))
    done < "$CONFIG_FILE"
    
    print_error "Invalid history index: $index"
    return 1
}