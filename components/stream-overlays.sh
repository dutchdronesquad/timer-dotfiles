#!/bin/bash
set -eu

# Function to install DDS Stream Overlays plugin for development
install_stream_overlays_dev() {
    local username=${1:-dutchdronesquad}  # Default username is dutchdronesquad

    cd ~
    git clone https://github.com/$username/rh-stream-overlays

    # Create a symlink with RotorHazard
    ln -s ~/rh-stream-overlays/stream_overlays ~/RotorHazard/src/server/plugins
    echo "INFO: DDS Stream Overlays installed for development."
}

# Function to install DDS Stream Overlays plugin
install_stream_overlays() {
    local plugin_destination=~/RotorHazard/src/server/plugins/stream_overlays

    # Check if the plugin already exists
    if [ -d $plugin_destination ]; then
        read -r -p "DDS Stream Overlays plugin already exists. Do you want to overwrite it? [y|N] " answer

        if [[ $answer =~ ^(y|Y)$ ]]; then
            rm -R $plugin_destination
        else
            echo "INFO: DDS Stream Overlays installation aborted."
            exit 1
        fi
    fi

    # Install for non-development
    wget https://codeload.github.com/dutchdronesquad/rh-stream-overlays/zip/main -O ~/temp.zip
    unzip ~/temp.zip

    # Move the plugin folder into RotorHazard and remove the rest
    mv ~/rh-stream-overlays-main/stream_overlays $plugin_destination
    rm -R ~/rh-stream-overlays-main
    rm ~/temp.zip

    echo "INFO: DDS Stream Overlays installed for non-development."
}

# Check if RotorHazard folder exists in the home directory
if [ -d ~/RotorHazard ]; then
    read -r -p "Do you want to install DDS Stream Overlays for development? [y|N] " answer

    if [[ $answer =~ ^(y|Y)$ ]]; then
        # Install for development
        read -r -p "Enter the GitHub username (press Enter for default 'dutchdronesquad'): " username
        install_stream_overlays_dev $username
    else
        # Install for non-development
        install_stream_overlays
    fi
else
    echo "ERROR: RotorHazard folder not found in the home directory. Please install RotorHazard first."
    exit 1
fi