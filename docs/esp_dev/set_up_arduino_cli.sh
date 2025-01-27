#!/bin/bash

# This script installs Arduino CLI to compile and upload firmwares for ESP32.

# USAGE
# ./set_up_arduino_cli.sh


# Retrieve Arduino CLI
wget -qO arduino-cli.tar.gz https://downloads.arduino.cc/arduino-cli/arduino-cli_latest_Linux_64bit.tar.gz

# Extract Arduino CLI to /usr/local/bin
sudo tar xf arduino-cli.tar.gz -C /usr/local/bin arduino-cli

# Check Arduino CLI version to verify install
arduino-cli version

# Remove Arduino CLI install archive
rm -rf arduino-cli.tar.gz

# Set up configuration file
arduino-cli config init

# Add ESP32 package link to Arduino CLI config .yaml
ARDUINO_CFG_FILE="/home/$USER/.arduino15/arduino-cli.yaml"
cat <<EOL > "$ARDUINO_CFG_FILE"
board_manager:
  additional_urls:
   - https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
EOL

# Install ESP32 packages
arduino-cli core update-index
arduino-cli board listall
arduino-cli core install esp32:esp32@2.0.6

# Install `pyserial` (required for ESP32 to build and upload)
pip3 install pyserial

printf "\nSuccessfull completed one-time set-up for A100 WAV GUI Tool.\n"
