#!/bin/bash

set -e

if [ "$1" == "--install-dev" ]; then
    sudo apt-get install clang lld xxd binaryen acme

    if ! [ -x "$(command -v pio)" ]; then
        echo "Installing PlatformIO..."

        sudo apt-get install python3.10-venv
        curl -fsSL -o get-platformio.py https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py
        python3 get-platformio.py

        rm get-platformio.py
    fi

    echo "Installing emsdk..."

    devdeps/emsdk/emsdk install latest
    devdeps/emsdk/emsdk activate latest

    exit
fi

mkdir -p build

acme --cpu 65c02 -o build/os.o os/main.asm
xxd -n rom -i build/os.o > firmware/_rom.h

if [ "$1" == "--sim" ]; then
    source devdeps/emsdk/emsdk_env.sh

    emcmake cmake .
    make
elif [ "$1" == "--upload" ]; then
    pio run -t upload -e ${2:-adafruit_feather_nrf52840_sense}
else
    pio run
fi