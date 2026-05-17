#!/bin/bash
# TikTok Launcher with error checking

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "Error: Application dependencies not found in $SCRIPT_DIR."
    echo "Please run './install.sh' first to install the application correctly."
    
    # Try to notify the user if notify-send exists
    if command -v notify-send &>/dev/null; then
        notify-send "TikTok Desktop" "Error: Dependencies not found. Please run install.sh" -i "$SCRIPT_DIR/icon.png"
    fi
    exit 1
fi

# Export path for common installation locations
export PATH=$PATH:/usr/local/bin:/usr/bin:/bin

echo "Starting TikTok from $SCRIPT_DIR..."

# Run the application
if ! npm start; then
    echo "Error: Failed to start the application."
    echo "This might be due to a missing Electron installation or a configuration error."
    exit 1
fi
