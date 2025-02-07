#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[*]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check version
check_version() {
    local cmd=$1
    local min_version=$2
    local current_version

    case $cmd in
        "docker")
            current_version=$(docker --version | awk '{print $3}' | tr -d ',')
            ;;
        "docker-compose")
            current_version=$(docker-compose --version | awk '{print $3}' | tr -d ',')
            ;;
        "python3")
            current_version=$(python3 --version | awk '{print $2}')
            ;;
    esac

    if [[ "$current_version" > "$min_version" || "$current_version" == "$min_version" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check sudo privileges
check_sudo() {
    if ! command_exists sudo; then
        print_error "sudo is not installed. Please install sudo first."
        exit 1
    fi
    
    if ! sudo -v; then
        print_error "sudo privileges are required for installation."
        exit 1
    fi
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif command_exists apt-get; then
        echo "debian"
    elif command_exists dnf; then
        echo "rhel"
    else
        echo "unknown"
    fi
}

# Function to check and install Homebrew package
install_brew_package() {
    local package=$1
    local cask=${2:-false}

    if brew list $package &>/dev/null; then
        print_info "$package is already installed, skipping..."
    else
        print_status "Installing $package..."
        if [ "$cask" = true ]; then
            brew install --cask $package
        else
            brew install $package
        fi
    fi
}

# Function to install on macOS
install_macos() {
    print_status "Checking dependencies for macOS..."
    
    # Check if Homebrew is installed
    if ! command_exists brew; then
        print_status "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        print_info "Homebrew is already installed, skipping..."
    fi
    
    # Install dependencies using Homebrew
    install_brew_package "docker" true
    install_brew_package "docker-compose"
    install_brew_package "python3"
    install_brew_package "sshpass"
    
    # Check Docker service
    if ! pgrep -f Docker &>/dev/null; then
        print_status "Starting Docker service..."
        open -a Docker
    else
        print_info "Docker is already running..."
    fi
}

# Function to check and install apt package
install_apt_package() {
    local package=$1
    if dpkg -l | grep -q "^ii  $package "; then
        print_info "$package is already installed, skipping..."
    else
        print_status "Installing $package..."
        sudo apt-get install -y $package
    fi
}

# Function to install on Debian/Ubuntu
install_debian() {
    print_status "Checking dependencies for Debian/Ubuntu..."
    
    # Update package list
    sudo apt-get update
    
    # Install dependencies
    install_apt_package "docker.io"
    install_apt_package "docker-compose"
    install_apt_package "python3"
    install_apt_package "python3-pip"
    install_apt_package "sshpass"
    install_apt_package "git"
        
    # Check Docker service
    if ! systemctl is-active --quiet docker; then
        print_status "Starting Docker service..."
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        print_info "Docker service is already running..."
    fi
    
    # Check docker group
    if ! groups $USER | grep -q "\bdocker\b"; then
        print_status "Adding user to docker group..."
        sudo usermod -aG docker $USER
    else
        print_info "User already in docker group..."
    fi
}

# Function to check and install dnf package
install_dnf_package() {
    local package=$1
    if rpm -q $package &>/dev/null; then
        print_info "$package is already installed, skipping..."
    else
        print_status "Installing $package..."
        sudo dnf -y install $package
    fi
}

# Function to install on RHEL/CentOS/Rocky
install_rhel() {
    print_status "Checking dependencies for RHEL/CentOS/Rocky..."
    
    # Install dependencies
    install_dnf_package "docker"
    install_dnf_package "docker-compose"
    install_dnf_package "python3"
    install_dnf_package "python3-pip"
    install_dnf_package "sshpass"
    install_dnf_package "git"
        
    # Check Docker service
    if ! systemctl is-active --quiet docker; then
        print_status "Starting Docker service..."
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        print_info "Docker service is already running..."
    fi
    
    # Check docker group
    if ! groups $USER | grep -q "\bdocker\b"; then
        print_status "Adding user to docker group..."
        sudo usermod -aG docker $USER
    else
        print_info "User already in docker group..."
    fi
}

# Function to install Ansible
install_ansible() {
    if command_exists ansible; then
        print_info "Ansible is already installed..."
        ansible --version
    else
        print_status "Installing Ansible..."
        python3 -m pip install --user ansible
        
        # Verify Ansible installation
        if command_exists ansible; then
            print_status "Ansible installed successfully!"
            ansible --version
        else
            print_error "Ansible installation failed. Please install manually."
            exit 1
        fi
    fi
}

# Function to check required directories
check_directories() {
    local dirs=("inventory/group_vars" "playbooks")
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            print_status "Creating directory: $dir"
            mkdir -p "$dir"
        else
            print_info "Directory $dir already exists, skipping..."
        fi
    done
}

# Main installation process
main() {
    print_status "Starting installation process..."
    
    # Detect OS
    OS=$(detect_os)
    
    case $OS in
        "macos")
            install_macos
            ;;
        "debian")
            check_sudo
            install_debian
            ;;
        "rhel")
            check_sudo
            install_rhel
            ;;
        *)
            print_error "Unsupported operating system"
            exit 1
            ;;
    esac
    
    # Install Ansible
    install_ansible
    
    # Final setup steps
    print_status "Setting up final configurations..."
    check_directories
    
    print_status "Installation completed successfully!"
    
    # Print status summary
    echo -e "\nStatus Summary:"
    echo "---------------"
    for cmd in docker docker-compose python3 ansible; do
        if command_exists $cmd; then
            echo -e "${GREEN}✓${NC} $cmd is installed"
        else
            echo -e "${RED}✗${NC} $cmd is not installed"
        fi
    done
    
    # Check if user needs to log out
    if groups $USER | grep -q "\bdocker\b"; then
        print_info "Docker group membership is active"
    else
        print_warning "Please log out and log back in for docker group changes to take effect"
    fi
    
    # Check Docker service
    if pgrep -f Docker &>/dev/null || systemctl is-active --quiet docker; then
        print_info "Docker service is running"
    else
        print_warning "Please ensure Docker service is running"
    fi
    
    # Print next steps
    echo -e "\nNext steps:"
    echo "1. Run 'docker-compose up -d' to start the lab environment"
    echo "2. Run 'ansible-playbook playbooks/test.yml' to verify the setup"
}

# Run main installation
main 