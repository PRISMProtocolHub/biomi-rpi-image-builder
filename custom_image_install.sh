#!/bin/bash
set -e
set -x

# Install specific dependencies
apt-get update
apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    libatlas-base-dev \
    libopencv-dev \
    python3-libcamera \
    python3-kms++ \
    libcap-dev \
    libkms++-dev libfmt-dev libdrm-dev \
    python3-pip \
    python3-pyqt5 \
    bluez \
    bluez-tools \
    bluetooth \
    libbluetooth-dev \
    python3-bluez \
    python3-venv

# Install Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Mettre à jour et installer Docker
apt-get update
apt-get install -y --no-install-recommends \
 docker-ce \
 docker-ce-cli \
 containerd.io \
 docker-buildx-plugin \
 docker-compose-plugin
