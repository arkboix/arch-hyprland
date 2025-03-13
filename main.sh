#!/bin/bash
# Arch Linux Only Version of Arkboi's Dotfiles Installation Script
# Original: https://github.com/arkboix/dotfiles
# https://github.com/arkboix/arch-hyprland



set -e # To Exit the script if any error happen

############
## COLORS ##
############
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

##################
## LOG FUNCTION ##
##################
log_info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${RESET} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

###########
## START ##
###########

log_info "Starting Script.. Please Enter SUDO Password"

sudo -v # Ask for sudo password, this way you do not need to enter it again.

log_success "Sudo password correct"

clear # Clear the text

######################
## INSTALL PACKAGES ##
######################


install_script_depends() {
  VISUAL_PACKAGES=(
        "figlet"
        "lolcat"
    )

  sudo pacman -S  --needed --noconfirm "${VISUAL_PACKAGES[@]}"
  clear
}

install_script_depends

# Starting Message
figlet "Arkboi's DOTS" | lolcat
log_info "Arch Linux install script for Arkboi's Hyprland dotfiles."



install_packages() {

    figlet "Install Packages" | lolcat


    # Define Packages
    PACKAGES=(
        "git"
        "stow"
        "curl"
        "zsh"
        "bash"
        "emacs"
        "hyprland"
        "hyprlock"
        "hypridle"
        "python-pywal"
        "hyprcursor"
        "waybar"
        "rofi-wayland"
        "kitty"
        "swww"
        "yad"
        "ttf-font-awesome"
        "ttf-jetbrains-mono"
        "ttf-jetbrains-mono-nerd"
        "ttf-fira-sans"
        "ttf-ibm-plex"
        "brightnessctl"
        "zenity"
        "thunar"
        "mako"
        "starship"
        "ttf-ibmplex-mono-nerd"
        "pipewire-pulse"
    )

    AUR_PACKAGES=(
        "pokeget"
        "hyprgui"
        "nwg-wrapper"
        "hyprshot"
        "wlogout"
        "nwg-displays"
        "light"
        "waypaper"
        "wallust"
    )

    # Define User-Specific Extra packages
    EXTRA_PACKAGES=()


    log_info "Installing Official Repo Packages.."
    sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"
    log_success "Installed Official Repo Packages"

    log_info "Installing (9) AUR Packages"

    if yay --version &>/dev/null; then
        log_info "YAY AUR Helper is installed."
        yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"

    elif sudo pacman -S --needed --noconfirm git base-devel && git clone https://aur.archlinux.org/yay.git && pushd yay && makepkg -si && popd; then
        log_success "Yay Installed successfully"
        yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
    else
        log_error "Yay failed to install, please try manually installing yay, Exiting."
        exit 1
    fi

}

install_packages # Install the packages

############
## BACKUP ##
############


backup() {

    figlet "Backup" | lolcat

    FILES=(
        "$HOME/.config/hypr"
        "$HOME/dotfiles"
        "$HOME/.config/kitty"
        "$HOME/.bashrc"
        "$HOME/.doom.d"
        "$HOME/.config/wallust"
        "$HOME/.config/wal"
        "$HOME/.config/mako"
        "$HOME/.config/waybar"
        "$HOME/.config/rofi"
        "$HOME/.config/nwg-dock-hyprland"
        "$HOME/.config/nwg-wrapper"
        "$HOME/.config/wofi"
        "$HOME/.config/wlogout"
        "$HOME/.config/starship"
        "$HOME/arkscripts/"
        "$HOME/wallpapers"
    )

    log_info "Do you want to backup existing configs? (y/n)"
    read -r BACKUP_CONFIRM

    if [[ "$BACKUP_CONFIRM" =~ ^[Yy]$ ]]; then
        BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y-%m-%d_%H-%M-%S)"
        mkdir -p "$BACKUP_DIR"
        log_info "Backing up existing configurations to $BACKUP_DIR"

        for file in "${FILES[@]}"; do
            if [ -e "$file" ]; then
                cp -r "$file" "$BACKUP_DIR/"
                log_success "Backup $file complete"
            else
                log_warning "Skipped $file does not exist"
            fi
        done

        log_success "Backup files successfully!"

    else
        log_info "Skip backup"
    fi
}


backup


##############
## CLEANUP  ##
##############


cleanup_config () {
    log_info "Now removing configs"

    for file in "${FILES[@]}"; do
        if [ -e "$file" ]; then
            rm -rf "$file"
            log_success "Removed $file"
        else
            log_warning "Skipped $file does not exist"
        fi
    done

    log_success "Files removed"
}

cleanup_config

###########
## CLONE ##
###########

clone() {
    log_info "Do you want to install additional wallpapers? (WARN: You need NASA's storage for this) (y/n)"
    read -r WALLS_CONFIRM

    if [[ "$WALLS_CONFIRM" =~ ^[Yy]$ ]]; then
        log_info "Cloning wallpapers repo, hope your computer doesn't run out of space!"
         git clone https://github.com/arkboix/wallpapers.git "$HOME/wallpapers"
         log_success "Wallpapers installed"
    fi


    log_info "Cloning main Dotfiles Repo"
    git clone https://github.com/arkboix/dotfiles.git "$HOME/dotfiles"
    log_success "Dotfiles installed."
}

clone


##########
## STOW ##
##########

stow_dots() {

    figlet "Stow Files" | lolcat

    log_info "Stowing the dotfiles"
    cd "$HOME/dotfiles" || { log_error "Failed to enter dotfiles"; exit 1; }

    FILES_STOW=(
        "arkscripts"
        "bash"
        "emacs"
        "hypr"
        "kitty"
        "mako"
        "nwg-dock-hyprland"
        "nwg-wrapper"
        "rofi"
        "starship"
        "wal"
        "wallust"
        "waybar"
        "wlogout"
        "wofi"
    )

# Check if wallpapers were cloned

    if [ -d "$HOME/wallpapers" ]; then
        log_info "Move exisitng wallpapers into dotfiles"

        mv "$HOME/wallpapers/"* "$HOME/dotfiles/wallpapers/wallpapers"
        rm -rf "$HOME/wallpapers"

        log_success "Wallpapers Moved"
        log_info "Stowing wallpapers"
    else
        log_info "Stowing wallpapers"
    fi


        stow -v -t ~ wallpapers
        log_success "Stowing wallpapers done"

    for dir in "${FILES_STOW[@]}"; do
        if [ -d "$dir" ]; then
            stow -v -t ~ "$dir"
            log_success "Stowed $dir"
        else
            log_warning "Skipped $dir does not exist"
        fi
    done

    log_success "All dotfiles stow successfully"

}

stow_dots

##################
## POST INSTALL ##
##################


post_install() {

    figlet "Post Install" | lolcat

    log_info "Settings SWWW"
    if ! pgrep -x "swww-daemon" &>/dev/null; then
        swww-daemon &
        log_success "Started swww-daemon"
    else
        log_info "swww-daemon is already running"
    fi


    log_info "setting wallpaper"
    swww img ~/wallpapers/polarlights3.jpg
    log_success "Apply wallpaper done"
    bash ~/arkscripts/wal.sh

}

post_install

#########
## END ##
#########

end() {
    figlet "We Are Done!" | lolcat
    log_success "Reboot is recommended"
    log_info "After reboot, launch into hyprland and Super + C to set wallpaper, Super + F1 to see keybinds"
    log_info "Do you want to reboot? (y/n) HIGHLY RECOMMEND"
    read -r REBOOT_CONFIRM

    if [[ "$REBOOT_CONFIRM" =~ ^[Yy]$ ]]; then
        reboot
    else
        log_info "Thanks!"
        exit 0
    fi
}

end
