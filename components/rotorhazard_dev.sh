#!/bin/bash

# Function to install rotorhazard
install_rotorhazard() {
    local username=${1:-RotorHazard}  # Default username is RotorHazard

    echo "** Installing apt packages"
    sudo apt update && sudo apt upgrade
    sudo apt-get install -y python3-dev libffi-dev python3-smbus build-essential python3-pip scons swig python3-rpi.gpio

    echo "** Installing RotorHazard from the main branch"
    cd ~
    git clone https://github.com/$username/RotorHazard.git

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

read -r -p "Do you want to install RotorHazard? [i|N] " action

if [[ $action =~ ^(i|install|I)$ ]]; then
    read -r -p "Enter the GitHub username (press Enter for default 'RotorHazard'): " username
    install_rotorhazard $username

else
    echo "No valid option selected. Exiting."
fi
