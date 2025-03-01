#!/usr/bin/env bash

# WARNING: DON'T EDIT IF YOU DON'T KNOW WHATCHA DOING!
# This script installs and configures dotfiles for Hyprland setup
# It's meant to be modifiable, but proceed with caution

set -e

# Check if running as root (avoid running as root)
if [ "$EUID" -eq 0 ]; then
  echo "Please do not run this script as root"
  exit 1
fi

# Variables
DOTFILES_REPO="https://github.com/arkboix/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
TERM_WIDTH=$(tput cols)
TERM_HEIGHT=$(tput lines)
WHIP_WIDTH=$((TERM_WIDTH - 10))
WHIP_HEIGHT=$((TERM_HEIGHT - 10))

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
DEFAULT_PACKAGES=("yay")

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

# Log file
LOG_FILE="/tmp/dotfiles_install_$(date +%Y%m%d_%H%M%S).log"

# Check if whiptail is available, if not try to install it
if ! command -v whiptail >/dev/null 2>&1; then
    echo "Whiptail is not installed. Installing it now..."
    sudo pacman -S --needed --noconfirm libnewt || {
        echo "Failed to install whiptail. Falling back to basic mode."
        USE_WHIPTAIL=false
    }
else
    USE_WHIPTAIL=true
fi

# Helper functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    if $USE_WHIPTAIL; then
        whiptail --title "Error" --msgbox "An error occurred: $1\nCheck the log at $LOG_FILE for details." 10 60
    else
        echo -e "\033[0;31mERROR: $1\033[0m"
        echo "Check the log at $LOG_FILE for details."
    fi
    log "ERROR: $1"
    exit 1
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Backup existing configuration
backup_configs() {
    log "Backing up existing configurations"

    if $USE_WHIPTAIL; then
        {
            echo -e "XXX\n0\nPreparing backup...\nXXX"

            if [[ ! -d "$BACKUP_DIR" ]]; then
                mkdir -p "$BACKUP_DIR"
                log "Created backup directory: $BACKUP_DIR"
            fi

            total=${#BACKUP_FOLDERS[@]}
            current=0

            for dir in "${BACKUP_FOLDERS[@]}"; do
                # Calculate percentage
                pct=$((current * 100 / total))
                current=$((current + 1))
                echo -e "XXX\n$pct\nBacking up ~/$dir...\nXXX"

                # Handle files and directories
                if [[ -e "$HOME/$dir" ]]; then
                    # Create necessary parent directories
                    parent_dir=$(dirname "$BACKUP_DIR/$dir")
                    mkdir -p "$parent_dir"

                    # Copy the file/directory
                    cp -r "$HOME/$dir" "$BACKUP_DIR/$dir" 2>> "$LOG_FILE"
                    log "Backed up ~/$dir"
                else
                    log "~/$dir does not exist, skipping backup"
                fi

                # Small sleep to make the progress visible
                sleep 0.1
            done

            echo -e "XXX\n100\nBackup completed!\nXXX"
            sleep 1
        } | whiptail --title "Backing up existing configurations" --gauge "Preparing backup..." 10 70 0
    else
        echo "Backing up existing configurations..."

        if [[ ! -d "$BACKUP_DIR" ]]; then
            mkdir -p "$BACKUP_DIR"
            log "Created backup directory: $BACKUP_DIR"
        fi

        for dir in "${BACKUP_FOLDERS[@]}"; do
            echo "Processing ~/$dir..."

            # Handle files and directories
            if [[ -e "$HOME/$dir" ]]; then
                # Create necessary parent directories
                parent_dir=$(dirname "$BACKUP_DIR/$dir")
                mkdir -p "$parent_dir"

                # Copy the file/directory
                cp -r "$HOME/$dir" "$BACKUP_DIR/$dir" 2>> "$LOG_FILE"
                log "Backed up ~/$dir"
                echo "✓ Backed up ~/$dir"
            else
                log "~/$dir does not exist, skipping backup"
                echo "! ~/$dir does not exist, skipping backup"
            fi
        done

        echo "Backup completed!"
    fi
}

# Install pacman packages
install_pacman_packages() {
    local packages=("$@")
    log "Installing packages with pacman: ${packages[*]}"
    sudo pacman -S --needed --noconfirm "${packages[@]}" >> "$LOG_FILE" 2>&1 ||
        error_exit "Failed to install packages with pacman"
}

# Install packages using yay
install_yay_packages() {
    local packages=("$@")
    log "Installing packages with yay: ${packages[*]}"
    yay -S --needed --noconfirm "${packages[@]}" >> "$LOG_FILE" 2>&1 ||
        error_exit "Failed to install packages with yay"
}

# Install required packages
install_packages() {
    # Check if pacman is available
    if ! command_exists pacman; then
        error_exit "Pacman package manager not found. This script expects an Arch-based distro."
    fi

    # Install script requirements first
    if $USE_WHIPTAIL; then
        whiptail --title "Installing Required Tools" --infobox "Installing script requirements..." 8 70
    else
        echo "Installing script requirements..."
    fi
    install_pacman_packages "${SCRIPT_REQUIRED[@]}"

    # Install basic required packages
    if ! command_exists yay; then
        if $USE_WHIPTAIL; then
            whiptail --title "Installing Yay" --infobox "Installing yay AUR helper..." 8 70
        else
            echo "Installing yay AUR helper..."
        fi
        install_pacman_packages "${DEFAULT_PACKAGES[@]}"
    else
        log "yay is already installed"
    fi

    # Ask for confirmation to install Hyprland packages
    install_hypr=true
    if $USE_WHIPTAIL; then
        if ! whiptail --title "Hyprland Packages" --yesno "Would you like to install the following Hyprland packages?\n\n$(printf "• %s\n" "${HYPR_PACKAGES[@]}")" $WHIP_HEIGHT $WHIP_WIDTH; then
            install_hypr=false
        fi
    else
        echo "The following Hyprland packages will be installed:"
        for package in "${HYPR_PACKAGES[@]}"; do
            echo "• $package"
        done
        read -p "Proceed with installation? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
            install_hypr=false
        fi
    fi

    if $install_hypr; then
        if $USE_WHIPTAIL; then
            {
                echo -e "XXX\n0\nPreparing to install Hyprland packages...\nXXX"
                # Install Hyprland packages
                yay -S --needed --noconfirm "${HYPR_PACKAGES[@]}" >> "$LOG_FILE" 2>&1 || {
                    echo -e "XXX\n100\nError: Failed to install packages. Check log.\nXXX"
                    sleep 2
                    error_exit "Failed to install Hyprland packages"
                }
                echo -e "XXX\n100\nHyprland packages installed successfully\nXXX"
                sleep 1
            } | whiptail --title "Installing Hyprland Packages" --gauge "Preparing to install Hyprland packages..." 10 70 0
        else
            echo "Installing Hyprland packages..."
            yay -S --needed --noconfirm "${HYPR_PACKAGES[@]}" >> "$LOG_FILE" 2>&1 ||
                error_exit "Failed to install Hyprland packages"
            echo "Hyprland packages installed successfully"
        fi
    else
        log "Hyprland package installation skipped by user"
    fi

    # Ask for additional packages
    additional_packages=""
    if $USE_WHIPTAIL; then
        additional_packages=$(whiptail --title "Additional Packages" --inputbox "Enter additional packages to install (separate with spaces):" 10 70 3>&1 1>&2 2>&3)
    else
        echo
        echo "Enter additional packages to install (separate with spaces):"
        read -r additional_packages
    fi

    if [[ ! -z "$additional_packages" ]]; then
        # Convert the input string to an array
        IFS=' ' read -ra additional_packages_arr <<< "$additional_packages"

        # Verify and install additional packages
        if $USE_WHIPTAIL; then
            {
                echo -e "XXX\n0\nVerifying additional packages...\nXXX"

                valid_packages=()
                total=${#additional_packages_arr[@]}
                current=0

                for package in "${additional_packages_arr[@]}"; do
                    pct=$((current * 50 / total))
                    current=$((current + 1))
                    echo -e "XXX\n$pct\nVerifying package: $package\nXXX"

                    if yay -Ss "^$package$" > /dev/null 2>&1; then
                        valid_packages+=("$package")
                        log "Package '$package' exists"
                    else
                        log "Package '$package' not found"
                    fi

                    sleep 0.2
                done

                if [[ ${#valid_packages[@]} -gt 0 ]]; then
                    echo -e "XXX\n50\nInstalling additional packages...\nXXX"
                    yay -S --needed --noconfirm "${valid_packages[@]}" >> "$LOG_FILE" 2>&1 || {
                        echo -e "XXX\n100\nError: Failed to install additional packages\nXXX"
                        sleep 2
                        error_exit "Failed to install additional packages"
                    }
                    echo -e "XXX\n100\nAdditional packages installed successfully\nXXX"
                else
                    echo -e "XXX\n100\nNo valid packages found to install\nXXX"
                fi

                sleep 1
            } | whiptail --title "Installing Additional Packages" --gauge "Verifying additional packages..." 10 70 0
        else
            echo "Verifying additional packages..."
            valid_packages=()

            for package in "${additional_packages_arr[@]}"; do
                echo -n "Checking if package '$package' exists... "
                if yay -Ss "^$package$" > /dev/null 2>&1; then
                    echo "✓ exists"
                    valid_packages+=("$package")
                    log "Package '$package' exists"
                else
                    echo "✗ not found"
                    log "Package '$package' not found"
                fi
            done

            if [[ ${#valid_packages[@]} -gt 0 ]]; then
                echo "Installing additional packages..."
                yay -S --needed --noconfirm "${valid_packages[@]}" >> "$LOG_FILE" 2>&1 ||
                    error_exit "Failed to install additional packages"
                echo "Additional packages installed successfully"
            else
                echo "No valid packages found to install"
            fi
        fi
    fi
}

# Clone dotfiles repository
clone_dotfiles() {
    log "Setting up dotfiles"
    if [[ -d "$DOTFILES_DIR" ]]; then
        log "Dotfiles directory already exists"

        remove_existing=false
        if $USE_WHIPTAIL; then
            if whiptail --title "Dotfiles Exist" --yesno "Dotfiles directory already exists at $DOTFILES_DIR.\n\nWould you like to remove it and clone again?" 10 70; then
                remove_existing=true
            fi
        else
            echo "Dotfiles directory already exists at $DOTFILES_DIR."
            read -p "Would you like to remove it and clone again? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                remove_existing=true
            fi
        fi

        if $remove_existing; then
            log "Removing existing dotfiles directory"
            rm -rf "$DOTFILES_DIR"
        else
            log "Using existing dotfiles directory"
            return
        fi
    fi

    if $USE_WHIPTAIL; then
        whiptail --title "Cloning Dotfiles" --infobox "Cloning dotfiles repository from $DOTFILES_REPO to $DOTFILES_DIR..." 8 70
    else
        echo "Cloning dotfiles repository from $DOTFILES_REPO to $DOTFILES_DIR..."
    fi

    git clone "$DOTFILES_REPO" "$DOTFILES_DIR" >> "$LOG_FILE" 2>&1 ||
        error_exit "Failed to clone dotfiles repository"

    log "Dotfiles cloned to $DOTFILES_DIR"
    if ! $USE_WHIPTAIL; then
        echo "✓ Dotfiles cloned to $DOTFILES_DIR"
    fi
}

# Stow configurations
stow_configs() {
    log "Stowing configuration files"

    # Change to dotfiles directory
    cd "$DOTFILES_DIR" || error_exit "Failed to change to dotfiles directory"

    # List available configurations
    available_configs=()
    for dir in */; do
        if [[ -d "$dir" ]]; then
            config=${dir%/}
            available_configs+=("$config")
        fi
    done

    if [[ ${#available_configs[@]} -eq 0 ]]; then
        log "No configuration folders found"
        if $USE_WHIPTAIL; then
            whiptail --title "No Configurations" --msgbox "No configuration folders found in $DOTFILES_DIR." 8 70
        else
            echo "No configuration folders found in $DOTFILES_DIR."
        fi
        return
    fi

    # Process for selecting configurations
    selected_configs=()

    if $USE_WHIPTAIL; then
        # Format for whiptail
        whiptail_options=()
        for config in "${available_configs[@]}"; do
            whiptail_options+=("$config" "" OFF)
        done

        # Set first option to ON by default if available
        if [[ ${#whiptail_options[@]} -ge 3 ]]; then
            whiptail_options[2]=ON
        fi

        # Add "All" option at the beginning
        whiptail_options=("all" "Select all configurations" OFF "${whiptail_options[@]}")

        # Ask which configurations to stow
        selected=$(whiptail --title "Select Configurations" --checklist \
            "Which configurations would you like to stow?" $WHIP_HEIGHT $WHIP_WIDTH $((${#whiptail_options[@]}/3)) \
            "${whiptail_options[@]}" 3>&1 1>&2 2>&3)

        exitstatus=$?
        if [[ $exitstatus -ne 0 ]]; then
            log "User canceled configuration selection"
            return
        fi

        # Check if "all" was selected
        if [[ $selected == *'"all"'* ]]; then
            selected_configs=("${available_configs[@]}")
        else
            # Parse selected options
            # Remove quotes and convert to array
            selected=${selected//\"/}
            IFS=' ' read -ra selected_arr <<< "$selected"
            selected_configs=("${selected_arr[@]}")
        fi
    else
        # CLI selection
        echo "Available configurations:"
        for i in "${!available_configs[@]}"; do
            echo "  $((i+1)). ${available_configs[$i]}"
        done

        echo
        echo "Which configurations would you like to stow?"
        echo "Options: all, none, or numbers separated by spaces (e.g., 1 3 4)"
        read -p "> " stow_choice

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
    fi

    # Stow selected configurations
    if [[ ${#selected_configs[@]} -gt 0 ]]; then
        if $USE_WHIPTAIL; then
            {
                echo -e "XXX\n0\nPreparing to stow configurations...\nXXX"

                total=${#selected_configs[@]}
                current=0

                for config in "${selected_configs[@]}"; do
                    pct=$((current * 100 / total))
                    current=$((current + 1))
                    echo -e "XXX\n$pct\nStowing $config...\nXXX"

                    stow -v -t "$HOME" "$config" >> "$LOG_FILE" 2>&1 || {
                        echo -e "XXX\n$pct\nError stowing $config. Check log.\nXXX"
                        sleep 2
                        log "ERROR: Failed to stow $config"
                        continue
                    }

                    log "$config stowed successfully"
                    sleep 0.3
                done

                echo -e "XXX\n100\nConfigurations stowed successfully\nXXX"
                sleep 1
            } | whiptail --title "Stowing Configurations" --gauge "Preparing to stow configurations..." 10 70 0
        else
            echo "Stowing configurations..."
            for config in "${selected_configs[@]}"; do
                echo -n "Stowing $config... "
                if stow -v -t "$HOME" "$config" >> "$LOG_FILE" 2>&1; then
                    echo "✓ done"
                    log "$config stowed successfully"
                else
                    echo "✗ failed"
                    log "ERROR: Failed to stow $config"
                fi
            done
            echo "Stowing completed"
        fi
    else
        log "No configurations selected for stowing"
        if $USE_WHIPTAIL; then
            whiptail --title "No Selection" --msgbox "No configurations selected for stowing." 8 70
        else
            echo "No configurations selected for stowing."
        fi
    fi
}

# Run post-installation steps
post_installation() {
    log "Running post-installation steps"

    if $USE_WHIPTAIL; then
        whiptail --title "Post-Installation" --infobox "Running post-installation steps..." 8 70
    else
        echo "Running post-installation steps..."
    fi

    # Make sure arkscripts directory exists
    if [[ -d "$HOME/arkscripts" ]]; then
        log "arkscripts directory found"
        cd "$HOME/arkscripts" || error_exit "Failed to change to arkscripts directory"

        # Make scripts executable
        chmod +x *.sh 2>> "$LOG_FILE" || log "WARNING: Failed to make all scripts executable"
        log "Made scripts executable"

        # Run waybar color script
        if [[ -f "./waybar-color.sh" ]]; then
            ./waybar-color.sh >> "$LOG_FILE" 2>&1 || log "WARNING: waybar-color.sh failed to run properly"
            log "Ran waybar-color.sh"
            if ! $USE_WHIPTAIL; then
                echo "✓ Ran waybar-color.sh"
            fi
        else
            log "WARNING: waybar-color.sh not found"
            if $USE_WHIPTAIL; then
                whiptail --title "Warning" --msgbox "waybar-color.sh not found in ~/arkscripts" 8 70
            else
                echo "! waybar-color.sh not found in ~/arkscripts"
            fi
        fi
    else
        log "WARNING: arkscripts directory not found"
        if $USE_WHIPTAIL; then
            whiptail --title "Warning" --msgbox "arkscripts directory not found. Post-installation steps incomplete." 8 70
        else
            echo "! arkscripts directory not found. Post-installation steps incomplete."
        fi
    fi

    # Create wlogout symbolic link
    if [[ -d "$HOME/wallpapers" && -f "$HOME/wallpapers/wlogout.jpg" ]]; then
        ln -sf "$HOME/wallpapers/wlogout.jpg" "/tmp/wlogout.jpg" 2>> "$LOG_FILE" ||
            log "WARNING: Failed to create wlogout wallpaper symlink"
        log "Created wlogout wallpaper symlink"
        if ! $USE_WHIPTAIL; then
            echo "✓ Created wlogout wallpaper symlink"
        fi
    else
        log "WARNING: Wallpaper for wlogout not found"
        if $USE_WHIPTAIL; then
            whiptail --title "Warning" --msgbox "Wallpaper for wlogout not found. Create ~/wallpapers/wlogout.jpg manually." 8 70
        else
            echo "! Wallpaper for wlogout not found. Create ~/wallpapers/wlogout.jpg manually."
        fi
    fi
}

# Main function
main() {
    # Initialize log file
    echo "Dotfiles Installation Log - $(date)" > "$LOG_FILE"
    log "Starting installation"

    # Display welcome message
    if $USE_WHIPTAIL; then
        whiptail --title "Dotfiles Installation Script" --msgbox "Welcome to the Dotfiles Installation Script!\n\nThis script will guide you through installing your dotfiles and setting up your Hyprland environment.\n\nWARNING: DON'T EDIT IF YOU DON'T KNOW WHATCHA DOING!" 15 70 || exit 1
    else
        echo "========================================="
        echo "      Dotfiles Installation Script      "
        echo "========================================="
        echo
        echo "WARNING: DON'T EDIT IF YOU DON'T KNOW WHATCHA DOING!"
        echo
        echo "This script will guide you through installing your"
        echo "dotfiles and setting up your Hyprland environment."
        echo
        read -p "Press Enter to continue..." </dev/tty
    fi

    # Check for stow
    if ! command_exists stow; then
        if $USE_WHIPTAIL; then
            whiptail --title "Missing Dependency" --msgbox "GNU Stow is not installed. It will be installed first." 8 70
        else
            echo "GNU Stow is not installed. Installing it first..."
        fi
        install_pacman_packages "stow"
    fi

    # Installation steps selection
    selected_steps=""
    if $USE_WHIPTAIL; then
        OPTIONS=(
            "1" "Install Packages" ON
            "2" "Clone Dotfiles Repository" ON
            "3" "Backup Existing Configurations" ON
            "4" "Stow Configurations" ON
            "5" "Run Post-Installation Steps" ON
        )

        selected_steps=$(whiptail --title "Installation Steps" --checklist \
            "Select the steps you want to perform:" 15 70 5 \
            "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

        exitstatus=$?
        if [[ $exitstatus -ne 0 ]]; then
            whiptail --title "Canceled" --msgbox "Installation canceled by user." 8 70
            exit 0
        fi
    else
        echo
        echo "Installation Steps:"
        echo "1. Install Packages"
        echo "2. Clone Dotfiles Repository"
        echo "3. Backup Existing Configurations"
        echo "4. Stow Configurations"
        echo "5. Run Post-Installation Steps"
        echo
        echo "Enter the numbers of steps you want to perform (separated by spaces),"
        echo "or enter 'all' to perform all steps:"
        read -p "> " steps_input

        if [[ "$steps_input" == "all" ]]; then
            selected_steps="1 2 3 4 5"
        else
            selected_steps="$steps_input"
        fi
    fi

    # Execute selected steps
    if [[ "$selected_steps" == *"1"* ]] || [[ "$selected_steps" == *'"1"'* ]]; then install_packages; fi
    if [[ "$selected_steps" == *"2"* ]] || [[ "$selected_steps" == *'"2"'* ]]; then clone_dotfiles; fi
    if [[ "$selected_steps" == *"3"* ]] || [[ "$selected_steps" == *'"3"'* ]]; then backup_configs; fi
    if [[ "$selected_steps" == *"4"* ]] || [[ "$selected_steps" == *'"4"'* ]]; then stow_configs; fi
    if [[ "$selected_steps" == *"5"* ]] || [[ "$selected_steps" == *'"5"'* ]]; then post_installation; fi

    # Installation complete
    if $USE_WHIPTAIL; then
        whiptail --title "Installation Complete" --msgbox "Your dotfiles have been installed successfully!\n\nA backup of your previous configurations can be found at:\n$BACKUP_DIR\n\nIf you encounter any issues, please visit:\nhttps://github.com/arkboix/dotfiles\n\nInstallation log available at:\n$LOG_FILE" 15 70
    else
        echo
        echo "========================================="
        echo "        Installation Complete!          "
        echo "========================================="
        echo
        echo "Your dotfiles have been installed successfully!"
        echo
        echo "A backup of your previous configurations can be found at:"
        echo "$BACKUP_DIR"
        echo
        echo "If you encounter any issues, please visit:"
        echo "https://github.com/arkboix/dotfiles"
        echo
        echo "Installation log available at:"
        echo "$LOG_FILE"
    fi

    log "Installation completed successfully"
}

# Run the script
main
