#!/bin/bash
# Enhanced version of Arkboi's Dotfiles Installation Script
# Original: https://github.com/arkboix/dotfiles
# https://github.com/arkboix/arch-hyprland

set -e  # Exit script on any error

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Backup dir
BACKUP_DIR="$HOME/arkboi-dots-backup-$(date +%Y%m%d-%H%M%S)"

# Function for printing colorful messages
print_msg() {
    echo -e "${2:-$BLUE}$1${NC}"
}

print_header() {
    echo -e "\n${PURPLE}===== $1 =====${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

# Check if running as root, which we don't want
if [ "$EUID" -eq 0 ]; then
    print_error "Please don't run this script as root!"
    exit 1
fi

# Function to check if commands are available
check_command() {
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            return 1
        fi
    done
    return 0
}

# Install required packages for script visuals if needed
install_visual_dependencies() {
    print_msg "Installing visual dependencies..."
    case "$DISTRO" in
        "arch")
            sudo pacman --needed --noconfirm -S figlet lolcat
            ;;
        "debian"|"ubuntu")
            sudo apt-get update
            sudo apt-get install -y figlet lolcat
            ;;
        "fedora")
            sudo dnf install -y figlet lolcat
            ;;
        "opensuse")
            sudo zypper install -y figlet lolcat
            ;;
    esac
}

# Display ASCII art header with distro detection
display_header() {
    if check_command figlet lolcat; then
        figlet "Arkboi's DOTS" | lolcat
    else
        echo "==============================================="
        echo "             ARKBOI'S DOTFILES"
        echo "==============================================="
    fi
    echo "Installing customized dotfiles for $(whoami) on $DISTRO"
}

# Check package manager and detect distro
detect_distro() {
    if command -v pacman &>/dev/null; then
        DISTRO="arch"
        PKG_MANAGER="pacman"
        PKG_INSTALL="sudo pacman -S --needed --noconfirm"
    elif command -v apt-get &>/dev/null; then
        DISTRO="debian"
        if grep -q "Ubuntu" /etc/os-release; then
            DISTRO="ubuntu"
        fi
        PKG_MANAGER="apt"
        PKG_INSTALL="sudo apt-get install -y"
    elif command -v dnf &>/dev/null; then
        DISTRO="fedora"
        PKG_MANAGER="dnf"
        PKG_INSTALL="sudo dnf install -y"
    elif command -v zypper &>/dev/null; then
        DISTRO="opensuse"
        PKG_MANAGER="zypper"
        PKG_INSTALL="sudo zypper install -y"
    else
        print_error "Unsupported distribution! This script supports Arch, Debian/Ubuntu, Fedora, and openSUSE."
        exit 1
    fi
}

# Function to ask for confirmation
confirm() {
    while true; do
        read -p "$(echo -e "${YELLOW}$1 [y/n]:${NC} ")" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Prompt user to choose distro manually or use auto-detection
choose_distro() {
    detect_distro
    print_header "Distribution Detection"
    print_msg "Detected distribution: $DISTRO"

    if confirm "Would you like to override this detection?"; then
        echo
        echo "Please select your distribution:"
        echo "1) Arch Linux"
        echo "2) Debian"
        echo "3) Ubuntu"
        echo "4) Fedora"
        echo "5) openSUSE"

        while true; do
            read -p "Enter your choice (1-5): " choice
            case $choice in
                1)
                    DISTRO="arch"
                    PKG_MANAGER="pacman"
                    PKG_INSTALL="sudo pacman -S --needed --noconfirm"
                    break
                    ;;
                2)
                    DISTRO="debian"
                    PKG_MANAGER="apt"
                    PKG_INSTALL="sudo apt-get install -y"
                    break
                    ;;
                3)
                    DISTRO="ubuntu"
                    PKG_MANAGER="apt"
                    PKG_INSTALL="sudo apt-get install -y"
                    break
                    ;;
                4)
                    DISTRO="fedora"
                    PKG_MANAGER="dnf"
                    PKG_INSTALL="sudo dnf install -y"
                    break
                    ;;
                5)
                    DISTRO="opensuse"
                    PKG_MANAGER="zypper"
                    PKG_INSTALL="sudo zypper install -y"
                    break
                    ;;
                *)
                    print_error "Invalid choice. Please select a number from 1 to 5."
                    ;;
            esac
        done
        print_success "Using $DISTRO for installation."
    fi

    # Install visual dependencies after distro selection
    install_visual_dependencies
    display_header
}

# Define package lists based on distribution
define_packages() {
    # Core packages needed for the script to function
    SCRIPT_PACKAGES=(
        "git"
        "stow"
        "curl"
    )

    # Base packages common to all distributions (with fallbacks)
    PACKAGES=(
        "zsh"
        "emacs"
    )

    # Define AUR packages (only for Arch)
    AUR_PACKAGES=()

    # Additional packages based on distribution
    case "$DISTRO" in
        "arch")
            PACKAGES+=(
                "hyprland"
                "hyprlock"
                "hypridle"
                "python-pywal"
                "hyprcursor"
                "wlogout"
                "nwg-wrapper"
                "waybar"
                "rofi-wayland"
                "kitty"
                "swww"
                "waypaper"
                "yad"
                "ttf-font-awesome"
                "ttf-jetbrains-mono"
                "ttf-jetbrains-mono-nerd"
                "ttf-fira-sans"
                "ttf-ibm-plex"
                "light"
                "brightnessctl"
                "zenity"
                "thunar"
                "mako"
                "nwg-displays"
                "starship"
                "ttf-ibmplex-mono-nerd"
                "hyprshot"
                "pipewire-pulse"
            )

            AUR_PACKAGES=(
                "pokeget"
                "hyprgui"
            )
            ;;

        "debian"|"ubuntu")
            PACKAGES+=(
                "kitty"
                "rofi"
                "thunar"
                "brightnessctl"
                "zenity"
                "python3-pip"
                "fonts-font-awesome"
                "fonts-firacode"
                "pipewire-pulse"
            )
            ;;

        "fedora")
            PACKAGES+=(
                "kitty"
                "rofi"
                "thunar"
                "brightnessctl"
                "zenity"
                "python3-pip"
                "fontawesome-fonts"
                "fira-code-fonts"
                "pipewire-pulseaudio"
                "starship"
            )
            ;;

        "opensuse")
            PACKAGES+=(
                "kitty"
                "rofi"
                "thunar"
                "zenity"
                "python3-pip"
                "pipewire-pulseaudio"
            )
            ;;
    esac

    # Allow user to add additional packages
    print_header "Additional Packages"
    if confirm "Would you like to add additional packages?"; then
        echo "Enter additional packages to install, separated by spaces:"
        read -r additional_packages
        for pkg in $additional_packages; do
            EXTRA_PACKAGES+=("$pkg")
        done
        if [ ${#EXTRA_PACKAGES[@]} -gt 0 ]; then
            print_success "Added ${#EXTRA_PACKAGES[@]} additional packages"
        fi
    fi

    # Configuration files to backup and replace
    FILES=(
        "$HOME/arkscripts"
        "$HOME/.config/hypr"
        "$HOME/.config/waybar"
        "$HOME/.doom.d"
        "$HOME/.config/kitty"
        "$HOME/.config/mako"
        "$HOME/.config/nwg-wrapper"
        "$HOME/.config/rofi"
        "$HOME/wallpapers"
        "$HOME/.config/wlogout"
        "$HOME/.config/starship.toml"
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.zshrc-personal"
        "$HOME/.config/wal"
        "$HOME/.config/nwg-dock-hyprland"
    )
}

# Install required script packages
install_script_packages() {
    print_header "Installing Script Dependencies"

    MISSING_SCRIPT_PACKAGES=()
    for pkg in "${SCRIPT_PACKAGES[@]}"; do
        if ! command -v "$pkg" &>/dev/null; then
            MISSING_SCRIPT_PACKAGES+=("$pkg")
        fi
    done

    if [ ${#MISSING_SCRIPT_PACKAGES[@]} -gt 0 ]; then
        print_msg "Installing required script packages: ${MISSING_SCRIPT_PACKAGES[*]}"
        case "$DISTRO" in
            "arch")
                sudo pacman -S --needed --noconfirm "${MISSING_SCRIPT_PACKAGES[@]}"
                ;;
            "debian"|"ubuntu")
                sudo apt-get update
                sudo apt-get install -y "${MISSING_SCRIPT_PACKAGES[@]}"
                ;;
            "fedora")
                sudo dnf install -y "${MISSING_SCRIPT_PACKAGES[@]}"
                ;;
            "opensuse")
                sudo zypper install -y "${MISSING_SCRIPT_PACKAGES[@]}"
                ;;
        esac
    else
        print_success "All script dependencies are already installed."
    fi
}

# Install AUR helper for Arch
install_aur_helper() {
    if [ "$DISTRO" == "arch" ]; then
        if ! command -v yay &>/dev/null; then
            print_header "Installing AUR Helper"
            cd "$HOME" || exit
            rm -rf yay  # Remove any existing yay directory to avoid conflicts
            sudo pacman -S --needed --noconfirm git base-devel
            git clone https://aur.archlinux.org/yay.git
            cd yay || exit
            makepkg -si --noconfirm
            cd "$HOME" || exit
            rm -rf yay  # Cleanup
            print_success "Yay installed successfully"
        else
            print_success "AUR helper (yay) is already installed."
        fi
    fi
}

# Function to install packages based on the detected distribution
install_packages() {
    print_header "Installing Packages"

    # Install packages
    print_msg "Installing main packages..."
    case "$DISTRO" in
        "arch")
            yay -S --needed --noconfirm "${PACKAGES[@]}" "${EXTRA_PACKAGES[@]}"

            # Install AUR packages
            print_msg "Installing AUR packages..."
            for pkg in "${AUR_PACKAGES[@]}"; do
                echo "Installing $pkg..."
                yay -S --needed --noconfirm "$pkg" || print_warning "Failed to install $pkg, continuing..."
            done
            ;;

        "debian"|"ubuntu")
            sudo apt-get update
            sudo apt-get install -y "${PACKAGES[@]}" "${EXTRA_PACKAGES[@]}"
            ;;

        "fedora")
            sudo dnf install -y "${PACKAGES[@]}" "${EXTRA_PACKAGES[@]}"
            ;;

        "opensuse")
            sudo zypper install -y "${PACKAGES[@]}" "${EXTRA_PACKAGES[@]}"
            ;;
    esac

    print_success "Package installation completed"
}

# Non-Arch specific package installations
install_non_arch_packages() {
    if [ "$DISTRO" != "arch" ]; then
        print_header "Installing Distribution-Specific Packages"

        # Install starship if not available
        if ! command -v starship &>/dev/null; then
            print_msg "Installing Starship prompt..."
            curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi

        # Install Hyprland if not Arch (may need extra steps)
        if ! command -v Hyprland &>/dev/null; then
            print_msg "Setting up Hyprland..."
            case "$DISTRO" in
                "debian"|"ubuntu")
                    # Check if Hyprland is available in repos, otherwise build from source
                    if apt-cache show hyprland &>/dev/null; then
                        sudo apt-get install -y hyprland
                    else
                        print_warning "Hyprland not found in repositories. Consider building from source: https://github.com/hyprwm/Hyprland/wiki/Installation"
                    fi
                    ;;
                "fedora")
                    sudo dnf copr enable solopasha/hyprland
                    sudo dnf install -y hyprland
                    ;;
                "opensuse")
                    print_warning "For openSUSE, please follow the manual installation instructions for Hyprland: https://github.com/hyprwm/Hyprland/wiki/Installation"
                    ;;
            esac
        fi

        # Install waybar if not available
        if ! command -v waybar &>/dev/null; then
            print_msg "Setting up Waybar..."
            case "$DISTRO" in
                "debian"|"ubuntu")
                    sudo apt-get install -y waybar
                    ;;
                "fedora")
                    sudo dnf install -y waybar
                    ;;
                "opensuse")
                    sudo zypper install -y waybar
                    ;;
            esac
        fi
    fi
}

# Install DOOM Emacs
install_doom_emacs() {
    print_header "Installing DOOM Emacs"

    if confirm "Do you want to install DOOM Emacs?"; then
        if [ -d "$HOME/.emacs.d" ]; then
            if confirm "Existing Emacs configuration detected. Do you want to back it up and reinstall DOOM?"; then
                mv "$HOME/.emacs.d" "$BACKUP_DIR/.emacs.d.bak"
            else
                print_msg "Skipping DOOM Emacs installation."
                return
            fi
        fi

        print_msg "Installing DOOM Emacs..."
        git clone https://github.com/doomemacs/doomemacs.git ~/.emacs.d/
        ~/.emacs.d/bin/doom install

        print_success "DOOM Emacs installed successfully."
    else
        print_msg "Skipping DOOM Emacs installation."
    fi
}

# Function to clone and set up dotfiles repository
setup_dotfiles() {
    print_header "Setting Up Dotfiles Repository"

    # Clone repo or allow custom repo
    if confirm "Would you like to use the default dotfiles from arkboix?"; then
        DOTFILES_REPO="https://github.com/arkboix/dotfiles.git"
    else
        echo "Enter your custom dotfiles repository URL:"
        read -r DOTFILES_REPO
    fi

    # Clone the repository
    if [ -d "$HOME/dotfiles" ]; then
        if confirm "Existing dotfiles found. Move to ~/.dotfiles_old?"; then
            mkdir -p "$HOME/.dotfiles_old"
            mv "$HOME/dotfiles" "$HOME/.dotfiles_old"
        else
            print_error "Cannot continue without moving existing dotfiles. Aborting."
            exit 1
        fi
    fi

    print_msg "Cloning dotfiles repository..."
    git clone "$DOTFILES_REPO" "$HOME/dotfiles" || {
        print_error "Failed to clone repository. Please check the URL and your internet connection."
        exit 1
    }

    print_success "Dotfiles repository cloned successfully."
}

# Backup existing configurations
backup_configurations() {
    print_header "Backing Up Existing Configurations"

    print_msg "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"

    for FILE in "${FILES[@]}"; do
        if [ -e "$FILE" ]; then
            print_msg "Backing up $FILE"
            backup_path="$BACKUP_DIR/$(basename "$FILE")"
            mkdir -p "$(dirname "$backup_path")"
            cp -r "$FILE" "$backup_path"
        fi
    done

    print_success "Backup completed. Files saved to $BACKUP_DIR"
}

# Apply dotfiles using stow
apply_dotfiles() {
    print_header "Applying Dotfiles"

    cd "$HOME/dotfiles" || {
        print_error "Failed to change to dotfiles directory."
        exit 1
    }

    print_msg "Applying dotfiles using Stow..."

    # Check which directories exist before attempting to stow them
    STOW_DIRS=()
    for DIR in hypr wal dunst nwg-dock-hyprland waybar kitty mako wlogout nwg-wrapper doom arkscripts starship rofi wallpapers zsh; do
        if [ -d "$DIR" ] || [ -f "$DIR" ]; then
            STOW_DIRS+=("$DIR")
        else
            print_warning "Skipping $DIR, directory not found."
        fi
    done

    # Apply configurations with stow
    for DIR in "${STOW_DIRS[@]}"; do
        print_msg "Stowing $DIR..."
        stow -v -t ~ "$DIR" || print_warning "Stow failed for $DIR"
    done

    print_success "Dotfiles applied successfully."
}

# Function to get additional wallpapers
get_additional_wallpapers() {
    print_header "Additional Wallpapers"

    if confirm "Would you like to download additional wallpapers from arkboix's collection?"; then
        print_msg "Downloading additional wallpapers..."

        # Create a temporary directory
        tmp_dir=$(mktemp -d)

        # Clone the wallpapers repository
        git clone https://github.com/arkboix/wallpapers.git "$tmp_dir/wallpapers" || {
            print_error "Failed to clone wallpapers repository."
            rm -rf "$tmp_dir"
            return 1
        }

        # Create wallpapers directory if it doesn't exist
        mkdir -p "$HOME/wallpapers"

        # Move all wallpapers to the user's wallpapers directory
        print_msg "Copying wallpapers to $HOME/wallpapers..."

        # Count the number of new wallpapers
        wallpaper_count=$(find "$tmp_dir/wallpapers" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | wc -l)

        # Move all wallpapers
        find "$tmp_dir/wallpapers" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) -exec cp {} "$HOME/wallpapers/" \;

        # Clean up
        rm -rf "$tmp_dir"

        print_success "Added $wallpaper_count additional wallpapers to your collection."

        # Ask if user wants to select from the new wallpapers
        if confirm "Would you like to browse the wallpapers now?"; then
            # Check if we have any GUI file manager available
            if command -v thunar &>/dev/null; then
                thunar "$HOME/wallpapers" &
            elif command -v nautilus &>/dev/null; then
                nautilus "$HOME/wallpapers" &
            elif command -v dolphin &>/dev/null; then
                dolphin "$HOME/wallpapers" &
            else
                print_warning "No GUI file manager found. You can browse the wallpapers at $HOME/wallpapers"
            fi
        fi
    else
        print_msg "Skipping additional wallpapers."
    fi
}

# Post-installation tasks
post_installation() {
    print_header "Post-Installation Tasks"

    # Download additional wallpapers
    get_additional_wallpapers

    # Reload configurations if services are running
    print_msg "Reloading configurations..."
    if pgrep -x "Hyprland" > /dev/null; then
        hyprctl reload || print_warning "Hyprland reload failed"
    else
        print_msg "Hyprland is not running, skipping reload"
    fi

    if pgrep -x "waybar" > /dev/null; then
        pkill -SIGUSR2 waybar || print_warning "Waybar reload failed"
    else
        print_msg "Waybar is not running, skipping reload"
    fi

    # Set ZSH as default shell
    if [ "$SHELL" != "/bin/zsh" ]; then
        print_msg "Changing default shell to ZSH..."
        if confirm "Would you like to set ZSH as your default shell?"; then
            chsh -s /bin/zsh || {
                print_warning "Failed to change shell automatically."
                print_msg "Run this command manually after installation: chsh -s /bin/zsh"
            }
        fi
    else
        print_success "ZSH is already your default shell."
    fi

    # Configure pywal and set wallpaper
    if confirm "Would you like to set up wallpaper and theme now?"; then
        # Try to start swww daemon if it exists
        if command -v swww &>/dev/null; then
            print_msg "Starting SWWW daemon..."
            pkill swww || true
            sleep 1
            swww-daemon &
            sleep 2

            if [ -f "$HOME/wallpapers/polarlights3.jpg" ]; then
                print_msg "Setting wallpaper..."
                swww img "$HOME/wallpapers/polarlights3.jpg" &
            elif [ -d "$HOME/wallpapers" ] && [ "$(ls -A "$HOME/wallpapers")" ]; then
                # Pick first wallpaper in directory
                wallpaper=$(find "$HOME/wallpapers" -type f \( -name "*.jpg" -o -name "*.png" \) | head -n 1)
                if [ -n "$wallpaper" ]; then
                    print_msg "Setting wallpaper to $wallpaper..."
                    swww img "$wallpaper" &
                fi
            fi
        else
            print_warning "swww not found. Wallpaper will need to be set manually."
        fi

        # Run pywal if available
        if command -v wal &>/dev/null && [ -f "$HOME/arkscripts/wal.sh" ]; then
            print_msg "Setting up pywal color scheme..."
            bash "$HOME/arkscripts/wal.sh"
        fi
    fi
}

# Main installation function
main() {
    # Check sudo access
    if ! command -v sudo &>/dev/null; then
        print_error "Error: sudo is not installed. Please install sudo first."
        exit 1
    fi

    # Keep sudo active
    sudo -v

    # Welcome message
    clear
    echo "Welcome to the enhanced dotfiles installation script!"
    echo "This script will help you set up a customized desktop environment."
    echo

    # Choose distro
    choose_distro

    # Define packages
    define_packages

    # Show installation plan
    print_header "Installation Plan"
    echo "The script will perform the following actions:"
    echo "1. Install required dependencies"
    echo "2. Set up package managers"
    echo "3. Install ${#PACKAGES[@]} packages and ${#EXTRA_PACKAGES[@]} extra packages"
    if [ "$DISTRO" == "arch" ]; then
        echo "4. Install ${#AUR_PACKAGES[@]} AUR packages"
    fi
    echo "5. Install DOOM Emacs (optional)"
    echo "6. Set up dotfiles"
    echo "7. Back up existing configurations"
    echo "8. Apply new configurations"
    echo "9. Download additional wallpapers (optional)"
    echo "10. Configure shell and theme"
    echo

    # Confirm installation
    if ! confirm "Do you want to proceed with the installation?"; then
        print_msg "Installation cancelled by user."
        exit 0
    fi

    # Start installation process
    install_script_packages
    install_aur_helper
    install_packages
    install_non_arch_packages
    install_doom_emacs
    setup_dotfiles
    backup_configurations
    apply_dotfiles
    post_installation

    # Final success message
    if check_command figlet lolcat; then
        figlet "Done!" | lolcat
    else
        print_header "INSTALLATION COMPLETE"
    fi

    print_success "Installation completed successfully!"
    echo
    echo "✅ Here's what to do next:"
    echo "1. Reboot your system for all changes to take effect"
    echo "2. Log in and select Hyprland as your session"
    echo "3. If you see no wallpaper, press Super + C to open the wallpaper selector"
    echo
    echo "If you experience any issues, check the repository for troubleshooting:"
    echo "https://github.com/arkboix/dotfiles"
    echo
    echo "Your original configurations have been backed up to: $BACKUP_DIR"
    echo

    if confirm "Would you like to reboot now?"; then
        print_msg "Rebooting system..."
        sudo reboot
    else
        print_msg "Remember to reboot manually to apply all changes."
    fi
}

# Run the main function
main
