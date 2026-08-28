#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/persistent/webtop"
mkdir -p "$CONFIG"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not ready. Rebuild the Codespace container once."
  exit 1
fi

docker rm -f homework-webtop >/dev/null 2>&1 || true
docker pull lscr.io/linuxserver/webtop:ubuntu-xfce

docker run -d   --name homework-webtop   --restart unless-stopped   --shm-size=1gb   -p 3000:3000   -e PUID="$(id -u)"   -e PGID="$(id -g)"   -e TZ="Australia/Sydney"   -e TITLE="Homework"   -e START_DOCKER="false"   -e SELKIES_AUDIO_ENABLED="true"   -e SELKIES_MICROPHONE_ENABLED="false"   -e SELKIES_ENCODER="x264enc"   -e SELKIES_FRAMERATE="30"   -e SELKIES_H264_CRF="28"   -e SELKIES_USE_CPU="true"   -e SELKIES_IS_MANUAL_RESOLUTION_MODE="true"   -e SELKIES_MANUAL_WIDTH="1280"   -e SELKIES_MANUAL_HEIGHT="720"   -e SELKIES_AUDIO_BITRATE="128000"   -e SELKIES_SECOND_SCREEN="false"   -e SELKIES_ENABLE_SHARING="false"   -e FILE_MANAGER_PATH="/config/Downloads"   -v "$CONFIG:/config"   lscr.io/linuxserver/webtop:ubuntu-xfce

echo "Homework audio/video desktop started on port 3000."
