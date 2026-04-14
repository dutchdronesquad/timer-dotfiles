#!/usr/bin/env bash
set -euo pipefail

# Source shared logging library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logger.sh"

readonly RH_HOME="$HOME/RotorHazard"
readonly RH_SERVER_DIR="$RH_HOME/src/server"
readonly RH_DATA_DIR="$HOME/rh-data"

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
    cd "$RH_SERVER_DIR"

    # Configure RotorHazard to use ~/rh-data for config/database
    configure_rh_data_path

    local ran_raspi_config=false

    # Ask if raspi-config should be run
    read -r -p "Do you want to change Raspberry Pi settings with raspi-config? (y/n): " raspi_config
    if [[ $raspi_config =~ ^(y|Y)$ ]]; then
        setup_pi_config
        ran_raspi_config=true
    fi

    log_info "Creating a virtual environment"
    python3 -m venv .venv

    # Update / install the venv packages
    update_virtualenv

    # Ask if raspi-config should be run
    read -r -p "Do you want to create the RotorHazard service? (y/n): " rh_service
    if [[ $rh_service =~ ^(y|Y)$ ]]; then
        create_rh_service
        show_post_install_next_steps
        maybe_run_post_install_tasks
    else
        log_info "Skipped service creation. You can run post-install tasks after RotorHazard has run once."
    fi

    if [[ "$ran_raspi_config" == true ]]; then
        log_warning "Don't forget to reboot because of raspi-config changes!"
    fi
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
        mv "$HOME/RotorHazard-$version" "$RH_HOME"
        rm ~/temp.zip

        # Configure RotorHazard to use ~/rh-data for config/database
        configure_rh_data_path

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

        # Keep data in ~/rh-data
        configure_rh_data_path
    else
        error "Invalid action. Aborting."
    fi

    # Move back to the server folder
    cd "$RH_SERVER_DIR"

    # Create a venv when selected install action
    if [[ $action =~ ^(i|install|I)$ ]]; then
        log_info "Creating a virtual environment"
        python3 -m venv .venv
    fi

    # Update / install the packages in venv
    update_virtualenv

    # Create the RH service
    create_rh_service
    show_post_install_next_steps
    maybe_run_post_install_tasks
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

# Configure RotorHazard to store runtime data in ~/rh-data
configure_rh_data_path() {
    mkdir -p "$RH_DATA_DIR"
    printf "%s\n" "$RH_DATA_DIR" > "$RH_SERVER_DIR/datapath.ini"
    log_info "Configured data path: $RH_DATA_DIR"
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

# Explain post-install migration flow for modern RotorHazard versions.
show_post_install_next_steps() {
    log_info "Next step: open RotorHazard UI and complete any data-migration prompts first"
    log_step "After migration, rerun this script and choose 'post-install tasks only'"
}

# Run optional tasks that require config.json to exist in RH data directory.
run_post_install_tasks() {
    local config_file="$RH_DATA_DIR/config.json"

    if [ ! -f "$config_file" ]; then
        log_warning "Post-install skipped: $config_file does not exist yet"
        log_step "Start RotorHazard once, complete migration in UI, then rerun post-install tasks"
        return
    fi

    change_rh_config
    log_success "Post-install tasks complete"
}

maybe_run_post_install_tasks() {
    read -r -p "Do you want to run post-install tasks now? [y|N] " post_install_now
    if [[ $post_install_now =~ ^(y|Y)$ ]]; then
        run_post_install_tasks
    else
        log_info "Post-install tasks skipped"
    fi
}

# Update the RH config file
change_rh_config() {
    local config_file="$RH_DATA_DIR/config.json"

    if [ ! -f "$config_file" ]; then
        log_warning "Cannot update Nuclearhazard settings: $config_file not found"
        return
    fi

    read -r -p "Are you using a Nuclearhazard PCB? (y/n): " answer
    if [[ ! $answer =~ ^(y|Y)$ ]]; then
        log_info "No changes made to the config file"
        return
    fi

    apply_nuclearhazard_config "$config_file"
    log_info "Applied Nuclearhazard settings in $config_file"
}

# Set Nuclearhazard shutdown GPIO settings in a new or existing config.json.
apply_nuclearhazard_config() {
    local config_file="$1"
    local tmp_file

    if ! command -v jq >/dev/null 2>&1; then
        error "jq is required to update $config_file"
    fi

    tmp_file=$(mktemp)
    local jq_expr='.GENERAL = (.GENERAL // {}) | .GENERAL.SHUTDOWN_BUTTON_GPIOPIN = 19 | .GENERAL.SHUTDOWN_BUTTON_DELAYMS = 2500'

    if [ -f "$config_file" ]; then
        jq "$jq_expr" "$config_file" > "$tmp_file"
    else
        jq "$jq_expr" <(echo '{}') > "$tmp_file"
    fi

    mv "$tmp_file" "$config_file"
}

# Update APT packages
install_apt_packages() {
    log_info "Installing apt packages"
    sudo apt update && sudo apt upgrade -y
    sudo apt-get install -y python3-dev libffi-dev python3-smbus build-essential python3-pip scons swig python3-rpi.gpio python3-venv jq
}

choose_main_action() {
    local selection

    if command -v whiptail >/dev/null 2>&1; then
        selection=$(whiptail --title "RotorHazard Installer" \
            --radiolist "Choose an action" 18 78 5 \
            "post-install" "Post-install tasks only (after RH UI migration)" ON \
            "install-dev" "Install development version" OFF \
            "install" "Install release version" OFF \
            "update" "Update existing release" OFF \
            "exit" "Exit" OFF \
            3>&1 1>&2 2>&3) || {
            echo "exit"
            return
        }
        echo "$selection"
        return
    fi

    if command -v dialog >/dev/null 2>&1; then
        local tmp_file
        tmp_file=$(mktemp)
        dialog --clear --title "RotorHazard Installer" \
            --radiolist "Choose an action" 18 78 5 \
            "post-install" "Post-install tasks only (after RH Data migration)" on \
            "install-dev" "Install development version" off \
            "install" "Install release version" off \
            "update" "Update existing release" off \
            "exit" "Exit" off \
            2>"$tmp_file" || {
            rm -f "$tmp_file"
            echo "exit"
            return
        }
        selection=$(cat "$tmp_file")
        rm -f "$tmp_file"
        echo "$selection"
        return
    fi

    log_info "Choose an action:"
    PS3="Select option [1-5]: "
    select _ in \
        "Post-install tasks only (after RH Data migration)" \
        "Install development version" \
        "Install release version" \
        "Update existing release" \
        "Exit"; do
        case "$REPLY" in
            1) echo "post-install"; return ;;
            2) echo "install-dev"; return ;;
            3) echo "install"; return ;;
            4) echo "update"; return ;;
            5) echo "exit"; return ;;
            *) log_warning "Invalid option, choose 1-5" ;;
        esac
    done
}

main_action=$(choose_main_action)

case "$main_action" in
    post-install)
        run_post_install_tasks
        ;;
    install-dev)
        read -r -p "Enter the GitHub username (press Enter for default 'RotorHazard'): " username
        install_rotorhazard_dev "$username"
        ;;
    install)
        if [ -d "$RH_HOME" ]; then
            error "You already installed RotorHazard. Aborting."
        fi

        read -r -p "Which version do you want to install? v" version
        if [ -z "$version" ]; then
            error "No version specified. Aborting."
        fi

        install_or_update_rotorhazard "i" "$version"
        ;;
    update)
        read -r -p "Which version do you want to update to? v" version
        if [ -z "$version" ]; then
            error "No version specified. Aborting."
        fi

        install_or_update_rotorhazard "u" "$version"
        ;;
    exit)
        log_info "No action selected. Exiting."
        ;;
    *)
        error "Unexpected menu action: $main_action"
        ;;
esac
