#!/bin/bash
venv=".venv"
PYTHON=python3
ESPHOME_VERSION="2023.11.2"

if [ ! -d "${venv}" ]; then
    echo "Creating virtual environment at ${venv}"
    rm -rf "${venv}"
    "${PYTHON}" -m venv "${venv}"
    source "${venv}/bin/activate"

else
    source "${venv}/bin/activate"
fi

# Install Python dependencies
echo 'Installing Python dependencies'
pip3 install --upgrade pip
pip3 install --upgrade esphome==${ESPHOME_VERSION}
