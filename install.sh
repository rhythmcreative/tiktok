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

header() {
  local title="${1:-}"
  echo -e "\n${BOLD}${BLUE}=== $title ===${NC}\n"
}

info() {
  local msg="${1:-}"
  echo -e "${CYAN}→ ${NC}$msg"
}

success() {
  local msg="${1:-}"
  echo -e "${GREEN}✓ ${NC}$msg"
}

warning() {
  local msg="${1:-}"
  echo -e "${YELLOW}! ${NC}$msg"
}

error() {
  local msg="${1:-}"
  echo -e "${RED}✗ ERROR: ${NC}$msg" >&2
  exit 1
}

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
    elif command_exists apt-get; then
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
            install_cmd="sudo apt-get install -y"
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

# Improved mapping function
get_mapped_package() {
    local distro="$1"
    local mapping="$2"
    # Format: "arch:pkg1;debian:pkg2;rpm:pkg3"
    echo "$mapping" | tr ';' '\n' | grep "^$distro:" | cut -d':' -f2
}

check_and_install_package() {
  local pkg_name="${1:-}"
  local pkg_map="${2:-}"
  local pkg=""

  if [[ -n "$pkg_map" ]]; then
      pkg=$(get_mapped_package "$DISTRO" "$pkg_map")
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

start_animation

header "Checking System Compatibility"
detect_distro
success "Running on a $DISTRO-based distribution ($PACKAGE_MANAGER)"

if [[ $EUID -eq 0 ]]; then
  error "This script should not be run as root. Please run as a normal user."
fi

trap 'echo -e "\n${RED}Installation aborted.${NC}"; exit 1' INT TERM

header "Checking System Dependencies"

# Mappings (using semicolon as separator)
DEV_TOOLS_MAP="arch:base-devel;debian:build-essential;rpm:Development Tools"
XDG_UTILS_MAP="arch:xdg-utils;debian:xdg-utils;rpm:xdg-utils"
DESKTOP_FILE_UTILS_MAP="arch:desktop-file-utils;debian:desktop-file-utils;rpm:desktop-file-utils"

check_and_install_package "git"
check_and_install_package "nodejs"
check_and_install_package "npm"
check_and_install_package "xdg-utils" "$XDG_UTILS_MAP"
check_and_install_package "desktop-file-utils" "$DESKTOP_FILE_UTILS_MAP"

if [[ "$DISTRO" == "rpm" ]]; then
    info "Installing Development Tools group..."
    sudo "$PACKAGE_MANAGER" groupinstall -y "Development Tools"
else
    check_and_install_package "build-essential" "$DEV_TOOLS_MAP"
fi

header "Installing Application Dependencies"

if [[ ! -d "node_modules" ]]; then
  info "Installing npm dependencies (this may take a minute)..."
  npm install --no-audit --no-fund --silent & spinner $! "Installing runtime dependencies..."
  
  info "Installing development dependencies..."
  npm install --save-dev electron @electron/packager electron-builder --silent & spinner $! "Installing development dependencies..."
else
  info "Updating dependencies..."
  npm update --silent & spinner $! "Updating dependencies..."
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

header "Creating Launcher Script"
info "Creating tiktok.sh launcher..."
cat > "$SCRIPT_DIR/tiktok.sh" << EOF
#!/bin/bash
cd "$SCRIPT_DIR" || exit 1
export PATH=\$PATH:/usr/local/bin:/usr/bin
npm start
EOF
chmod +x "$SCRIPT_DIR/tiktok.sh"
success "Launcher created"

header "Setting Up Desktop Integration"
SCRIPT_ABS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
EXEC_PATH="$SCRIPT_ABS_DIR/tiktok.sh"
LOCAL_ICON_PATH="$SCRIPT_ABS_DIR/icon.png"

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
APPLICATIONS_DIR="$XDG_DATA_HOME/applications"
mkdir -p "$APPLICATIONS_DIR"

if command_exists xdg-icon-resource && [[ -f "$LOCAL_ICON_PATH" ]]; then
  info "Registering application icon..."
  # Use tiktok-tiktok to avoid 'unbound vendor prefix' error in Debian/Ubuntu
  xdg-icon-resource install --context apps --size 256 "$LOCAL_ICON_PATH" tiktok-tiktok
  ICON_NAME="tiktok-tiktok"
else
  info "Using local path for icon..."
  ICON_NAME="$LOCAL_ICON_PATH"
fi

DESKTOP_FILE_NAME="tiktok-desktop.desktop"
TMP_DESKTOP_FILE="$SCRIPT_ABS_DIR/$DESKTOP_FILE_NAME"

info "Creating desktop entry..."
cat > "$TMP_DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=TikTok
Comment=TikTok Desktop Application
GenericName=Social Media Client
Exec="$EXEC_PATH"
Icon=$ICON_NAME
Terminal=false
Categories=Network;AudioVideo;
Keywords=TikTok;Social;Media;Videos;Shorts;
StartupWMClass=TikTok
Version=1.0
EOF
chmod 644 "$TMP_DESKTOP_FILE"

if command_exists xdg-desktop-menu; then
  info "Installing menu entry..."
  xdg-desktop-menu install --mode user "$TMP_DESKTOP_FILE"
  success "Menu entry installed"
else
  cp "$TMP_DESKTOP_FILE" "$APPLICATIONS_DIR/$DESKTOP_FILE_NAME"
fi

if command_exists update-desktop-database; then
  update-desktop-database "$APPLICATIONS_DIR" &>/dev/null || true
fi

header "Finalizing"
info "Setting up terminal alias..."
SHELL_CONFIG=""
if [[ "${SHELL:-}" == *"zsh"* ]]; then SHELL_CONFIG="$HOME/.zshrc"
elif [[ "${SHELL:-}" == *"bash"* ]]; then SHELL_CONFIG="$HOME/.bashrc"
fi

if [[ -n "$SHELL_CONFIG" ]] && ! grep -q "alias tiktok=" "$SHELL_CONFIG"; then
    echo -e "\n# TikTok Alias\nalias tiktok='$SCRIPT_DIR/tiktok.sh'" >> "$SHELL_CONFIG"
    success "Alias added to $SHELL_CONFIG"
fi

header "Installation Complete"
echo -e "${GREEN}TikTok Desktop se ha instalado correctamente.${NC}"
echo -e "Si el icono no aparece, intenta reiniciar tu sesión."

exit 0
