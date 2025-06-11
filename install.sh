#!/bin/bash

# install.sh: Installs custom tools from ~/Dev/Tools as terminal commands
# Installs to ~/.local/bin for user-specific access
# Usage: ./install.sh

# Base directory for tools
TOOLS_DIR="$HOME/Dev/Tools"

# Target directory for commands
BIN_DIR="$HOME/.local/bin"

# Function to display usage
usage() {
    echo "Usage: $0"
    echo "Installs tools from $TOOLS_DIR as commands in $BIN_DIR"
    echo "Example: $0"
    exit 1
}

# Function to check dependencies
check_dependencies() {
    echo "Checking dependencies..."
    local deps=("curl" "adb" "java")
    local missing=0
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "Error: $dep is not installed"
            missing=1
        else
            echo "$dep found"
        fi
    done
    if [ "$missing" -eq 1 ]; then
        echo "Please install missing dependencies:"
        echo "- curl: 'sudo apt-get install curl' (Linux) or 'brew install curl' (macOS)"
        echo "- adb: 'sudo apt-get install android-sdk-platform-tools' (Linux) or 'brew install android-platform-tools' (macOS)"
        echo "- java: 'sudo apt-get install openjdk-11-jre' (Linux) or 'brew install java' (macOS)"
        exit 1
    fi
}

# Function to ensure ~/.local/bin is in PATH
ensure_path() {
    echo "Checking if $BIN_DIR is in PATH..."
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo "Adding $BIN_DIR to PATH in ~/.bashrc and ~/.zshrc..."
        # Append to .bashrc
        echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.bashrc"
        # Append to .zshrc if it exists (for macOS or zsh users)
        [ -f "$HOME/.zshrc" ] && echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.zshrc"
        echo "Added $BIN_DIR to PATH"
        echo "Please run 'source ~/.bashrc' or 'source ~/.zshrc' (or restart your terminal) to update PATH"
    else
        echo "$BIN_DIR is already in PATH"
    fi
}

# Function to install a tool
install_tool() {
    local src="$1"
    local dest_name="$2"
    local dest="$BIN_DIR/$dest_name"

    echo "Installing $src as $dest_name..."
    # Create ~/.local/bin if it doesn't exist
    mkdir -p "$BIN_DIR"
    # Copy and rename (strip .sh)
    cp "$src" "$dest"
    # Make executable
    chmod +x "$dest"
    if [ $? -eq 0 ]; then
        echo "Successfully installed $dest_name to $BIN_DIR"
    else
        echo "Error: Failed to install $dest_name"
        exit 1
    fi
}

# Main installation logic
main() {
    # Check if TOOLS_DIR exists
    if [ ! -d "$TOOLS_DIR" ]; then
        echo "Error: Tools directory $TOOLS_DIR does not exist"
        exit 1
    fi

    # Check dependencies
    check_dependencies

    # Ensure ~/.local/bin is in PATH
    ensure_path

    # Install test_bundletool.sh
    local bundletool_script="$TOOLS_DIR/BundleTool/test_bundletool.sh"
    if [ -f "$bundletool_script" ]; then
        install_tool "$bundletool_script" "test-bundletool"
    else
        echo "Warning: $bundletool_script not found, skipping"
    fi

    # Add more tools here in the future
    # Example:
    # if [ -f "$TOOLS_DIR/OtherTool/other_script.sh" ]; then
    #     install_tool "$TOOLS_DIR/OtherTool/other_script.sh" "other-tool"
    # fi

    echo "Installation complete!"
    echo "Run 'test-bundletool --help' to verify"
    echo "If commands don't work, run 'source ~/.bashrc' or 'source ~/.zshrc'"
}

# Parse arguments
if [ $# -gt 0 ]; then
    echo "Error: No arguments expected"
    usage
fi

# Run main
main

exit 0
