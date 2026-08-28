#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA="$ROOT/persistent"
DISPLAY_NUM=":1"
VNC_PORT="5901"
WEB_PORT="6080"
PASSFILE="$DATA/vnc.pass"

if [[ ! -f "$PASSFILE" ]]; then
  echo "VNC password is not configured. Run: bash .devcontainer/setup.sh"
  exit 1
fi

bash "$ROOT/scripts/stop-vm.sh" >/dev/null 2>&1 || true
mkdir -p "$DATA" "$DATA/Downloads" "$DATA/Documents" "$DATA/Desktop" "$DATA/config" "$DATA/cache" "$DATA/share"
export XDG_CONFIG_HOME="$DATA/config"
export XDG_CACHE_HOME="$DATA/cache"
export XDG_DATA_HOME="$DATA/share"

nohup Xvfb "$DISPLAY_NUM" -screen 0 1280x720x24 -ac +extension GLX +render -noreset   >"$DATA/xvfb.log" 2>&1 &
echo $! >"$DATA/xvfb.pid"

for _ in {1..30}; do
  [[ -S /tmp/.X11-unix/X1 ]] && break
  sleep 0.2
done

nohup env DISPLAY="$DISPLAY_NUM" dbus-run-session -- startxfce4   >"$DATA/desktop.log" 2>&1 &
echo $! >"$DATA/desktop.pid"

nohup x11vnc -display "$DISPLAY_NUM" -forever -shared -noxdamage -wait 20 -defer 20 -rfbauth "$PASSFILE" -rfbport "$VNC_PORT"   >"$DATA/x11vnc.log" 2>&1 &
echo $! >"$DATA/x11vnc.pid"

nohup websockify --heartbeat=30 --web=/usr/share/novnc "$WEB_PORT" "127.0.0.1:$VNC_PORT"   >"$DATA/novnc.log" 2>&1 &
echo $! >"$DATA/novnc.pid"

echo "Homework Linux started at 1280x720. Persistent files: $DATA"
