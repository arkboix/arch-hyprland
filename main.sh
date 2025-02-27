#!/usr/bin/env bash

# WARNING: DON'T EDIT IF YOU DON'T KNOW WHATCHA DOING!
# This script installs and configures dotfiles for Hyprland setup
# It's meant to be modifiable, but proceed with caution

set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Variables
DOTFILES_REPO="https://github.com/arkboix/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Directories to backup
BACKUP_FOLDERS=(
    ".config/hypr"
    ".config/waybar"
    ".config/rofi"
    ".config/kitty"
    "arkscripts"
    ".config/mako"
    ".config/nwg-wrapper"
    ".zshrc"
    ".config/wlogout"
)

# Required packages to run the script
SCRIPT_REQUIRED=("git" "stow" "curl")

# Default packages to install
DEFAULT_PACKAGES=(
    "yay"
)

# Hyprland and related packages
HYPR_PACKAGES=(
    "hyprland"
    "hyprlock"
    "hypridle"
    "hyprpaper"
    "hyprsunset"
    "waybar"
    "rofi-wayland"
    "nwg-wrapper"
    "kitty"
    "zsh"
    "wlogout"
    "mako"
    "hyprgui"
    "zenity"
    "nwg-displays"
    "ttf-font-awesome"
    "ttf-ibm-plex"
    "ttf-ibmplex-mono-nerd"
)

# Helper functions
print_header() {
    echo -e "\n${BOLD}${BLUE}$1${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Backup existing configuration
backup_configs() {
    print_header "Backing up existing configurations"

    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        print_success "Created backup directory: $BACKUP_DIR"
    fi

    for dir in "${BACKUP_FOLDERS[@]}"; do
        # Handle files and directories
        if [[ -e "$HOME/$dir" ]]; then
            # Create necessary parent directories
            parent_dir=$(dirname "$BACKUP_DIR/$dir")
            mkdir -p "$parent_dir"

            # Copy the file/directory
            cp -r "$HOME/$dir" "$BACKUP_DIR/$dir"
            print_success "Backed up ~/$dir"
        else
            print_warning "~/$dir does not exist, skipping backup"
        fi
    done
}

# Install pacman packages
install_pacman_packages() {
    local packages=("$@")
    print_header "Installing packages with pacman: ${packages[*]}"
    sudo pacman -S --needed "${packages[@]}"
}

# Install packages using yay
install_yay_packages() {
    local packages=("$@")
    print_header "Installing packages with yay: ${packages[*]}"
    yay -S --needed "${packages[@]}"
}

# Install required packages
install_packages() {
    print_header "Installing required packages"

    # Check if pacman is available
    if ! command_exists pacman; then
        print_error "Pacman package manager not found. This script expects Arch-based distro."
        exit 1
    fi

    # Install script requirements first
    install_pacman_packages "${SCRIPT_REQUIRED[@]}"

    # Install basic required packages
    print_header "Installing yay AUR helper"
    if ! command_exists yay; then
        install_pacman_packages "${DEFAULT_PACKAGES[@]}"
    else
        print_success "yay is already installed"
    fi

    # Ask for confirmation to install Hyprland packages
    echo -e "\n${BOLD}The following packages will be installed using yay:${NC}"
    for package in "${HYPR_PACKAGES[@]}"; do
        echo "  - $package"
    done

    read -p "Proceed with installation? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
        print_warning "Hyprland package installation skipped"
        return
    fi

    # Install Hyprland packages
    install_yay_packages "${HYPR_PACKAGES[@]}"

    # Ask for additional packages
    echo -e "\n${BOLD}What additional packages do you want to install?${NC}"
    echo "Separate items with a space. The script will verify each package exists."
    read -p "> " additional_packages_input

    if [[ ! -z "$additional_packages_input" ]]; then
        # Convert the input string to an array
        IFS=' ' read -ra additional_packages <<< "$additional_packages_input"

        # Verify packages exist
        valid_packages=()
        for package in "${additional_packages[@]}"; do
            echo -n "Checking if package '$package' exists... "
            if yay -Ss "^$package$" > /dev/null 2>&1; then
                echo -e "${GREEN}exists${NC}"
                valid_packages+=("$package")
            else
                echo -e "${RED}not found${NC}"
            fi
        done

        # Install additional packages if any valid ones found
        if [[ ${#valid_packages[@]} -gt 0 ]]; then
            install_yay_packages "${valid_packages[@]}"
        fi
    fi
}

# Clone dotfiles repository
clone_dotfiles() {
    print_header "Setting up dotfiles"

    if [[ -d "$DOTFILES_DIR" ]]; then
        print_warning "Dotfiles directory already exists"
        read -p "Do you want to remove it and clone again? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Removing existing dotfiles directory"
            rm -rf "$DOTFILES_DIR"
        else
            print_warning "Using existing dotfiles directory"
            return
        fi
    fi

    print_header "Cloning dotfiles repository"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    print_success "Dotfiles cloned to $DOTFILES_DIR"
}

# Stow configurations
stow_configs() {
    print_header "Stowing configuration files"

    # Change to dotfiles directory
    cd "$DOTFILES_DIR"

    # List available configurations
    available_configs=()
    for dir in */; do
        config=${dir%/}
        available_configs+=("$config")
    done

    echo -e "${BOLD}Available configurations:${NC}"
    for i in "${!available_configs[@]}"; do
        echo "  $((i+1)). ${available_configs[$i]}"
    done

    # Ask which configurations to stow
    echo -e "\n${BOLD}Which configurations would you like to stow?${NC}"
    echo "Options: all, none, or numbers separated by spaces (e.g., 1 3 4)"
    read -p "> " stow_choice

    selected_configs=()

    if [[ "$stow_choice" == "all" ]]; then
        selected_configs=("${available_configs[@]}")
    elif [[ "$stow_choice" != "none" ]]; then
        # Parse numbers
        IFS=' ' read -ra selected_numbers <<< "$stow_choice"
        for num in "${selected_numbers[@]}"; do
            if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#available_configs[@]} )); then
                selected_configs+=("${available_configs[$num-1]}")
            fi
        done
    fi

    # Stow selected configurations
    if [[ ${#selected_configs[@]} -gt 0 ]]; then
        for config in "${selected_configs[@]}"; do
            echo -e "Stowing ${BOLD}$config${NC}..."
            stow -v -t "$HOME" "$config"
            print_success "$config stowed successfully"
        done
    else
        print_warning "No configurations selected for stowing"
    fi
}

# Run post-installation steps
post_installation() {
    print_header "Running post-installation steps"

    # Make sure arkscripts directory exists
    if [[ -d "$HOME/arkscripts" ]]; then
        print_success "arkscripts directory found"
        cd "$HOME/arkscripts"

        # Make scripts executable
        chmod +x *.sh
        print_success "Made scripts executable"

        # Run waybar color script
        if [[ -f "./waybar-color.sh" ]]; then
            ./waybar-color.sh
            print_success "Ran waybar-color.sh"
        else
            print_error "waybar-color.sh not found"
        fi
    else
        print_error "arkscripts directory not found. Post-installation steps incomplete."
    fi

    # Create wlogout symbolic link
    print_header "Setting up wlogout background"
    if [[ -d "$HOME/wallpapers" && -f "$HOME/wallpapers/wlogout.jpg" ]]; then
        ln -sf "$HOME/wallpapers/wlogout.jpg" "/tmp/wlogout.jpg"
        print_success "Created wlogout wallpaper symlink"
    else
        print_warning "Wallpaper for wlogout not found. Create ~/wallpapers/wlogout.jpg manually."
    fi
}

# Main function
main() {
    print_header "Dotfiles Installation Script"
    echo -e "${YELLOW}WARNING: DON'T EDIT IF YOU DON'T KNOW WHATCHA DOING!${NC}"

    # Check for stow
    if ! command_exists stow; then
        print_error "GNU Stow is not installed. Installing it first..."
        sudo pacman -S --needed stow
    fi

    # Installation steps
    install_packages
    clone_dotfiles
    backup_configs
    stow_configs
    post_installation

    print_header "Installation Complete!"
    echo -e "Your dotfiles have been installed. A backup of your previous configurations can be found at: ${BOLD}$BACKUP_DIR${NC}"
    echo -e "If you encounter any issues, please visit: ${BOLD}https://github.com/arkboix/dotfiles${NC}"
}

# Run the script
main
