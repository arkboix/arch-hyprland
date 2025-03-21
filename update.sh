#!/bin/bash
# Arkboi's Dotfiles Update Script

set -e # Exit on error

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

aur_helper() {
    log_info "Which AUR helper to use? You need to have it installed. (yay/paru)?"
    read -r AUR_HELPER

    if [[ "$AUR_HELPER" =~ ^(yay|paru)$ ]]; then
        export AUR_HELPER="$AUR_HELPER"
    else
        log_warning "Invalid input, using yay"
        export AUR_HELPER="yay"
    fi
}

############
## BACKUP ##
############
backup() {
    BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y-%m-%d_%H-%M-%S)"

    log_info "Backing up ~/dotfiles to $BACKUP_DIR"

    cp -r "$HOME/dotfiles" "$BACKUP_DIR"

    log_success "Backup Complete"
}

############
## UPDATE ##
############
update_repo() {
    log_info "Do you want to update Arch Linux? (y/n)"
    read -r UPDATE_CONFIRM

    if [[ "$UPDATE_CONFIRM" == "y" || "$UPDATE_CONFIRM" == "Y" ]]; then
        log_info "Updating Arch Linux..."
        sudo pacman --noconfirm -Syu
        log_success "Updated Arch Linux"
    else
        log_info "Not updating Arch Linux"
    fi
}

update_aur() {
    log_info "Do you want to update Arch Linux AUR? (y/n)"
    read -r AUR_UPDATE_CONFIRM

    if [[ "$AUR_UPDATE_CONFIRM" == "y" || "$AUR_UPDATE_CONFIRM" == "Y" ]]; then
        log_info "Updating Arch Linux AUR..."
        "$AUR_HELPER" --noconfirm -Syu
        log_success "Updated Arch Linux AUR"
    else
        log_info "Not updating Arch Linux AUR"
    fi
}

#################
## UPDATE DOTS ##
#################

update_dots() {
    log_info "Updating dotfiles repo without resetting local changes"

    cd "$HOME/dotfiles" || { log_error "Failed to access dotfiles directory"; exit 1; }

    git stash push -m "Local changes before pull" && log_info "Stashed local changes"

    if git pull --rebase origin main; then
        log_success "Pulled latest changes with rebase"
        git stash pop || log_info "No local changes to apply"
        log_success "Dotfiles updated without losing local changes"
    else
        log_error "Merge conflict detected! Fix manually."
        git rebase --abort
        git stash pop # Restore local changes safely
        exit 1
    fi
}


stow_dots() {
    log_info "Stowing new dirs"

    old_dirs=$(ls "$BACKUP_DIR")
    new_dirs=$(ls "$HOME/dotfiles")

    for dir in $new_dirs; do
        # Skip .md files, LICENSE, and assets directory
        if [[ "$dir" == *.md || "$dir" == "LICENSE" || "$dir" == "assets" ]]; then
            log_info "Skipping $dir"
            continue
        fi

        if [[ -d "$HOME/dotfiles/$dir" && ! " $old_dirs " =~ " $dir " ]]; then
            log_info "Stowing new directory: $dir"
            stow -v -t ~ "$dir"
            log_success "Stowed $dir"
        fi
    done
}


install_fonts() {
    sudo pacman --needed --noconfirm ttf-montserrat
}

reboot_ask() {
    log_info "Do you want to reboot? Highly recommended. (y/n)"
    read -r REBOOT_CONFIRM

    if [[ "$REBOOT_CONFIRM" == "y" || "$REBOOT_CONFIRM" == "Y" ]]; then
        log_info "Rebooting..."
        sleep 1
        sync
        reboot
    else
       log_warning "Reboot skipped"
    fi
}



# Run
aur_helper
backup
update_repo
update_aur
update_dots
stow_dots
install_fonts
reboot_ask
