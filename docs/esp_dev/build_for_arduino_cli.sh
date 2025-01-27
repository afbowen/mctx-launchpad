#!/bin/bash

# USAGE #
# ./flash_node_fw.sh kneel_node
#!/bin/bash

# This script...
# - Creates a symlink at the location Arduino CLI looks for shared code libraries
#   (`~/Arduino/libraries`), temporarily moving the existing directory if libraries have already
#   been installed using `arduino-cli lib install ...`.
# - Compiles the target control node firmware.
# - Uploads the target control node firmware.
# - Removes the symblink and restores the original `~/Arduino/libraries` directory if need be.

# USAGE
# ./build_for_arduino_cli.sh path/to/sketch


# Define paths
ARDUINO_DIR="$HOME/Arduino"
LIBRARIES_DIR="$ARDUINO_DIR/libraries"
THIS_DIR="$(dirname "$(realpath "$0")")"
MODULES_DIR="path/to/shared/modules"
LIBRARIES_TMP="$ARDUINO_DIR/libraries_tmp"


# Confirm user has a device plugged into USB
printf "Please confirm ESP32-C3 is plugged in via USB and the GUI tool is NOT running (y/n): "
read -r CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  printf "Exiting. Please plug in the ESP32-C3 and try again."
  exit 1
fi


# SET UP SYMLINK FOR MODULES/LIBRARIES #

# Ensure ~/Arduino exists
if [ ! -d "$ARDUINO_DIR" ]; then
  printf "Creating directory: $ARDUINO_DIR\n"
  mkdir -p "$ARDUINO_DIR"
fi

# Check if ~/Arduino/libraries exists and handle it
if [ -d "$LIBRARIES_DIR" ]; then
  printf "Moving existing libraries directory to: $LIBRARIES_TMP\n"
  mv "$LIBRARIES_DIR" "$LIBRARIES_TMP"
fi

# Create symlink for ~/Arduino/libraries pointing to ~/modules
if [ ! -d "$MODULES_DIR" ]; then
  printf "Modules directory does not exist. Creating: $MODULES_DIR\n"
  mkdir -p "$MODULES_DIR"
fi

printf "Creating symlink: $LIBRARIES_DIR -> $MODULES_DIR\n"
ln -s "$MODULES_DIR" "$LIBRARIES_DIR"


# COMPILE AND UPLOAD APP #

acli_failed=false
# Compile application
printf "Compiling "$1" firmware...\n"
arduino-cli compile -b esp32:esp32:esp32c3 -p /dev/ttyUSB0 "$1"
if [ $? != 0 ]; then printf "ERROR: COMPILATION FAILED\n"; acli_failed=true; fi

# Upload firmware to ESP32-C3
if ! $acli_failed; then
    printf "Uploading "$1" firmware...\n"
    arduino-cli upload -b esp32:esp32:esp32c3 -p /dev/ttyUSB0 "$1"
    if [ $? != 0 ]; then printf "ERROR: UPLOAD FAILED\n"; acli_failed=true; fi
fi


# RESTORE ORIGINAL ARDUINO LIBRARIES #

# Clean up: Remove symlink and restore original libraries directory if it existed
if [ -L "$LIBRARIES_DIR" ]; then
  printf "Removing symlink: $LIBRARIES_DIR\n"
  rm "$LIBRARIES_DIR"
fi

if [ -d "$LIBRARIES_TMP" ]; then
  printf "Restoring original libraries directory from: $LIBRARIES_TMP\n"
  mv "$LIBRARIES_TMP" "$LIBRARIES_DIR"
fi

if $acli_failed; then
    printf "ERROR: COMPILATION OR UPLOAD FAILED, READ ABOVE\n"
else
    printf "\nSuccessfull uploaded $1 firmware.\n"
fi
