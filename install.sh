#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for browser dependencies
check_browser_dependencies() {
    print_info "Checking for browser dependencies..."
    
    if command_exists chromium; then
        print_success "Chromium is installed."
        BROWSER_FOUND="true"
    elif command_exists google-chrome; then
        print_success "Google Chrome is installed."
        BROWSER_FOUND="true"
    elif command_exists firefox; then
        print_success "Firefox is installed."
        BROWSER_FOUND="true"
    else
        print_info "No compatible browser found (Chromium, Google Chrome, or Firefox)."
        print_info "The app will only work in Electron mode unless a browser is installed."
        BROWSER_FOUND="false"
    fi
}

# Check if running on Arch Linux
check_arch_linux() {
    if [ -f /etc/arch-release ]; then
        return 0
    else
        print_error "This script is designed for Arch Linux."
        print_info "You might need to manually install dependencies for your distribution."
        return 1
    fi
}

# Check and install Node.js and npm
install_nodejs() {
    print_info "Checking for Node.js and npm..."
    
    if command_exists node && command_exists npm; then
        print_success "Node.js and npm are already installed."
        print_info "Node version: $(node -v)"
        print_info "npm version: $(npm -v)"
    else
        print_info "Installing Node.js and npm..."
        if sudo pacman -Sy --noconfirm nodejs npm; then
            print_success "Node.js and npm have been installed successfully."
        else
            print_error "Failed to install Node.js and npm. Please install them manually."
            exit 1
        fi
    fi
}

# Install npm dependencies
install_npm_dependencies() {
    print_info "Installing npm dependencies..."
    
    # Navigate to the TikTok directory
    cd "$(dirname "$0")"
    
    if npm install; then
        print_success "npm dependencies installed successfully."
    else
        print_error "Failed to install npm dependencies."
        exit 1
    fi
}

# Setup desktop integration
setup_desktop_integration() {
    print_info "Setting up desktop integration..."
    
    # Create necessary directories if they don't exist
    if ! sudo mkdir -p /usr/local/bin; then
        print_error "Failed to create /usr/local/bin directory."
        exit 1
    fi
    
    if ! mkdir -p ~/.local/share/applications; then
        print_error "Failed to create ~/.local/share/applications directory."
        exit 1
    fi
    
    # Get the full path to the TikTok directory
    APP_DIR="$(cd "$(dirname "$0")" && pwd)"
    
    # Create the improved TikTok launch script
    print_info "Creating TikTok launch script..."
    
    # Write the launch script content to /usr/local/bin/tiktok
    if ! sudo bash -c "cat > /usr/local/bin/tiktok" << 'EOL'
#!/bin/bash

# Try to launch TikTok in a standalone browser window first
if command -v chromium &> /dev/null; then
    chromium --app="https://www.tiktok.com/" --new-window --profile-directory=TikTok
    exit $?
elif command -v google-chrome &> /dev/null; then
    google-chrome --app="https://www.tiktok.com/" --new-window --profile-directory=TikTok
    exit $?
elif command -v firefox &> /dev/null; then
    firefox --new-instance --kiosk "https://www.tiktok.com/"
    exit $?
fi

# If we reach here, try to launch the Electron app
if [ -d "${APP_DIR}" ]; then
    cd "${APP_DIR}" || exit 1
    if [ -f "package.json" ]; then
        npm start
        exit $?
    else
        echo "Error: package.json not found in TikTok directory"
        exit 1
    fi
else
    echo "Error: TikTok directory not found at ${APP_DIR}"
    echo "No compatible browser found and TikTok directory is missing."
    exit 1
fi
EOL
    then
        print_error "Failed to create the launch script."
        exit 1
    fi
    
    # Fix the path in the script to use the full application path
    if ! sudo sed -i "s|\${APP_DIR}|${APP_DIR}|g" /usr/local/bin/tiktok; then
        print_error "Failed to update the application path in the launch script."
        exit 1
    fi
    
    # Make the script executable
    if ! sudo chmod +x /usr/local/bin/tiktok; then
        print_error "Failed to make the script executable."
        exit 1
    fi
    
    # Update the desktop file with correct icon path
    if ! sed -i "s|Icon=.*|Icon=${APP_DIR}/icon.png|g" "$APP_DIR/tiktok.desktop"; then
        print_error "Failed to update icon path in desktop file."
        exit 1
    fi
    
    # Copy the desktop entry file
    if ! cp "$APP_DIR/tiktok.desktop" ~/.local/share/applications/; then
        print_error "Failed to copy desktop entry file."
        exit 1
    fi
    
    # Update desktop database
    if command_exists update-desktop-database; then
        if ! update-desktop-database ~/.local/share/applications; then
            print_error "Failed to update desktop database."
            # Not critical, so don't exit
        fi
    fi
    
    print_success "Desktop integration completed successfully."
}

# Main installation process
main() {
    print_info "Starting TikTok desktop application installation..."
    
    # Check if running on Arch Linux
    check_arch_linux || exit 1
    
    # Check for browser dependencies
    check_browser_dependencies
    
    # Install Node.js and npm
    install_nodejs
    
    # Install npm dependencies
    install_npm_dependencies
    
    # Setup desktop integration
    setup_desktop_integration
    
    print_success "TikTok desktop application has been installed successfully!"
    print_info "You can now launch TikTok from your application menu or by typing 'tiktok' in terminal."
    
    if [ "$BROWSER_FOUND" = "false" ]; then
        print_info "Note: No web browsers were detected. TikTok will run in Electron mode only."
        print_info "Install Chromium, Google Chrome, or Firefox for web app functionality."
    fi
}

# Run the main function
main
