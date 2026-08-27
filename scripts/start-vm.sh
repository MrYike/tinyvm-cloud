#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA="$HOME/tinyvm-data"
DISPLAY_NUM=":1"
VNC_PORT="5901"
WEB_PORT="6080"

bash "$ROOT/scripts/stop-vm.sh" >/dev/null 2>&1 || true
mkdir -p "$DATA"

nohup Xvfb "$DISPLAY_NUM" -screen 0 1366x768x24 -ac +extension GLX +render -noreset \
  >"$DATA/xvfb.log" 2>&1 &
echo $! >"$DATA/xvfb.pid"

for _ in {1..30}; do
  [[ -S /tmp/.X11-unix/X1 ]] && break
  sleep 0.2
done

nohup env DISPLAY="$DISPLAY_NUM" dbus-run-session -- startxfce4 \
  >"$DATA/desktop.log" 2>&1 &
echo $! >"$DATA/desktop.pid"

nohup x11vnc -display "$DISPLAY_NUM" -forever -shared -nopw -rfbport "$VNC_PORT" \
  >"$DATA/x11vnc.log" 2>&1 &
echo $! >"$DATA/x11vnc.pid"

nohup websockify --web=/usr/share/novnc "$WEB_PORT" "127.0.0.1:$VNC_PORT" \
  >"$DATA/novnc.log" 2>&1 &
echo $! >"$DATA/novnc.pid"

echo "TinyVM Linux started. Open the existing TinyVM Cloud link."
