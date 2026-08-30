#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/persistent/webtop"
mkdir -p "$CONFIG" "$CONFIG/CloudDrive"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not ready. Rebuild the Codespace container once."
  exit 1
fi

docker rm -f homework-webtop >/dev/null 2>&1 || true
docker pull lscr.io/linuxserver/webtop:ubuntu-xfce

docker run -d   --name homework-webtop   --restart unless-stopped   --shm-size=2gb   -p 3000:3000   -p 3100:3100   -p 8765:8765   -e PUID="$(id -u)"   -e PGID="$(id -g)"   -e TZ="Australia/Sydney"   -e TITLE="Homework"   -e START_DOCKER="false"   -e SELKIES_AUDIO_ENABLED="true"   -e SELKIES_MICROPHONE_ENABLED="false"   -e SELKIES_ENCODER="x264enc"   -e SELKIES_FRAMERATE="30"   -e SELKIES_H264_CRF="30"   -e SELKIES_USE_CPU="true"   -e SELKIES_IS_MANUAL_RESOLUTION_MODE="true"   -e SELKIES_MANUAL_WIDTH="1280"   -e SELKIES_MANUAL_HEIGHT="720"   -e SELKIES_AUDIO_BITRATE="96000"   -e SELKIES_SECOND_SCREEN="false"   -e SELKIES_ENABLE_SHARING="false"   -e FILE_MANAGER_PATH="/config/Downloads"   -v "$CONFIG:/config"   lscr.io/linuxserver/webtop:ubuntu-xfce

if [[ -n "${FILE_BRIDGE_TOKEN:-}" ]]; then
  cp "$ROOT/cloud/file_bridge.py" "$CONFIG/file_bridge.py"
  cp "$ROOT/cloud/relay_gateway.py" "$CONFIG/relay_gateway.py"
  docker exec -d -e FILE_BRIDGE_TOKEN="$FILE_BRIDGE_TOKEN" -e CLOUDDRIVE_ROOT=/config/CloudDrive homework-webtop /lsiopy/bin/python3 /config/file_bridge.py
  docker exec homework-webtop /lsiopy/bin/python3 -m pip install --disable-pip-version-check --target /config/relay-libs aiohttp
  docker exec -d -e FILE_BRIDGE_TOKEN="$FILE_BRIDGE_TOKEN" -e PYTHONPATH=/config/relay-libs homework-webtop /lsiopy/bin/python3 /config/relay_gateway.py
else
  echo "CloudDrive helper is waiting for FILE_BRIDGE_TOKEN."
fi

if [[ ! -x "$CONFIG/firefox/firefox" ]]; then
  mkdir -p "$CONFIG/firefox-download"
  curl -fL --retry 5 'https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US' -o "$CONFIG/firefox-download/firefox.tar.xz"
  tar -xJf "$CONFIG/firefox-download/firefox.tar.xz" -C "$CONFIG"
  rm -f "$CONFIG/firefox-download/firefox.tar.xz"
fi
mkdir -p "$CONFIG/Desktop"
cat > "$CONFIG/Desktop/firefox.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Firefox
Exec=/config/firefox/firefox
Icon=/config/firefox/browser/chrome/icons/default/default128.png
Terminal=false
Categories=Network;WebBrowser;
EOF
chmod +x "$CONFIG/Desktop/firefox.desktop"

if [[ -n "${FILE_BRIDGE_TOKEN:-}" ]]; then
  mkdir -p "$ROOT/persistent/bin"
  if [[ ! -x "$ROOT/persistent/bin/cloudflared" ]]; then
    curl -fL --retry 5 https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o "$ROOT/persistent/bin/cloudflared"
    chmod +x "$ROOT/persistent/bin/cloudflared"
  fi
  pkill -f 'cloudflared tunnel --url http://127.0.0.1:3100' 2>/dev/null || true
  nohup "$ROOT/persistent/bin/cloudflared" tunnel --no-autoupdate --url http://127.0.0.1:3100 > "$ROOT/persistent/cloudflared.log" 2>&1 &
  for _ in {1..30}; do
    TUNNEL_URL="$(grep -Eo 'https://[-a-z0-9]+\.trycloudflare\.com' "$ROOT/persistent/cloudflared.log" | tail -1 || true)"
    [[ -n "$TUNNEL_URL" ]] && break
    sleep 1
  done
  if [[ -n "${TUNNEL_URL:-}" ]]; then
    curl -fsS -X POST https://homework-study-work-app.vercel.app/api/tunnel-register -H "Authorization: Bearer $FILE_BRIDGE_TOKEN" -H 'Content-Type: application/json' --data "{\"url\":\"$TUNNEL_URL\"}" >/dev/null
    echo "Protected Vercel desktop relay registered."
  else
    echo "Desktop relay did not return an address yet."
  fi
fi

echo "Homework audio/video desktop started on port 3000."
