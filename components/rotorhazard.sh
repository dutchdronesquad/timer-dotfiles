#!/bin/bash

version="3.2.0"

echo
echo "** Installing apt packages"
sudo apt update && sudo apt upgrade
sudo apt-get install -y python3-smbus python3-pip scons swig python3-rpi.gpio python3-dev


#----------------------------------------------------------------------------
# RotorHazard install
#----------------------------------------------------------------------------
echo
echo "** Installing RotorHazard"
cd ~
wget https://codeload.github.com/RotorHazard/RotorHazard/zip/v$version -O temp.zip
unzip temp.zip
mv RotorHazard-$version RotorHazard
rm temp.zip

cd ~/RotorHazard/src/server
sudo pip install -r requirements.txt