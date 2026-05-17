#!/bin/bash
# TikTok Desktop Application Uninstaller
# This script removes the TikTok desktop application and its configuration

# Enable strict mode
set -euo pipefail

# ===========================================
# Color definitions
# ===========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}→ ${NC}$1"; }
success() { echo -e "${GREEN}✓ ${NC}$1"; }
warning() { echo -e "${YELLOW}! ${NC}$1"; }
error() { echo -e "${RED}✗ ERROR: ${NC}$1"; exit 1; }

header() { echo -e "\n${BLUE}=== $1 ===${NC}\n"; }

header "TikTok Uninstaller"

# 1. Remove desktop integration
info "Removing desktop entry..."
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
APPLICATIONS_DIR="$XDG_DATA_HOME/applications"
DESKTOP_FILE="tiktok-desktop.desktop"

if [ -f "$APPLICATIONS_DIR/$DESKTOP_FILE" ]; then
    rm "$APPLICATIONS_DIR/$DESKTOP_FILE"
    success "Removed $DESKTOP_FILE"
else
    warning "Desktop file not found in $APPLICATIONS_DIR"
fi

# 2. Remove icon
if command -v xdg-icon-resource &>/dev/null; then
    info "Removing application icon..."
    xdg-icon-resource uninstall --context apps --size 256 tiktok-tiktok || true
    success "Icon uninstalled"
fi

# 3. Remove alias
info "Removing terminal alias..."
for CONFIG in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$CONFIG" ]; then
        if grep -q "alias tiktok=" "$CONFIG"; then
            # Use a temporary file to safely remove the alias
            grep -v "alias tiktok=" "$CONFIG" > "$CONFIG.tmp"
            # Remove the header comment too if it exists
            grep -v "# TikTok Alias" "$CONFIG.tmp" > "$CONFIG.new"
            mv "$CONFIG.new" "$CONFIG"
            rm "$CONFIG.tmp"
            success "Removed alias from $CONFIG"
        fi
    fi
done

# 4. Clean up application data (optional, but good for a fresh start)
info "Removing application data..."
APP_DATA_DIR="$HOME/.config/TikTok"
if [ -d "$APP_DATA_DIR" ]; then
    rm -rf "$APP_DATA_DIR"
    success "Removed $APP_DATA_DIR"
fi

# 5. Clean up local files (node_modules, launcher)
info "Cleaning up local repository files..."
rm -f tiktok.sh
rm -rf node_modules
success "Cleaned up repository"

header "Uninstallation Complete"
echo -e "${GREEN}TikTok Desktop has been removed successfully.${NC}"
echo -e "You can now delete the repository folder if you wish."
