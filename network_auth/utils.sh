#!/bin/bash

# Source configuration
source ./config.sh

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to get current timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Function to get compact timestamp for device names
get_compact_timestamp() {
    date '+%Y%m%d_%H%M%S'
}

# Function to get user input
get_input() {
    local prompt="$1"
    local var_name="$2"
    echo -n "$prompt"
    read -r "$var_name"
}