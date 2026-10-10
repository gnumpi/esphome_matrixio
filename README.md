# ESPHome MatrixIO
**Target: ESPHome-2023.12.9**

[![ESPHome-target](https://github.com/gnumpi/esphome_matrixio/actions/workflows/tox-target.yml/badge.svg)](https://github.com/gnumpi/esphome_matrixio/actions/workflows/tox-target.yml)
[![ESPHome-latest](https://github.com/gnumpi/esphome_matrixio/actions/workflows/tox-latest.yml/badge.svg)](https://github.com/gnumpi/esphome_matrixio/actions/workflows/tox-latest.yml)



This custom component gives access to the LED-Strip (everloop), microphones and speakers of the [Matrixio-Voice](https://matrix-io.github.io/matrix-documentation/matrix-voice/overview/) within [ESPHome](https://esphome.io/).

It allows to use a Matrixio-Voice as a satellite for [Home Assistant](https://www.home-assistant.io/) [voice control](https://www.home-assistant.io/voice_control/).

Now it is also possible to use the Matrixio-Voice as a media player for Home Assistant.
Configuration files can be found in the 'examples' folder.

Right now, only one microphone of the array is used. I might add a beamforming in the future.

The implementation is based on the example code which MATRIX Labs provides on their project page: https://github.com/matrix-io.


## Installation
### With the MATRIX tools
#### Prepare Raspberry PI
Follow "Step 1: Raspberry Pi Setup" of  https://matrix-io.github.io/matrix-documentation/matrix-voice/esp32/

Unfortunately, the packages of MATRIX Lab are now longer maintained. Checkout the repository of Kunal Bansal
https://github.com/qnlbnsl/Matrix-IO if you run into installation issues, especially with the new Rapsberry PI OS Bookworm.

#### Build firmware
    git clone https://github.com/gnumpi/esphome_matrixio.git
    cd esphome_matrixio
    source scripts/setup_esphome.sh
    esphome compile matrix_voice.yaml

copy .esphome/build/matrixio-voice/.pioenvs/matrixio-voice/firmware-factory.bin to raspberry pi.

#### Flash ESP32
On raspberry pi:

    sudo voice_esp32_enable

    voice_esptool --chip esp32 --port /dev/ttyS0 --baud 1500000 --before default_reset --after hard_reset write_flash -u --flash_mode dio --flash_freq 40m --flash_size detect 0x000 firmware-factory.bin

### Alternative: flash with esptool directly (Raspberry Pi OS Bookworm and newer)
Use this if the steps above do not work: the MATRIX packages (`apt.matrix.one`, `voice_esp32_enable`,
`voice_esptool`) can no longer be installed, and their scripts use the sysfs GPIO numbers that changed with
kernel 6.6. Everything needed is the Pi's UART, two GPIOs and esptool. Build the firmware as described above
and copy `firmware-factory.bin` to the Pi.
Tested with a Pi 3B+, Raspberry Pi OS Trixie (64 bit) and esptool 4.8. The Pi powers the Voice through the
40 pin header, so use the original 2.5 A power supply (under-voltage made the flash unreliable) and unplug the
Voice's USB cable.

Wiring on the header: GPIO14/15 = ESP32 UART0, GPIO25 = EN (reset), GPIO24 = IO0 (low on reset = download mode).

1. Free the UART: `sudo raspi-config nonint do_serial_cons 1; sudo raspi-config nonint do_serial_hw 0` and add to
   `/boot/firmware/config.txt`:

        dtoverlay=disable-bt        # PL011 on GPIO14/15 -> /dev/serial0 = ttyAMA0 (the mini UART is unreliable)
        gpio=24,25,26=op,dh         # ESP32 boots normally, FPGA not in reset

2. `python3 -m venv ~/esptool-venv && ~/esptool-venv/bin/pip install 'esptool==4.8.*'`, then reboot.
3. Enter download mode, flash, start the firmware again (`pinctrl` ships with Raspberry Pi OS):

        pinctrl set 24 op dl; pinctrl set 25 op dl; sleep 0.1; pinctrl set 25 op dh; sleep 0.3
        ~/esptool-venv/bin/esptool.py --chip esp32 --port /dev/serial0 --baud 230400 --before no_reset --after no_reset \
            write_flash -z --flash_mode dio --flash_freq 40m --flash_size detect 0x0 firmware-factory.bin
        pinctrl set 24 op dh; pinctrl set 25 op dl; sleep 0.1; pinctrl set 25 op dh

   460800 baud produced transfer errors with a short, loosely fitting header extender, 230400 baud was reliable.
   The log of the running firmware is on the same port (115200 baud, e.g. `picocom -b 115200 /dev/serial0`).
   `firmware-factory.bin` is written to 0x0 and therefore also replaces bootloader and partition table.
   Before flashing, back up the old image with `read_flash 0 0x400000 backup.bin` (it contains the WiFi password).


## Configuration

```yaml
esp32:
  board: esp32dev
  framework:
    type: esp-idf
    version: recommended

spi:
  clk_pin:  GPIO32
  mosi_pin: GPIO33
  miso_pin: GPIO21

matrixio:
  id: matrixio_dev
  cs_pin: GPIO23

light:
  - platform: matrixio
    name: everloop
    id: everloop

microphone:
  - platform: matrixio
    id: matrixio_mic

speaker:
  - platform: matrixio
    id: matrixio_speaker
    # [headphone,speakers], default: headphone
    audio_out: headphone
    # 0..100, in percent, default: 80
    volume: 90


```
