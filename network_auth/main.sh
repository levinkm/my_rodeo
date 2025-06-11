#!/bin/bash

# Source all necessary modules
source ./config.sh
source ./utils.sh
source ./history.sh
source ./auth.sh

# Function to display menu
show_menu() {
    echo
    echo "=== Network Authentication Tool ==="
    echo "1. Authenticate new device"
    echo "2. Show MAC history"
    echo "3. Re-authenticate from history"
    echo "4. Exit"
    echo
}

# Function to check for required commands
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_info "Please install the missing dependencies and try again."
        exit 1
    fi
}

# Main function
main() {
    echo "Network Authentication Script for Sasa Connect Portal"
    echo "===================================================="
    
    while true; do
        show_menu
        get_input "Select option (1-4): " choice
        
        case "$choice" in
            1)
                get_input "Enter MAC address: " mac
                get_input "Enter device name (optional): " name
                
                if [[ -n "$mac" ]]; then
                    authenticate_device "$mac" "$name"
                else
                    print_error "MAC address cannot be empty"
                fi
                ;;
            2)
                show_mac_history
                ;;
            3)
                show_mac_history
                if [[ -f "$CONFIG_FILE" && -s "$CONFIG_FILE" ]]; then
                    get_input "Enter device number to re-authenticate: " index
                    if [[ "$index" =~ ^[0-9]+$ ]]; then
                        authenticate_from_history "$index"
                    else
                        print_error "Invalid input. Please enter a number."
                    fi
                fi
                ;;
            4)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please select 1-4."
                ;;
        esac
        
        # Pause before showing menu again
        echo
        read -p "Press Enter to continue..."
    done
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check dependencies
    check_dependencies
    
    # Handle command line arguments
    if [[ $# -eq 0 ]]; then
        # Interactive mode
        main
    elif [[ $# -eq 1 || $# -eq 2 ]]; then
        # Direct authentication mode
        authenticate_device "$1" "$2"
    else
        echo "Usage: $0 [MAC_ADDRESS] [DEVICE_NAME]"
        echo "   or: $0 (for interactive mode)"
        exit 1
    fi
fi