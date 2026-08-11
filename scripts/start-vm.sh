#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA="$HOME/tinyvm-data"
ISO="${WINDOWS_ISO:-$ROOT/Windows11-arm64.iso}"
DISK="$DATA/windows.qcow2"
LOG="$DATA/qemu.log"

if [[ ! -f "$ISO" ]]; then
  echo "Missing Windows ARM64 ISO: $ISO"
  echo "Upload it to the repository root as Windows11-arm64.iso."
  exit 1
fi

bash "$ROOT/scripts/stop-vm.sh" >/dev/null 2>&1 || true

FIRMWARE="/usr/share/AAVMF/AAVMF_CODE.fd"
if [[ ! -f "$FIRMWARE" ]]; then
  FIRMWARE="$(find /usr/share -iname '*AAVMF*CODE*.fd' -o -iname 'QEMU_EFI.fd' | head -n 1)"
fi
if [[ -z "$FIRMWARE" || ! -f "$FIRMWARE" ]]; then
  echo "ARM64 UEFI firmware was not found."
  exit 1
fi

nohup qemu-system-aarch64 \
  -machine virt,accel=tcg,gic-version=3 \
  -cpu max -smp 2 -m 6144 \
  -bios "$FIRMWARE" \
  -device qemu-xhci \
  -drive if=none,file="$DISK",format=qcow2,id=system \
  -device nvme,drive=system,serial=tinyvm \
  -drive if=none,file="$ISO",media=cdrom,readonly=on,id=installer \
  -device usb-storage,drive=installer \
  -device ramfb \
  -device usb-kbd -device usb-tablet \
  -nic user,model=virtio-net-pci \
  -vnc 127.0.0.1:1 \
  -daemonize \
  >>"$LOG" 2>&1

nohup websockify --web=/usr/share/novnc 6080 127.0.0.1:5901 \
  >"$DATA/novnc.log" 2>&1 &
echo $! >"$DATA/novnc.pid"

echo "TinyVM started. Open the forwarded port 6080 from the Codespaces Ports panel."
echo "Expect the first Windows boot to be very slow because it uses software emulation."
