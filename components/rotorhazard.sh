#!/bin/bash
set -eu

# Function to install rotorhazard for development
install_rotorhazard_dev() {
    local username=${1:-RotorHazard}  # Default username is RotorHazard

    echo "** Installing apt packages"
    sudo apt update && sudo apt upgrade
    sudo apt-get install -y python3-dev libffi-dev python3-smbus build-essential python3-pip scons swig python3-rpi.gpio

    echo "** Installing RotorHazard for development from the main branch"
    cd ~
    git clone https://github.com/$username/RotorHazard.git

    # Install packages in venv
    cd ~/RotorHazard/src/server

    echo "** Creating a virtual environment **"
    setup_virtualenv
    pip install -r requirements.txt
    deactivate
}

# Function to install or update rotorhazard
install_or_update_rotorhazard() {
    local action=$1
    local version=$2

    echo "** Installing apt packages"
    sudo apt update && sudo apt upgrade
    sudo apt-get install -y python3-dev libffi-dev python3-smbus build-essential python3-pip scons swig python3-rpi.gpio

    if [[ $action =~ ^(i|install|I)$ ]]; then
        echo "** Installing RotorHazard version: $version"
        cd ~
        wget https://codeload.github.com/RotorHazard/RotorHazard/zip/v$version -O temp.zip
        unzip temp.zip
        mv RotorHazard-$version RotorHazard
        rm temp.zip
    elif [[ $action =~ ^(u|update|U)$ ]]; then
        echo "** Updating RotorHazard to version: $version"
        cd ~
        wget https://codeload.github.com/RotorHazard/RotorHazard/zip/v$version -O temp.zip
        unzip temp.zip
        mv RotorHazard RotorHazard.old
        mv RotorHazard-$version RotorHazard
        rm temp.zip

        # Copy files from the old install
        cp RotorHazard.old/src/server/config.json RotorHazard/src/server/
        cp RotorHazard.old/src/server/database.db RotorHazard/src/server/
        cp -r RotorHazard.old/src/server/venv RotorHazard/src/server/
    else
        echo "Invalid action. Exiting."
        exit 1
    fi

    # Install packages in venv
    cd ~/RotorHazard/src/server

    echo "** Creating a virtual environment **"
    setup_virtualenv
    pip install -r requirements.txt
    deactivate
}

# Create a venv
setup_virtualenv() {
    python3 -m venv venv
    source venv/bin/activate
}

read -r -p "Do you want to install RotorHazard for development purposes? [y|N] " dev_action

if [[ $dev_action =~ ^(y|Y)$ ]]; then
    read -r -p "Enter the GitHub username (press Enter for default 'RotorHazard'): " username
    install_rotorhazard_dev $username
else
    read -r -p "Do you want to install or update RotorHazard? [i|u|N] " action

    if [[ $action =~ ^(i|install|I|u|update|U)$ ]]; then
        if [[ $action =~ ^(i|install|I)$ ]]; then
            read -r -p "Which version do you want to install? v" version

            # Check if the version variable is empty
            if [ -z "$version" ]; then
                echo "No version specified. Aborting."
                exit 1
            fi
            install_or_update_rotorhazard $action $version
        elif [[ $action =~ ^(u|update|U)$ ]]; then
            read -r -p "Which version do you want to update to? v" version

            # Check if the version variable is empty
            if [ -z "$version" ]; then
                echo "No version specified. Aborting."
                exit 1
            fi
            install_or_update_rotorhazard $action $version
        fi
    else
        echo "No valid option selected. Exiting."
    fi
fi
