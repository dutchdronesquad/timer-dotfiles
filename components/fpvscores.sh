#!/bin/bash
set -eu

# Function to install FPVScores plugin for development
install_fpvscores_dev() {
    local username=${1:-FPVScores}  # Default username is FPVScores

    cd ~
    git clone https://github.com/$username/FPVScores-Sync

    # Create a symlink with RotorHazard
    ln -s ~/FPVScores/fpvscores ~/RotorHazard/src/server/plugins
    echo "INFO: FPVScores installed for development."
}

# Function to install FPVScores plugin
install_fpvscores() {
    local plugin_destination=~/RotorHazard/src/server/plugins/fpvscores

    # Check if the plugin already exists
    if [ -d $plugin_destination ]; then
        read -r -p "FPVScores plugin already exists. Do you want to overwrite it? [y|N] " answer

        if [[ $answer =~ ^(y|Y)$ ]]; then
            rm -R $plugin_destination
        else
            echo "INFO: FPVScores installation aborted."
            exit 1
        fi
    fi

    # Install for non-development
    cd ~
    wget https://codeload.github.com/FPVScores/FPVScores/zip/main -O ~/temp.zip
    unzip ~/temp.zip

    # Move the plugin folder into RotorHazard and remove the rest
    mv ~/FPVScores-Sync-main/fpvscores $plugin_destination
    rm -R ~/FPVScores-Sync-main
    rm ~/temp.zip

    echo "INFO: FPVScores installed for non-development."
}

# Check if RotorHazard folder exists in the home directory
if [ -d ~/RotorHazard ]; then
    read -r -p "Do you want to install FPVScores for development? [y|N] " answer

    if [[ $answer =~ ^(y|Y)$ ]]; then
        # Install for development
        read -r -p "Enter the GitHub username (press Enter for default 'FPVScores'): " username
        install_fpvscores_dev $username
    else
        # Install for non-development
        install_fpvscores
    fi
else
    echo "ERROR: RotorHazard folder not found in the home directory. Please install RotorHazard first."
    exit 1
fi