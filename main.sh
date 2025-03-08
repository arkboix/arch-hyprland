#!/bin/bash
# https://github.com/arkboix/dotfiles
# https://github.com/arkboix/arch-hyprland

# Arkboi's Dotfiles Installation Script for Arch GNU/Linux.
# DO NOT EDIT IF YOU DO NOT KNOW WHAT YOU ARE DOING!!
#
#
#
#  ___       _    _           _ _      ______ _____ _____ _____
# / _ \     | |  | |         (_| )     |  _  \  _  |_   _/  ___|
#/ /_\ \_ __| | _| |__   ___  _|/ ___  | | | | | | | | | \ `--.
#|  _  | '__| |/ / '_ \ / _ \| | / __| | | | | | | | | |  `--. \
#| | | | |  |   <| |_) | (_) | | \__ \ | |/ /\ \_/ / | | /\__/ /
#\_| |_/_|  |_|\_\_.__/ \___/|_| |___/ |___/  \___/  \_/ \____/

set -e  # Exit script on any error

# Check for sudo immediately
if ! command -v sudo &>/dev/null; then
    echo "Error: sudo is not installed. Please install sudo first."
    exit 1
fi

sudo -v  # Keep sudo active

# Check for required utilities before trying to use them
if ! command -v pacman &>/dev/null; then
    echo "Error: This script is designed for Arch Linux and requires pacman."
    exit 1
fi

# Install figlet and lolcat first if not already installed
if ! command -v figlet &>/dev/null || ! command -v lolcat &>/dev/null; then
    sudo pacman --needed --noconfirm -S figlet lolcat
fi

figlet "Arkboi's DOTS" | lolcat
echo "Installing Arkboi's DOTFILES for $(whoami)"

# Define stuff - Add any more packages you want to install in EXTRA_PACKAGES
BACKUP_DIR="$HOME/arkboi-dots-backup"

SCRIPT_PACKAGES=(
    "git"
    "stow"
    "curl"
)

PACKAGES=(
    "hyprland"
    "hyprlock"
    "hypridle"
    "hyprcursor"
    "wlogout"
    "nwg-wrapper"
    "waybar"
    "rofi-wayland"
    "kitty"
    "emacs"
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
    "zsh"
    "zenity"
    "mako"
    "nwg-displays"
    "nautilus"
    "starship"
    "hyprshot"
)

# AUR packages
AUR_PACKAGES=(
    "pokeget"
    "hyprgui"
    "hyprshade"
    "ttf-ibm-plex-mono-nerd"
)

# Dependencies
DEPENDENCIES=(
    "pipewire-pulse" # For audio control (replaces pactl)
)

EXTRA_PACKAGES=()

FILES=(
    "$HOME/arkscripts"
    "$HOME/.config/hypr"
    "$HOME/.config/waybar"
    "$HOME/.config/doom"
    "$HOME/.config/kitty"
    "$HOME/.config/mako"
    "$HOME/.config/nwg-wrapper"
    "$HOME/.config/rofi"
    "$HOME/wallpapers"
    "$HOME/.config/wlogout"
    "$HOME/.config/starship.toml"
    "$HOME/.zshrc"
    "$HOME/.zshrc-personal"
)

# Check for script packages
MISSING_SCRIPT_PACKAGES=()
for pkg in "${SCRIPT_PACKAGES[@]}"; do
    if ! command -v "$pkg" &>/dev/null; then
        MISSING_SCRIPT_PACKAGES+=("$pkg")
    fi
done

# Install missing script packages if any
if [ ${#MISSING_SCRIPT_PACKAGES[@]} -gt 0 ]; then
    echo "Installing required script packages: ${MISSING_SCRIPT_PACKAGES[*]}"
    sudo pacman -S --needed --noconfirm "${MISSING_SCRIPT_PACKAGES[@]}"
fi

# Install Yay if not found
if ! command -v yay &>/dev/null; then
    echo "Installing Yay..."
    cd "$HOME"
    rm -rf yay  # Remove any existing yay directory to avoid conflicts
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd "$HOME"
    rm -rf yay  # Cleanup
else
    echo "Yay is already installed."
fi

figlet "Install Packages" | lolcat

# Install Packages
echo "Installing Packages..."
yay -S --needed --noconfirm "${PACKAGES[@]}" "${DEPENDENCIES[@]}" "${EXTRA_PACKAGES[@]}"

# Install AUR packages separately to handle any errors more gracefully
echo "Installing AUR Packages..."
for pkg in "${AUR_PACKAGES[@]}"; do
    echo "Installing $pkg..."
    yay -S --needed --noconfirm "$pkg" || echo "Warning: Failed to install $pkg, continuing..."
done

# Clone the repository of dotfiles
if [ -d "$HOME/dotfiles" ]; then
    echo "Existing dotfiles found. Moving to ~/.dotfiles_old..."
    mkdir -p "$HOME/.dotfiles_old"
    mv "$HOME/dotfiles" "$HOME/.dotfiles_old"
fi

git clone https://github.com/arkboix/dotfiles.git "$HOME/dotfiles"

# Backup existing configurations
echo "Backing up existing configuration files..."
mkdir -p "$BACKUP_DIR"

for FILE in "${FILES[@]}"; do
    if [ -e "$FILE" ]; then
        echo "Backing up $FILE to $BACKUP_DIR/"
        mkdir -p "$(dirname "$BACKUP_DIR/$(basename "$FILE")")"
        mv "$FILE" "$BACKUP_DIR/$(basename "$FILE")"
    fi
done

figlet "Backup and Install" | lolcat

# Stow dotfiles safely
cd "$HOME/dotfiles" || { echo "Failed to change to dotfiles directory"; exit 1; }

echo "Applying dotfiles using Stow..."
for DIR in hypr waybar kitty mako wlogout nwg-wrapper doom arkscripts starship rofi wallpapers zsh; do
    if [ -d "$DIR" ] || [ -f "$DIR" ]; then
        stow -v -t ~ "$DIR" || echo "Warning: Stow failed for $DIR"
    else
        echo "Skipping $DIR, directory not found."
    fi
done

# Post Installation
echo "Reloading configurations..."
if pgrep -x "Hyprland" > /dev/null; then
    hyprctl reload || echo "Hyprland reload failed"
else
    echo "Hyprland is not running, skipping reload"
fi

if pgrep -x "waybar" > /dev/null; then
    pkill -SIGUSR2 waybar || echo "Waybar reload failed"
else
    echo "Waybar is not running, skipping reload"
fi

# Set ZSH as default shell without requiring password input
if [ "$SHELL" != "/bin/zsh" ]; then
    echo "Changing default shell to ZSH..."
    echo "Note: You may need to enter your password"
    chsh -s /bin/zsh
    echo "If shell change failed, run this command manually after installation: chsh -s /bin/zsh"
fi

figlet "Done!" | lolcat
echo "Installation completed successfully!"
echo "You should be good to go now! If you experience any errors, open an issue at: https://github.com/arkboix/dotfiles"
echo "If you launch into Hyprland and see no wallpaper, set one by pressing Super + C"
echo
echo "Log out and log back in for all changes to take effect."
