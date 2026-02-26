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
  local title="${1:-}"
  echo -e "\n${BOLD}${BLUE}=== $title ===${NC}\n"
}

# Print an info message
info() {
  local msg="${1:-}"
  echo -e "${CYAN}→ ${NC}$msg"
}

# Print a success message
success() {
  local msg="${1:-}"
  echo -e "${GREEN}✓ ${NC}$msg"
}

# Print a warning message
warning() {
  local msg="${1:-}"
  echo -e "${YELLOW}! ${NC}$msg"
}

# Print an error message and exit
error() {
  local msg="${1:-}"
  echo -e "${RED}✗ ERROR: ${NC}$msg" >&2
  exit 1
}

# Display a spinner for background processes
spinner() {
  local pid="${1:-}"
  local message="${2:-}"
  local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local temp
  
  echo -ne "${CYAN}→ ${NC}$message "
  
  while kill -0 "$pid" 2>/dev/null; do
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
  local cmd="${1:-}"
  command -v "$cmd" >/dev/null 2>&1
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
    local pkg="${1:-}"
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
    local pkg="${1:-}"
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
  local pkg_name="${1:-}"
  local pkg_map="${2:-}"
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
  local duration="${1:-0}"
  local msg="${2:-}"
  local steps=20
  local step_duration
  step_duration=$(echo "$duration / $steps" | bc -l)
  
  echo -ne "${CYAN}→ ${NC}$msg ["
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
XDG_UTILS_MAP="arch:xdg-utils:debian:xdg-utils:rpm:xdg-utils"
DESKTOP_FILE_UTILS_MAP="arch:desktop-file-utils:debian:desktop-file-utils:rpm:desktop-file-utils"

# Essential dependencies
check_and_install_package "git"
check_and_install_package "nodejs"
check_and_install_package "npm"
check_and_install_package "xdg-utils" "$XDG_UTILS_MAP"
check_and_install_package "desktop-file-utils" "$DESKTOP_FILE_UTILS_MAP"

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
LOCAL_ICON_PATH="$SCRIPT_ABS_DIR/icon.png"

# Setup icons directory
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
ICONS_DIR="$XDG_DATA_HOME/icons/hicolor/256x256/apps"
mkdir -p "$ICONS_DIR"

# Copy icon to a standard location if it exists
if [[ -f "$LOCAL_ICON_PATH" ]]; then
  info "Installing application icon..."
  cp "$LOCAL_ICON_PATH" "$ICONS_DIR/tiktok.png"
  ICON_NAME="tiktok"
else
  warning "Icon file not found at $LOCAL_ICON_PATH. Desktop entry may display without an icon."
  ICON_NAME="video-x-generic"
fi

# Ensure applications directory exists
APPLICATIONS_DIR="$XDG_DATA_HOME/applications"
info "Ensuring applications directory exists at $APPLICATIONS_DIR"
mkdir -p "$APPLICATIONS_DIR"

# Create desktop file
DESKTOP_FILE_NAME="tiktok-desktop.desktop"
DESKTOP_PATH="$APPLICATIONS_DIR/$DESKTOP_FILE_NAME"

info "Creating desktop entry..."
cat > "$DESKTOP_PATH" << EOF
[Desktop Entry]
Type=Application
Name=TikTok
Comment=Make Your Day
GenericName=Short-form Video Platform
Exec=$EXEC_PATH
Icon=$ICON_NAME
Terminal=false
Categories=Network;Video;Social;InstantMessaging;
Keywords=TikTok;Social Media;Videos;Shorts;Entertainment;
StartupWMClass=TikTok
Version=1.0
EOF

# Set proper permissions for .desktop file (not executable)
chmod 644 "$DESKTOP_PATH"

# Register the desktop file using xdg-desktop-menu
if command_exists xdg-desktop-menu; then
  info "Registering desktop entry with xdg-desktop-menu..."
  xdg-desktop-menu install --mode user "$DESKTOP_PATH"
fi

# Create desktop shortcut using XDG specification
XDG_DESKTOP_DIR="${XDG_DESKTOP_DIR:-$HOME/Desktop}"
if [[ ! -d "$XDG_DESKTOP_DIR" ]]; then
  if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs" ]]; then
    source "${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs"
    XDG_DESKTOP_DIR="${XDG_DESKTOP_DIR:-$HOME/Desktop}"
  fi
fi

if [[ -d "$XDG_DESKTOP_DIR" ]]; then
  info "Creating desktop shortcut in $XDG_DESKTOP_DIR..."
  DESKTOP_SHORTCUT="$XDG_DESKTOP_DIR/$DESKTOP_FILE_NAME"
  cp "$DESKTOP_PATH" "$DESKTOP_SHORTCUT"
  chmod 644 "$DESKTOP_SHORTCUT"
  # Some desktop environments require the executable bit for desktop shortcuts to work
  # but xdg spec says they shouldn't. We'll stick to 644 but note it.
fi

# Update desktop and icon databases
if command_exists update-desktop-database; then
  update-desktop-database "$APPLICATIONS_DIR" &>/dev/null
fi

if command_exists gtk-update-icon-cache; then
  gtk-update-icon-cache -f -t "$XDG_DATA_HOME/icons/hicolor" &>/dev/null || true
fi

# Notify the desktop environment using DBus
if command_exists dbus-send; then
  dbus-send --session --type=method_call --dest=org.freedesktop.DBus \
    /org/freedesktop/DBus org.freedesktop.DBus.ReloadConfig >/dev/null 2>&1
fi

success "Desktop integration complete"

# Setup terminal command
header "Setting Up Terminal Command"

info "Adding terminal command 'tiktok'..."

# Determine shell and config file
SHELL_CONFIG=""
if [[ "${SHELL:-}" == *"zsh"* ]]; then
  SHELL_CONFIG="$HOME/.zshrc"
elif [[ "${SHELL:-}" == *"bash"* ]]; then
  SHELL_CONFIG="$HOME/.bashrc"
fi

if [[ -n "$SHELL_CONFIG" ]]; then
  if ! grep -q "alias tiktok=" "$SHELL_CONFIG"; then
    echo -e "\n# TikTok Desktop Application alias" >> "$SHELL_CONFIG"
    echo "alias tiktok='$SCRIPT_DIR/tiktok.sh'" >> "$SHELL_CONFIG"
    success "Terminal command 'tiktok' added to $SHELL_CONFIG"
  else
    info "Terminal command 'tiktok' already exists"
  fi
fi

# Create a symlink in /usr/local/bin (requires sudo)
if sudo ln -sf "$SCRIPT_DIR/tiktok.sh" /usr/local/bin/tiktok 2>/dev/null; then
  sudo chmod +x /usr/local/bin/tiktok
  success "System-wide 'tiktok' command created"
fi

# Validate installation
header "Validating Installation"

info "Performing post-installation checks..."

if [[ ! -f "main.js" ]]; then
  error "main.js not found. Installation may be corrupted."
fi

if [[ ! -x "tiktok.sh" ]]; then
  error "tiktok.sh not found or not executable."
fi

if [[ ! -d "node_modules" ]]; then
  error "Node modules not installed correctly."
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
