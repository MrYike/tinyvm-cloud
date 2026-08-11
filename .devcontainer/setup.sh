#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  qemu-system-arm qemu-utils qemu-efi-aarch64 novnc websockify

mkdir -p "$HOME/tinyvm-data"
if [[ ! -f "$HOME/tinyvm-data/windows.qcow2" ]]; then
  qemu-img create -f qcow2 "$HOME/tinyvm-data/windows.qcow2" 64G
fi

chmod +x scripts/start-vm.sh scripts/stop-vm.sh
printf '\nTinyVM is ready. Upload Windows11-arm64.iso, then run: bash scripts/start-vm.sh\n\n'
