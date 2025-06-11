#!/bin/bash

# Script to test and manage Flutter App Bundle using bundletool
# Checks for ~/bundletool.jar, downloads if missing
# Uninstalls existing app before installation
# Dynamically extracts PACKAGE_NAME from bundle or accepts --package
# Usage: ./test_bundletool.sh --bundle=<path-to-aab> --output=<path-to-apks> [--package=<package-name>] [command]

# Default bundletool path
BUNDLETOOL=~/bundletool.jar

# URL for downloading bundletool (version 1.8.2)
BUNDLETOOL_URL="https://github.com/google/bundletool/releases/download/1.8.2/bundletool-all-1.8.2.jar"

# Default values
BUNDLE=""
OUTPUT=""
PACKAGE_NAME=""
COMMAND=""

# Function to display usage
usage() {
    echo "Usage: $0 --bundle=<path-to-aab> --output=<path-to-apks> [--package=<package-name>] [command]"
    echo "Commands:"
    echo "  test        Generate and install APKs (uninstalls existing app, default)"
    echo "  build       Generate APKs only"
    echo "  install     Install previously generated APKs (uninstalls existing app)"
    echo "  validate    Validate the App Bundle"
    echo "  extract     Extract device-specific APKs"
    echo "Example:"
    echo "  $0 --bundle=build/app/outputs/bundle/release/app-release.aab --output=app.apks test"
    echo "  $0 --bundle=build/app/outputs/bundle/release/app-release.aab --output=app.apks --package=com.hcash install"
    exit 1
}

# Function to check and download bundletool
check_bundletool() {
    if [ ! -f "$BUNDLETOOL" ]; then
        echo "bundletool.jar not found at $BUNDLETOOL, downloading..."
        curl -L -o "$BUNDLETOOL" "$BUNDLETOOL_URL"
        if [ $? -eq 0 ]; then
            echo "Successfully downloaded bundletool to $BUNDLETOOL"
        else
            echo "Error: Failed to download bundletool from $BUNDLETOOL_URL"
            exit 1
        fi
    else
        echo "bundletool.jar found at $BUNDLETOOL"
    fi
}

# Function to check if ADB is installed
check_adb() {
    if ! command -v adb &> /dev/null; then
        echo "Error: ADB not found. Install Android SDK Platform-Tools."
        exit 1
    fi
}

# Function to extract package name from bundle
extract_package_name() {
    if [ -z "$PACKAGE_NAME" ]; then
        echo "Extracting package name from $BUNDLE..."
        PACKAGE_NAME=$(java -jar "$BUNDLETOOL" dump manifest --bundle="$BUNDLE" | grep "package=" | sed -n 's/.*package="\([^"]*\)".*/\1/p')
        if [ -z "$PACKAGE_NAME" ]; then
            echo "Error: Could not extract package name from $BUNDLE"
            echo "Please provide --package=<package-name>"
            exit 1
        fi
        echo "Package name: $PACKAGE_NAME"
    fi
}

# Function to uninstall existing app
uninstall_app() {
    check_adb
    extract_package_name
    echo "Checking if $PACKAGE_NAME is installed..."
    if adb shell pm list packages | grep -q "$PACKAGE_NAME"; then
        echo "Uninstalling $PACKAGE_NAME..."
        adb uninstall "$PACKAGE_NAME"
        if [ $? -eq 0 ]; then
            echo "Successfully uninstalled $PACKAGE_NAME"
        else
            echo "Warning: Failed to uninstall $PACKAGE_NAME, proceeding with installation"
        fi
    else
        echo "$PACKAGE_NAME is not installed, no uninstall needed"
    fi
}

# Function to generate APKs
build_apks() {
    echo "Generating APKs from $BUNDLE to $OUTPUT..."
    java -jar "$BUNDLETOOL" build-apks --bundle="$BUNDLE" --output="$OUTPUT" --overwrite
    if [ $? -eq 0 ]; then
        echo "APKs generated successfully at $OUTPUT"
    else
        echo "Error: Failed to generate APKs"
        exit 1
    fi
}

# Function to install APKs
install_apks() {
    if [ ! -f "$OUTPUT" ]; then
        echo "Error: APKs file not found at $OUTPUT"
        exit 1
    fi
    echo "Installing APKs from $OUTPUT..."
    uninstall_app
    java -jar "$BUNDLETOOL" install-apks --apks="$OUTPUT"
    if [ $? -eq 0 ]; then
        echo "APKs installed successfully"
    else
        echo "Error: Failed to install APKs"
        exit 1
    fi
}

# Function to validate App Bundle
validate_bundle() {
    echo "Validating App Bundle $BUNDLE..."
    java -jar "$BUNDLETOOL" validate --bundle="$BUNDLE"
    if [ $? -eq 0 ]; then
        echo "App Bundle is valid"
    else
        echo "Error: App Bundle validation failed"
        exit 1
    fi
}

# Function to extract device-specific APKs
extract_device_apks() {
    check_adb
    echo "Extracting device-specific APKs for connected device..."
    java -jar "$BUNDLETOOL" build-apks --bundle="$BUNDLE" --output="$OUTPUT" --overwrite --connected-device
    if [ $? -eq 0 ]; then
        echo "Device-specific APKs generated at $OUTPUT"
    else
        echo "Error: Failed to extract device-specific APKs"
        exit 1
    fi
}

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --bundle=*)
            BUNDLE="${1#*=}"
            ;;
        --output=*)
            OUTPUT="${1#*=}"
            ;;
        --package=*)
            PACKAGE_NAME="${1#*=}"
            ;;
        test|build|install|validate|extract)
            COMMAND="$1"
            ;;
        *)
            echo "Error: Unknown argument $1"
            usage
            ;;
    esac
    shift
done

# Validate arguments
if [ -z "$BUNDLE" ] || [ -z "$OUTPUT" ]; then
    echo "Error: --bundle and --output are required"
    usage
fi

if [ ! -f "$BUNDLE" ]; then
    echo "Error: Bundle file not found at $BUNDLE"
    exit 1
fi

# Default command is 'test'
COMMAND=${COMMAND:-test}

# Check and download bundletool
check_bundletool

# Execute command
case "$COMMAND" in
    test)
        build_apks
        install_apks
        ;;
    build)
        build_apks
        ;;
    install)
        install_apks
        ;;
    validate)
        validate_bundle
        ;;
    extract)
        extract_device_apks
        ;;
    *)
        echo "Error: Unknown command $COMMAND"
        usage
        ;;
esac

exit 0
