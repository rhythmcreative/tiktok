#!/bin/bash
# TikTok Desktop Application Installer
# This script installs the TikTok desktop application with all dependencies
# Works on Arch, Debian/Ubuntu, and Fedora/RHEL based distributions

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

# ===========================================
# System and Package Manager Detection
# ===========================================
PACKAGE_MANAGER=""
DISTRO=""

detect_distro() {
    if command_exists pacman; then
        DISTRO="arch"
        PACKAGE_MANAGER="pacman"
    elif command_exists apt; then
        DISTRO="debian"
        PACKAGE_MANAGER="apt"
    elif command_exists dnf; then
        DISTRO="rpm"
        PACKAGE_MANAGER="dnf"
    elif command_exists yum; then
        DISTRO="rpm"
        PACKAGE_MANAGER="yum"
    else
        error "Unsupported distribution. This script supports Arch, Debian/Ubuntu, and Fedora/RHEL based distributions."
    fi
}

is_package_installed() {
    local pkg=$1
    case "$PACKAGE_MANAGER" in
        pacman)
            pacman -Qi "$pkg" &>/dev/null
            ;;
        apt)
            dpkg -s "$pkg" &>/dev/null
            ;;
        dnf|yum)
            rpm -q "$pkg" &>/dev/null
            ;;
    esac
}

install_package() {
    local pkg=$1
    local install_cmd=""
    case "$PACKAGE_MANAGER" in
        pacman)
            install_cmd="sudo pacman -S --noconfirm"
            ;;
        apt)
            install_cmd="sudo apt install -y"
            ;;
        dnf)
            install_cmd="sudo dnf install -y"
            ;;
        yum)
            install_cmd="sudo yum install -y"
            ;;
    esac

    if $install_cmd "$pkg"; then
        success "$pkg installed successfully!"
    else
        error "Failed to install $pkg"
    fi
}

check_and_install_package() {
  local pkg_name=$1
  local pkg_map=$2
  local pkg

  if [[ -n "$pkg_map" ]]; then
      pkg=$(echo "$pkg_map" | grep "^$DISTRO:" | cut -d':' -f2)
      if [[ -z "$pkg" ]]; then
          error "No package mapping found for '$pkg_name' on '$DISTRO' distribution."
      fi
  else
      pkg=$pkg_name
  fi

  info "Checking for $pkg..."
  
  if ! is_package_installed "$pkg"; then
    warning "$pkg is not installed. Installing..."
    install_package "$pkg"
  else
    success "$pkg is already installed!"
  fi
}

# Create a simple progress bar
progress_bar() {
  local duration=$1
  local steps=20
  local step_duration
  step_duration=$(echo "$duration / $steps" | bc -l)
  
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

# Detect distribution
header "Checking System Compatibility"
detect_distro
success "Running on a $DISTRO-based distribution ($PACKAGE_MANAGER)"

# Check for root permissions
if [[ $EUID -eq 0 ]]; then
  error "This script should not be run as root. Please run as a normal user."
fi

# Set up trap for clean exit
trap 'echo -e "\n${RED}Installation aborted.${NC}"; exit 1' INT TERM

# Check and install system dependencies
header "Checking System Dependencies"

# Package mappings
DEV_TOOLS_MAP="arch:base-devel:debian:build-essential:rpm:\"Development Tools\""

# Essential dependencies
check_and_install_package "git"
check_and_install_package "nodejs"
check_and_install_package "npm"
if [[ "$PACKAGE_MANAGER" == "dnf" || "$PACKAGE_MANAGER" == "yum" ]]; then
    info "Installing Development Tools group..."
    if sudo "$PACKAGE_MANAGER" groupinstall -y "Development Tools"; then
        success "Development Tools installed successfully!"
    else
        error "Failed to install Development Tools"
    fi
else
    check_and_install_package "build-essential" "$DEV_TOOLS_MAP"
fi


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

# Get absolute paths for use in desktop entries
SCRIPT_ABS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
EXEC_PATH="$SCRIPT_ABS_DIR/tiktok.sh"
ICON_PATH="$SCRIPT_ABS_DIR/icon.png"

# Verify the icon exists
if [[ ! -f "$ICON_PATH" ]]; then
  warning "Icon file not found at $ICON_PATH. Desktop entry may display without an icon."
fi

# Ensure applications directory exists
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
APPLICATIONS_DIR="$XDG_DATA_HOME/applications"
info "Ensuring applications directory exists at $APPLICATIONS_DIR"
mkdir -p "$APPLICATIONS_DIR"

# Create desktop file
DESKTOP_PATH="$APPLICATIONS_DIR/tiktok-desktop.desktop"

info "Creating desktop entry..."
cat > "$DESKTOP_PATH" << EOF
[Desktop Entry]
Type=Application
Name=TikTok
Comment=Make Your Day
GenericName=Short-form Video Platform
Exec=$EXEC_PATH
Icon=$ICON_PATH
Terminal=false
Categories=Network;Video;Social;InstantMessaging;
Keywords=TikTok;Social Media;Videos;Shorts;Entertainment;
StartupWMClass=TikTok
Version=1.0
EOF

# Set proper permissions for .desktop file (not executable)
chmod 644 "$DESKTOP_PATH"

# Verify desktop entry creation
if [[ -f "$DESKTOP_PATH" ]]; then
  success "Desktop entry created at $DESKTOP_PATH"
else
  error "Failed to create desktop entry at $DESKTOP_PATH"
fi

# Create desktop shortcut using XDG specification
# First try XDG_DESKTOP_DIR, then try standard Desktop directory
XDG_DESKTOP_DIR="${XDG_DESKTOP_DIR:-$HOME/Desktop}"
if [[ ! -d "$XDG_DESKTOP_DIR" ]]; then
  # Try to get desktop folder from user-dirs.dirs
  if [[ -f "$XDG_CONFIG_HOME/user-dirs.dirs" ]]; then
    source "$XDG_CONFIG_HOME/user-dirs.dirs"
    XDG_DESKTOP_DIR="${XDG_DESKTOP_DIR:-$HOME/Desktop}"
  fi
fi

if [[ -d "$XDG_DESKTOP_DIR" ]]; then
  info "Creating desktop shortcut in $XDG_DESKTOP_DIR..."
  DESKTOP_SHORTCUT="$XDG_DESKTOP_DIR/TikTok.desktop"
  cp "$DESKTOP_PATH" "$DESKTOP_SHORTCUT"
  # Set proper permissions (not executable)
  chmod 644 "$DESKTOP_SHORTCUT"
  
  # Verify desktop shortcut creation
  if [[ -f "$DESKTOP_SHORTCUT" ]]; then
    success "Desktop shortcut created at $DESKTOP_SHORTCUT"
  else
    warning "Failed to create desktop shortcut at $DESKTOP_SHORTCUT"
  fi
else
  warning "Desktop directory not found at $XDG_DESKTOP_DIR. Skipping desktop shortcut creation."
fi

# Make the shell script executable
chmod +x "$EXEC_PATH"

# Update desktop database
if command_exists update-desktop-database; then
  info "Updating desktop database..."
  update-desktop-database "$APPLICATIONS_DIR" &>/dev/null
  if [[ $? -eq 0 ]]; then
    success "Desktop database updated successfully"
  else
    warning "Failed to update desktop database"
  fi
else
  warning "update-desktop-database command not found. Desktop entry might not be immediately visible."
fi

# Notify the desktop environment about the new application using DBus
if command_exists dbus-send; then
  info "Notifying desktop environment about new application..."
  dbus-send --session --type=method_call --dest=org.freedesktop.DBus \
    /org/freedesktop/DBus org.freedesktop.DBus.ReloadConfig >/dev/null 2>&1
  
  # Force desktop refresh using file manager commands (covers more desktop environments)
  if command_exists xdg-desktop-menu; then
    xdg-desktop-menu forceupdate &>/dev/null
    success "Desktop menu forced to update"
  fi
else
  warning "dbus-send command not found. Manual desktop refresh may be required."
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
