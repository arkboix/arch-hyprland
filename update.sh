#!/usr/bin/env sh
# Arkboi's Dotfiles Update Script
# Original: https://github.com/arkboix/dotfiles
# https://github.com/arkboix/arch-hyprland

set -e # to exit script in case of errors.

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

log_info "Starting Update script... Please enter SUDO password"

sudo -v # ask for password so no need to enter it again.

log_success "Sudo password correct"

clear

########################
## UPDATE PACMAN REPO ##
########################

update_repo() {
    log_info "Updating Arch Linux repository"
    sudo pacman --needed --noconfirm -Syu
    log_success "Update Arch Linux Repository"
}

update_repo

################
## UPDATE AUR ##
################

update_aur() {
    log_info "Updating AUR packages"

    if yay --version &>/dev/null; then
        log_info "Yay is installed"
        yay --needed --noconfirm -Syu
    else
        log_error "Yay is NOT installed. Please install yay by running:"
        log_warning "sudo pacman -S yay"
        exit 1
    fi
    log_success "AUR updated"
}

update_aur

#####################
## UPDATE DOTFILES ##
#####################

update_dots() {
    log_info "Updating Dotfiles.."
    cd "$HOME/dotfiles" || { log_error "Failed to enter dotfiles directory"; exit 1; }
    git pull --rebase origin main
    log_success "Update Dotfiles"

    log_info "Stowing Changes"
    for dir in */; do
        if [ -d "$dir" ] && [[ "$dir" != ".git" ]] && [[ "$dir" != "README.md" ]]; then
            stow -v -t ~ "$dir"
            log_success "Stowed $dir"
        else
            log_warning "Skipped $dir: Not a valid dotfile or excluded"
        fi
    done

    log_success "Stowing is done"
}

update_dots

#################
## POST UPDATE ##
#################

log_info "Post update tasks"

# Optionally, you can restart services or processes like wallpaper setting or daemon restart
log_info "Restarting swww-daemon if it's running"
if pgrep -x "swww-daemon" &>/dev/null; then
    pkill swww-daemon
    swww-daemon &
    log_success "swww-daemon restarted"
else
    log_info "swww-daemon is not running"
fi

# Reapply wallpaper after update
log_info "Reapplying wallpaper"
swww img ~/wallpapers/polarlights3.jpg
log_success "Wallpaper reapplied"

log_success "Post update complete!"

##########
## END ##
##########

log_success "Update complete!"
log_info "It is recommended to reboot your system to ensure all updates take effect."
log_info "Do you want to reboot now? (y/n)"
read -r REBOOT_CONFIRM

if [[ "$REBOOT_CONFIRM" =~ ^[Yy]$ ]]; then
    reboot
else
    log_info "Thanks for updating!"
    exit 0
fi
