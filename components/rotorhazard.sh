#!/bin/bash

version="3.2.1"

echo
echo "** Installing apt packages"
sudo apt update && sudo apt upgrade
sudo apt-get install -y python3-dev libffi-dev python3-smbus build-essential python3-pip scons swig python3-rpi.gpio


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