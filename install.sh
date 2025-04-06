#!/bin/bash
# TikTok Desktop Application Installer
# This script installs the TikTok desktop application with all dependencies
# Works on Arch Linux and other pacman-based distributions

# Enable strict mode
set -euo pipefail

# ===========================================
# Color definitions for beautiful output
# ===========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ===========================================
# Helper functions
# ===========================================

# Print a section header
header() {
  echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"
}

# Print an info message
info() {
  echo -e "${CYAN}→ ${NC}$1"
}

# Print a success message
success() {
  echo -e "${GREEN}✓ ${NC}$1"
}

# Print a warning message
warning() {
  echo -e "${YELLOW}! ${NC}$1"
}

# Print an error message and exit
error() {
  echo -e "${RED}✗ ERROR: ${NC}$1" >&2
  exit 1
}

# Display a spinner for background processes
spinner() {
  local pid=$1
  local message=$2
  local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local temp
  
  echo -ne "${CYAN}→ ${NC}$message "
  
  while kill -0 $pid 2>/dev/null; do
    temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep 0.1
    printf "\b\b\b\b\b"
  done
  
  printf "    \b\b\b\b"
  echo -e "${GREEN}✓${NC}"
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if package is installed via pacman
is_package_installed() {
  pacman -Qi "$1" >/dev/null 2>&1
}

# Check and install required system packages
check_and_install_package() {
  local pkg=$1
  info "Checking for $pkg..."
  
  if ! is_package_installed "$pkg"; then
    warning "$pkg is not installed. Installing..."
    if sudo pacman -S --noconfirm "$pkg"; then
      success "$pkg installed successfully!"
    else
      error "Failed to install $pkg"
    fi
  else
    success "$pkg is already installed!"
  fi
}

# Create a simple progress bar
progress_bar() {
  local duration=$1
  local steps=20
  local step_duration=$(echo "$duration / $steps" | bc -l)
  
  echo -ne "${CYAN}→ ${NC}$2 ["
  for ((i=0; i<steps; i++)); do
    echo -ne "${BLUE}=${NC}"
    sleep "$step_duration"
  done
  echo -e "] ${GREEN}✓${NC}"
}

# Animation for script start
start_animation() {
  echo -e "${MAGENTA}"
  echo -e "  ████████╗██╗██╗  ██╗████████╗ ██████╗ ██╗  ██╗"
  echo -e "  ╚══██╔══╝██║██║ ██╔╝╚══██╔══╝██╔═══██╗██║ ██╔╝"
  echo -e "     ██║   ██║█████╔╝    ██║   ██║   ██║█████╔╝ "
  echo -e "     ██║   ██║██╔═██╗    ██║   ██║   ██║██╔═██╗ "
  echo -e "     ██║   ██║██║  ██╗   ██║   ╚██████╔╝██║  ██╗"
  echo -e "     ╚═╝   ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝"
  echo -e "${NC}"
  echo -e "${BOLD}Desktop Application Installer${NC}"
  echo -e "────────────────────────────────────────────────"
  sleep 1
}

# ===========================================
# Main installation process
# ===========================================

# Display welcome animation
start_animation

# Check if we're running on Arch Linux
header "Checking System Compatibility"
if [[ -f /etc/arch-release ]] || command_exists pacman; then
  success "Running on Arch Linux or compatible distribution"
else
  warning "This script is optimized for Arch Linux. Some features may not work correctly."
fi

# Check for root permissions
if [[ $EUID -eq 0 ]]; then
  error "This script should not be run as root. Please run as a normal user."
fi

# Set up trap for clean exit
trap 'echo -e "\n${RED}Installation aborted.${NC}"; exit 1' INT TERM

# Check and install system dependencies
header "Checking System Dependencies"

# Essential dependencies
for pkg in git nodejs npm base-devel; do
  check_and_install_package "$pkg"
done

# Verify Node.js and npm versions
NODE_VERSION=$(node -v)
NPM_VERSION=$(npm -v)

info "Node.js version: $NODE_VERSION"
info "npm version: $NPM_VERSION"

# Comparing versions
if [[ "${NODE_VERSION:1:2}" -lt 16 ]]; then
  warning "Node.js version $NODE_VERSION might be too old. Consider updating to v16 or newer."
fi

# Install npm dependencies
header "Installing Application Dependencies"

# Check if we need to install dependencies
if [[ ! -d "node_modules" ]]; then
  info "Installing npm dependencies..."
  npm install --silent & spinner $! "Installing runtime dependencies..."
  
  info "Installing dev dependencies..."
  npm install --silent --save-dev electron @electron/packager electron-builder & spinner $! "Installing development dependencies..."
else
  info "Checking for dependency updates..."
  npm update --silent & spinner $! "Updating dependencies..."
fi

# Define script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Create launcher script
header "Creating Launcher Script"

info "Creating tiktok.sh launcher script..."
cat > "$SCRIPT_DIR/tiktok.sh" << EOF
#!/bin/bash

# This script runs the TikTok Electron app using npm start
# It can be used for AUR and other package managers combined with libelectron

echo "Starting TikTok..."
cd "$SCRIPT_DIR" || exit 1
npm start
EOF

chmod +x "$SCRIPT_DIR/tiktok.sh"
success "Launcher script created and made executable"

# Setup desktop integration
header "Setting Up Desktop Integration"

# Ensure desktop directory exists
mkdir -p ~/.local/share/applications

# Create desktop file
DESKTOP_PATH=~/.local/share/applications/tiktok-desktop.desktop

info "Creating desktop entry..."
cat > "$DESKTOP_PATH" << EOF
[Desktop Entry]
Name=TikTok
Comment=Make Your Day
GenericName=Short-form Video Platform
Exec=$SCRIPT_DIR/tiktok.sh
Icon=$SCRIPT_DIR/icon.png
Terminal=false
Type=Application
Categories=Network;Video;Social;InstantMessaging;
Keywords=TikTok;Social Media;Videos;Shorts;Entertainment;
StartupWMClass=TikTok
Version=1.0
EOF

# Create desktop shortcut
DESKTOP_DIR="$HOME/Desktop"
if [[ -d "$DESKTOP_DIR" ]]; then
  info "Creating desktop shortcut..."
  DESKTOP_SHORTCUT="$DESKTOP_DIR/TikTok.desktop"
  cp "$DESKTOP_PATH" "$DESKTOP_SHORTCUT"
  chmod +x "$DESKTOP_SHORTCUT"
  success "Desktop shortcut created at $DESKTOP_SHORTCUT"
else
  warning "Desktop directory not found. Skipping desktop shortcut creation."
fi

# Make the shell script executable
chmod +x "$SCRIPT_DIR/tiktok.sh"
success "Desktop entry created at $DESKTOP_PATH"

# Update desktop database
if command_exists update-desktop-database; then
  update-desktop-database ~/.local/share/applications &>/dev/null
  success "Desktop database updated"
fi

# Setup terminal command
header "Setting Up Terminal Command"

info "Adding terminal command 'tiktok'..."

# Determine shell and config file
SHELL_CONFIG=""
if [[ "$SHELL" == *"zsh"* ]]; then
  SHELL_CONFIG="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
  SHELL_CONFIG="$HOME/.bashrc"
fi

if [[ -n "$SHELL_CONFIG" ]]; then
  # Check if alias already exists
  if grep -q "alias tiktok=" "$SHELL_CONFIG"; then
    info "Terminal command 'tiktok' already exists"
  else
    # Add alias to shell config
    echo -e "\n# TikTok Desktop Application alias" >> "$SHELL_CONFIG"
    echo "alias tiktok='$SCRIPT_DIR/tiktok.sh'" >> "$SHELL_CONFIG"
    success "Terminal command 'tiktok' added to $SHELL_CONFIG"
    info "You'll need to restart your terminal or run 'source $SHELL_CONFIG' to use it"
  fi
else
  warning "Unable to determine shell configuration file. Manual setup required."
  info "To use TikTok from anywhere, add this to your shell config file:"
  echo "alias tiktok='$SCRIPT_DIR/tiktok.sh'"
fi

# Create a symlink in /usr/local/bin (requires sudo)
info "Creating system-wide command (requires sudo)..."
if sudo ln -sf "$SCRIPT_DIR/tiktok.sh" /usr/local/bin/tiktok 2>/dev/null; then
  sudo chmod +x /usr/local/bin/tiktok
  success "System-wide 'tiktok' command created"
else
  warning "Could not create system-wide command. You may need to run with sudo."
fi

# Validate installation
header "Validating Installation"

# Check for critical files and dependencies
info "Performing post-installation checks..."

progress_bar 1 "Checking files"
if [[ ! -f "main.js" ]]; then
  error "main.js not found. Installation may be corrupted."
fi

progress_bar 1 "Checking dependencies"
if [[ ! -x "tiktok.sh" ]]; then
  error "tiktok.sh not found or not executable."
fi

progress_bar 1 "Checking node_modules"
if [[ ! -d "node_modules" ]]; then
  error "Node modules not installed correctly."
fi

progress_bar 1 "Checking electron"
if [[ ! -d "node_modules/electron" ]]; then
  error "Electron not installed correctly."
fi

# All checks passed
header "Installation Complete"
echo -e "
${GREEN}TikTok Desktop Application has been successfully installed!${NC}

${BOLD}To start the application:${NC}
  1. Type ${CYAN}tiktok${NC} in your terminal
  2. Run ${CYAN}./tiktok.sh${NC} from this directory
  3. Click the desktop shortcut on your Desktop
  4. Use your desktop environment's application menu

${BOLD}For updates:${NC}
  Run this installer again to update dependencies

${YELLOW}Note:${NC} If you encounter any issues, please report them at the repository.
"

exit 0

