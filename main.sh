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


remove_packages() {

    REMOVE_PACKAGES=(
        "mako"
        "pulseaudio"
        "wallust-git"
        "wlogout-git"
    )

    log_info "Removing unwanted/conficting packages..."

    for pkg in "${REMOVE_PACKAGES[@]}"; do
        if pacman -Qq "$pkg" &>/dev/null; then
            log_info "Removing $pkg"
            sudo pacman -Rnsc --noconfirm "$pkg"
        else
            log_info "$pkg not found, skipping.."
        fi
    done

}

remove_packages

aur_helper_choose() {
    log_info "Which AUR helper do you want to use? If it is not installed then the script will install it. (yay/paru)?"
    read -r AUR_HELPER

    AUR_HELPER=${AUR_HELPER:-yay} # Default YAY
    export AUR_HELPER


    if command -v "$AUR_HELPER" &>/dev/null; then
       log_info "$AUR_HELPER is already installed, WOAO"
    else
        log_info "installing $AUR_HELPER"
        sudo pacman -S --needed --noconfirm git base-devel || { log_error "Failed to install base-devel"; exit 1; }
        git clone "https://aur.archlinux.org/$AUR_HELPER.git" "$HOME/$AUR_HELPER" && cd "$HOME/$AUR_HELPER"
        makepkg -si --noconfirm
        cd "$HOME" && rm -rf "$HOME/$AUR_HELPER"


        if ! command -v "$AUR_HELPER" &>/dev/null; then
            log_error "$AUR_HELPER installation failed. Exiting."
            exit 1
        fi

        log_success "$AUR_HELPER installed successfully."
    fi
}

aur_helper_choose

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
log_info "Please Wait"
sleep 2

figlet "Install Packages" | lolcat


install_user_extra() {
    log_info "Any extra packages to install!? Press enter if no, seperate with a space."
    read -r USER_EXTRA_PACKAGES

    if [[ -n "$USER_EXTRA_PACKAGES" ]]; then
        log_info "Installing user packages"
        sudo pacman -S --needed --noconfirm "$USER_EXTRA_PACKAGES"
        log_success "Install USER_EXTRA_PACKAGES"
    else
        log_info "No user extras, skipping"
    fi

}

install_user_extra

install_packages() {


    # Define Packages
    PACKAGES=(
        "git"
        "stow"
        "curl"
        "zsh"
        "nwg-menu"
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
        "nwg-displays"
        "zenity"
        "thunar"
        "mako"
        "starship"
        "ttf-ibmplex-mono-nerd"
        "pipewire-pulse"
    )

    AUR_PACKAGES=(
        "nwg-wrapper"
        "wlogout"
        "light"
        "wallust"
    )


    # remove dupes
    rm_dupes

    log_info "Installing Official Repo Packages.."
    sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"
    log_success "Installed Official Repo Packages"

    log_info "Installing (6) AUR Packages"
for pkg in "${AUR_PACKAGES[@]}"; do
    if $AUR_HELPER -Ss "^$pkg\$" | grep -q "$pkg"; then
        log_info "Installing $pkg"
        $AUR_HELPER -S --needed --noconfirm "$pkg"
        log_success "Installed $pkg"
    else
        log_error "AUR package $pkg not found, skipping."
    fi
done


}

rm_dupes() {
    declare -A package_map

    # Add Official
    for pkg in "${PACKAGES[@]}"; do
        package_map["$pkg"]=1
    done

    # Fileter Aur

    local cleaned_aur_packages=()
    for pkg in "${AUR_PACKAGES[@]}"; do
               if [[ -z "${package_map[$pkg]}" ]]; then
                   cleaned_aur_packages+=("$pkg")
               else
                   log_warning "Skipping duplicate package: $pkg (exists in both PACKAGES and AUR_PACKAGES)"

               fi
    done

   AUR_PACKAGES=("${cleaned_aur_packages[@]}")
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
        "$HOME/wallpapers"
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
         git clone --depth 1 https://github.com/arkboix/wallpapers.git "$HOME/wallpapers"
         log_success "Wallpapers installed"
    fi


    log_info "Cloning main Dotfiles Repo"
    git clone --depth 1 https://github.com/arkboix/dotfiles.git "$HOME/dotfiles"
    log_success "Dotfiles installed."
}

clone


##########
## STOW ##
##########

stow_dots() {
    figlet "Stow Files" | lolcat

    log_info "Stowing the dotfiles"

    if ! cd "$HOME/dotfiles"; then
        log_error "Failed to enter dotfiles directory"
        exit 1
    fi

    FILES_STOW=(
        "arkscripts"
        "bash"
        "emacs"
        "wallpapers"
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


    ###################
    ## STOW DOTFILES ##
    ###################
    for dir in "${FILES_STOW[@]}"; do
        if [ -d "$dir" ]; then
            stow -v -t ~ "$dir" && log_success "Stowed $dir"
        else
            log_warning "Skipped $dir - does not exist"
        fi
    done

    log_success "All dotfiles stowed successfully"
}


stow_dots

##################
## POST INSTALL ##
##################


post_install() {

    figlet "Post Install" | lolcat

    log_info "Settings SWWW"
    if ! pgrep -x "swww-daemon" &>/dev/null; then
        swww-daemon & disown
        sleep 1
        log_success "Started swww-daemon"
    else
        log_info "swww-daemon is already running"
    fi


    log_info "setting wallpaper"
    swww img ~/wallpapers/moon-sky.png
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
