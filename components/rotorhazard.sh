#!/usr/bin/env bash
set -euo pipefail

# Source shared logging library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logger.sh"

rh_destination=~/RotorHazard

log_header "RotorHazard Installation"

# Function to install rotorhazard for development
install_rotorhazard_dev() {
    local username=${1:-RotorHazard}  # Default username is RotorHazard

    # Install needed APT packages
    install_apt_packages

    log_info "Installing RotorHazard for development from the main branch"
    cd ~
    git clone "https://github.com/$username/RotorHazard.git"

    # Move back to the server folder
    cd ~/RotorHazard/src/server

    # Ask if raspi-config should be run
    read -r -p "Do you want to change Raspberry Pi settings with raspi-config? (y/n): " raspi_config
    if [[ $raspi_config =~ ^(y|Y)$ ]]; then
        setup_pi_config
    fi

    log_info "Creating a virtual environment"
    python3 -m venv .venv

    # Update / install the venv packages
    update_virtualenv

    # Change the RH config file
    change_rh_config

    # Ask if raspi-config should be run
    read -r -p "Do you want to create the RotorHazard service? (y/n): " rh_service
    if [[ $rh_service =~ ^(y|Y)$ ]]; then
        create_rh_service
    fi

    log_warning "Don't forget to reboot because of raspi-config changes!"
    log_success "Ready with RotorHazard DEV installation"
}

# Function to install or update rotorhazard
install_or_update_rotorhazard() {
    local action=$1
    local version=$2

    if [[ $action =~ ^(i|install|I)$ ]]; then
        # Install needed APT packages
        install_apt_packages

        log_info "Download RotorHazard version: $version"
        wget "https://codeload.github.com/RotorHazard/RotorHazard/zip/v$version" -O ~/temp.zip
        unzip ~/temp.zip
        mv ~/RotorHazard-$version ~/RotorHazard
        rm ~/temp.zip

        # Change the RH config file
        change_rh_config

        # Update raspi-config settings
        setup_pi_config
    elif [[ $action =~ ^(u|update|U)$ ]]; then
        log_info "Updating RotorHazard to version: $version"
        cd ~
        wget "https://codeload.github.com/RotorHazard/RotorHazard/zip/v$version" -O ~/temp.zip
        unzip ~/temp.zip
        mv RotorHazard RotorHazard.old
        mv "RotorHazard-$version" RotorHazard
        rm ~/temp.zip

        # Copy files from the old install
        cp RotorHazard.old/src/server/config.json RotorHazard/src/server/
        cp RotorHazard.old/src/server/database.db RotorHazard/src/server/
        cp -r RotorHazard.old/src/server/venv RotorHazard/src/server/
    else
        error "Invalid action. Aborting."
    fi

    # Move back to the server folder
    cd ~/RotorHazard/src/server

    # Create a venv when selected install action
    if [[ $action =~ ^(i|install|I)$ ]]; then
        log_info "Creating a virtual environment"
        python3 -m venv .venv
    fi

    # Update / install the packages in venv
    update_virtualenv

    # Create the RH service
    create_rh_service
    log_success "Ready with RotorHazard installation"

    # Reboot after install - needed because of raspi changes
    if [[ $action =~ ^(i|install|I)$ ]]; then
        log_warning "Raspberry pi will reboot in 10 seconds"
        sleep 10

        log_info "Rebooting now"
        sudo reboot
    fi
}

# Update a venv
update_virtualenv() {
    log_info "Update venv packages"

    source .venv/bin/activate
    uv pip install -r requirements.txt
    deactivate
}

# Setup the Raspi config and boot settings
setup_pi_config() {
    log_info "Setup the Raspberry Pi config"
    source ~/timer-dotfiles/components/scripts/pi-config.sh
}

# Create the RotorHazard service
create_rh_service() {
    log_info "Create the RotorHazard service"
    source ~/timer-dotfiles/components/scripts/rh-service.sh
}

# Update the RH config file
change_rh_config() {
    cd ~/RotorHazard/src/server
    cp config-dist.json config.json

    read -r -p "Are you using a Nuclearhazard PCB? (y/n): " answer
    if [[ $answer =~ ^(y|Y)$ ]]; then
        echo "$(jq '.GENERAL += {"SHUTDOWN_BUTTON_GPIOPIN": 19, "SHUTDOWN_BUTTON_DELAYMS": 2500}' config.json)" > config.json
    else
        log_info "No changes made to the config file"
    fi
}

# Update APT packages
install_apt_packages() {
    log_info "Installing apt packages"
    sudo apt update && sudo apt upgrade -y
    sudo apt-get install -y python3-dev libffi-dev python3-smbus build-essential python3-pip scons swig python3-rpi.gpio python3-venv
}

read -r -p "Do you want to install RotorHazard for development purposes? [y|N] " dev_action

if [[ $dev_action =~ ^(y|Y)$ ]]; then
    read -r -p "Enter the GitHub username (press Enter for default 'RotorHazard'): " username
    install_rotorhazard_dev "$username"
else
    read -r -p "Do you want to install or update RotorHazard? [i|u|N] " action

    if [[ $action =~ ^(i|install|I|u|update|U)$ ]]; then
        if [[ $action =~ ^(i|install|I)$ ]]; then
            if [ -d "$rh_destination" ]; then
                error "You already installed RotorHazard. Aborting."
            fi

            read -r -p "Which version do you want to install? v" version

            # Check if the version variable is empty
            if [ -z "$version" ]; then
                error "No version specified. Aborting."
            fi
            install_or_update_rotorhazard "$action" "$version"
        elif [[ $action =~ ^(u|update|U)$ ]]; then
            read -r -p "Which version do you want to update to? v" version

            # Check if the version variable is empty
            if [ -z "$version" ]; then
                error "No version specified. Aborting."
            fi
            install_or_update_rotorhazard "$action" "$version"
        fi
    else
        log_error "No valid option selected. Aborting."
    fi
fi
