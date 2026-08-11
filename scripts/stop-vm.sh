#!/usr/bin/env bash
set -euo pipefail

DATA="$HOME/tinyvm-data"
pkill -f 'qemu-system-aarch64.*windows.qcow2' 2>/dev/null || true
if [[ -f "$DATA/novnc.pid" ]]; then
  kill "$(cat "$DATA/novnc.pid")" 2>/dev/null || true
  rm -f "$DATA/novnc.pid"
fi
