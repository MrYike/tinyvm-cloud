#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  xfce4 xfce4-terminal dbus-x11 xvfb x11vnc novnc websockify

mkdir -p "$HOME/tinyvm-data"
chmod +x scripts/start-vm.sh scripts/stop-vm.sh

printf '\nTinyVM Linux is ready. Run: bash scripts/start-vm.sh\n\n'
