#!/bin/bash
# https://github.com/arkboix/dotfiles
# https://github.com/arkboix/arch-hyprland

# Arkboi's Dotfiles Installation Script for Arch GNU/Linux.
# DO NOT EDIT IF YOU DO NOT KNOW WHAT YOU ARE DOING!!

set -e  # Exit script on any error

sudo -v  # Keep sudo active
sudo pacman --needed --noconfirm -S figlet lolcat
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
    "pokeget"
    "ttf-font-awesome"
    "ttf-jetbrains-mono"
    "ttf-jetbrains-mono-nerd"
    "ttf-fira-sans"
    "ttf-ibm-plex"
    "ttf-ibmplex-mono-nerd"
    "light"
    "pactl"
    "brightnessctl"
    "hyprsunset"
    "zsh"
    "hyprgui"
    "zenity"
    "mako"
    "nwg-displays"
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
yay -S --needed --noconfirm "${PACKAGES[@]}" "${SCRIPT_PACKAGES[@]}" "${EXTRA_PACKAGES[@]}"

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
        mv "$FILE" "$BACKUP_DIR/"
        echo "Moved $FILE to $BACKUP_DIR/"
    fi
done

figlet "Backup and Install" | lolcat

# Stow dotfiles safely
cd "$HOME/dotfiles"

echo "Applying dotfiles using Stow..."
for DIR in hypr waybar kitty mako wlogout nwg-wrapper doom arkscripts starship rofi wallpapers zsh; do
    if [ -d "$DIR" ] || [ -f "$DIR" ]; then
        stow -v -t ~ "$DIR"
    else
        echo "Skipping $DIR, directory not found."
    fi
done

# Post Installation
echo "Reloading configurations..."
hyprctl reload || echo "Hyprland reload failed (not running?)"
pkill -SIGUSR2 waybar || echo "Waybar reload failed (not running?)"

figlet "Done!" | lolcat
echo "You should be good to go now! If you experience any errors, open an issue at: https://github.com/arkboix/dotfiles"
