#!/usr/bin/env bash
set -euo pipefail

DATA="$HOME/tinyvm-data"
for name in novnc x11vnc desktop xvfb; do
  pidfile="$DATA/$name.pid"
  if [[ -f "$pidfile" ]]; then
    kill "$(cat "$pidfile")" 2>/dev/null || true
    rm -f "$pidfile"
  fi
done
pkill -f 'qemu-system-aarch64.*windows.qcow2' 2>/dev/null || true
pkill -f 'websockify.*6080' 2>/dev/null || true
pkill -f 'x11vnc.*5901' 2>/dev/null || true
