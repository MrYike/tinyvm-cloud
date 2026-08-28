#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspaces/tinyvm-cloud"
DATA="$HOME/tinyvm-data"
DISPLAY_NUM=":1"
PASSFILE="$DATA/vnc.pass"

bash "$ROOT/scripts/stop-vm.sh" >/dev/null 2>&1 || true
mkdir -p "$DATA"

if [[ ! -f "$PASSFILE" ]]; then
  echo "VNC password is not configured."
  exit 1
fi

nohup Xvfb "$DISPLAY_NUM" -screen 0 1366x768x24 -ac +extension GLX +render -noreset >"$DATA/xvfb.log" 2>&1 &
echo $! >"$DATA/xvfb.pid"

for _ in {1..30}; do
  [[ -S /tmp/.X11-unix/X1 ]] && break
  sleep 0.2
done

nohup env DISPLAY="$DISPLAY_NUM" dbus-run-session -- startxfce4 >"$DATA/desktop.log" 2>&1 &
echo $! >"$DATA/desktop.pid"

nohup x11vnc -display "$DISPLAY_NUM" -forever -shared -rfbauth "$PASSFILE" -rfbport 5901 >"$DATA/x11vnc.log" 2>&1 &
echo $! >"$DATA/x11vnc.pid"

nohup websockify --web=/usr/share/novnc 6080 127.0.0.1:5901 >"$DATA/novnc.log" 2>&1 &
echo $! >"$DATA/novnc.pid"

echo "TinyVM Linux started."
