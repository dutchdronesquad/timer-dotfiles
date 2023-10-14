#!/bin/bash

# Function to install rotorhazard
install_rotorhazard() {
    local version=$1

    echo "** Installing apt packages"
    sudo apt update && sudo apt upgrade
    sudo apt-get install -y python3-dev libffi-dev python3-smbus build-essential python3-pip scons swig python3-rpi.gpio

    echo "** Installing RotorHazard version $version"
    cd ~
    wget https://codeload.github.com/RotorHazard/RotorHazard/zip/v$version -O temp.zip
    unzip temp.zip
    mv RotorHazard-$version RotorHazard
    rm temp.zip

    # Install packages in venv
    cd ~/RotorHazard/src/server

    echo "** Creating a virtual environment **"
    setup_virtualenv
    pip install -r requirements.txt
    deactivate
}

# Function for updating rotorhazard
update_rotorhazard() {
    local version=$1

    echo "** Updating RotorHazard to $version"
    cd ~
    wget https://codeload.github.com/RotorHazard/RotorHazard/zip/v$version -O temp.zip
    unzip temp.zip
    mv RotorHazard RotorHazard.old
    mv RotorHazard-$version RotorHazard
    rm temp.zip

    # Copy files from the old install
    cp RotorHazard.old/src/server/config.json RotorHazard/src/server/
    cp RotorHazard.old/src/server/database.db RotorHazard/src/server/

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

read -r -p "Do you want to install or update RotorHazard? [i|u|N] " action

if [[ $action =~ ^(i|install|I)$ ]]; then
    read -r -p "Which version do you want to install? v" version
    install_rotorhazard $version

elif [[ $action =~ ^(u|update|U)$ ]]; then
    read -r -p "Which version do you want to update to? v" version
    update_rotorhazard $version

else
    echo "No valid option selected. Exiting."
fi