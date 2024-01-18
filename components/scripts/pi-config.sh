#!/bin/bash

# Logging function
log() {
    echo "INFO: $1"
}

log "Update raspi-config settings"

sudo raspi-config nonint do_ssh 0
sudo raspi-config nonint do_spi 0
sudo raspi-config nonint do_i2c 0
sudo raspi-config nonint do_serial_hw 0
sudo raspi-config nonint do_serial_cons 1

# Function to append to the config file if the line is not present
append_if_not_exists() {
    grep -qF "$1" "$2" || echo "$1" | sudo tee -a "$2"
}

# Prompt user for GPIO pin
read -p "Enter GPIO pin (default is 18): " GPIO_PIN
GPIO_PIN=${GPIO_PIN:-18}

log "Update /boot/config.txt settings with GPIO pin $GPIO_PIN"

append_if_not_exists "dtparam=i2c_baudrate=75000" /boot/config.txt
append_if_not_exists "dtoverlay=miniuart-bt" /boot/config.txt
append_if_not_exists "dtoverlay=act-led,gpio=24" /boot/config.txt
append_if_not_exists "dtparam=act_led_trigger=heartbeat" /boot/config.txt
append_if_not_exists "dtoverlay=gpio-shutdown,gpio_pin=$GPIO_PIN,debounce=5000" /boot/config.txt

if grep -qF "core_freq=250" /boot/config.txt
then
    log "INFO: core_freq=250 already set"
else
    sudo sed -i '/\[pi[0-3]\]/a core_freq=250' /boot/config.txt
    sudo sed -i '/\[all\]/a core_freq=250' /boot/config.txt
fi