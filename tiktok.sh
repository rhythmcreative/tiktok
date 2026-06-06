#!/bin/bash
# TikTok Launcher with error checking
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" &>/dev/null && pwd)"
cd "$SCRIPT_DIR" || exit 1

if [ ! -d "node_modules" ]; then
    echo "Error: Application dependencies not found. Please run './install.sh' first."
    if command -v notify-send &>/dev/null; then
        notify-send "TikTok Desktop" "Error: Dependencies not found. Please run install.sh"
    fi
    exit 1
fi

export PATH=$PATH:/usr/local/bin:/usr/bin:/bin
npm start
