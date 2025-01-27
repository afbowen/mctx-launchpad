# ESP32 Development
ESP32 is a flexible microprocessor platform with excellent documentation and handy features like
integrated WiFi and BLE. This document captures relevant information about the platform in the
context of development on a Linux computer.


## Set Up Build Tools
These are one-time procedures to set up build tools for ESP32 processors.

### ESP-IDF
Espressif provides a development framework called the IDF (IoT Development Framework) that makes
it easy to configure, build, upload, and debug projects.

#### Install and Set Up ESP-IDF
This installation process is based entirely on the
[Standard Toolchain Setup for Linux and macOS](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/get-started/linux-macos-setup.html)
procedure available on the Espressif website.

1. Install system dependencies.
   ```
   sudo apt-get install git wget flex bison gperf python3 python3-pip python3-venv cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0
   ```
2. Clone the ESP-IDF.
   ```
   mkdir -p ~/esp
   cd ~/esp
   git clone -b v5.4 --recursive https://github.com/espressif/esp-idf.git
   ```
3. Set up the tools.
   ```
   cd ~/esp/esp-idf
   ./install.sh esp32
   ```
4. Set up the environmental variables (note this only applies to the **current** terminal session).
   ```
   . $HOME/esp/esp-idf/export.sh
   ```
5. Create an alias to set up the environmental variables by adding the following to `~/.bashrc`.
   ```
   alias get_idf='. $HOME/esp/esp-idf/export.sh'
   ```
6. _Peruse example projects at `~/esp/esp-idf/examples`._

### Arduino CLI
Espressif provides an [Ardiuno core](https://github.com/espressif/arduino-esp32) that makes it
possible to build for a wide variety of ESP32 processors and breakout boards using Arduino CLI or
Arduino IDE. This route might be preferable when writing for specific ESP32-based boards (like
those with onboard displays, sensors etc), or when needing to write or execute existing code that
is used across different host microprocessors.

#### Install and Set Up Arduino CLI
The Arduino CLI install procedure is based on
[this procedure](https://lindevs.com/install-arduino-cli-on-ubuntu), and configuration for use with
ESP32 is based on [this one](https://wellys.com/posts/esp32_cli/).

Alternatively, run the `arduino_cli_set_up.sh` script in this directory. It automatically executes
all of the following commands (minus confirmation of install using `arduino-cli version`).

1. Retrieve Arduino CLI.
   ```
   wget -qO arduino-cli.tar.gz https://downloads.arduino.cc/arduino-cli/arduino-cli_latest_Linux_64bit.tar.gz
   ```
2. Extract Arduino CLI to `/usr/local/bin` for command line access.
   ```
   sudo tar xf arduino-cli.tar.gz -C /usr/local/bin arduino-cli
   ```

3. Check Arduino CLI version to verify install.
   ```
   arduino-cli version
   ```

4. Remove Arduino CLI install archive.
   ```
   rm -rf arduino-cli.tar.gz
   ```
5. Initialize Arduino CLI configuration.
   ```
   arduino-cli config init
   ```
6. Update Arduino CLI configuration to include a pointer to the ESP32 repository by adding the
   following text to `/home/$USER/.arduino15/arduino-cli.yaml`.
   ```
   board_manager:
     additional_urls:
      - https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
7. Install ESP32 packages.
   ```
   arduino-cli core update-index
   arduino-cli board listall
   arduino-cli core install esp32  # OR install esp32:esp32@2.0.6 for version 2.0.6
   ```
8. Make sure `pyserial` is installed so Arduino CLI can talk to ESP32 microcontollers over USB.
   ```
   pip3 install pyserial
   ```


## Building

### ESP-IDF
#### Build, Upload and Monitor

1. Open a terminal window and enter the project directory.
   ```
   cd path/to/project_directory
   ```
2. Export IDF environmental variables (`export.sh`) using the `get_idf` alias created during
   [Install and Set Up ESP-IDF](install-and-set-up-esp-idf).
   ```
   get_idf
   ```
3. Build the project.
   ```
   idf build
   ```
4. Upload the project to the ESP32 plugged in via USB (defaults to `/dev/ttyUSB0`).
   ```
   idf -p path/to/port flash
   ```
5. Monitor the output of the project (print log message published using `ESP_LOG...()`, in addition
   to the `printf` output visible to serial monitors like Putty).
   ```
   idf -p path/to/port flash
   ```
6. _Clean the project for full rebuild as needed._
   ```
   idf fullclean
   ```

### Arduino
Look at the `build_for_arduino_cli.sh` script in this directory.
