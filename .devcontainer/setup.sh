#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA="$ROOT/persistent"

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y   xfce4 xfce4-terminal xfce4-goodies dbus-x11 xvfb x11vnc novnc websockify epiphany-browser   thunar mousepad xarchiver gvfs gvfs-backends fonts-liberation ffmpeg libavcodec-extra   wget gnupg ca-certificates

# Ubuntu's own repos only offer Firefox as a snap, which doesn't run reliably
# inside a container. Install the real .deb build from Mozilla's official APT repo.
sudo install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- |   sudo tee /etc/apt/keyrings/packages.mozilla.org.asc >/dev/null

echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" |   sudo tee /etc/apt/sources.list.d/mozilla.list >/dev/null

echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla >/dev/null

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y firefox ffmpeg libavcodec-extra

mkdir -p "$DATA" "$DATA/Downloads" "$DATA/Documents" "$DATA/Desktop" "$DATA/config" "$DATA/cache" "$DATA/share"
chmod +x scripts/start-vm.sh scripts/stop-vm.sh

cat >"$DATA/config/user-dirs.dirs" <<EOF
XDG_DESKTOP_DIR="$DATA/Desktop"
XDG_DOWNLOAD_DIR="$DATA/Downloads"
XDG_DOCUMENTS_DIR="$DATA/Documents"
XDG_PICTURES_DIR="$DATA"
XDG_MUSIC_DIR="$DATA"
XDG_VIDEOS_DIR="$DATA"
XDG_TEMPLATES_DIR="$DATA"
XDG_PUBLICSHARE_DIR="$DATA"
EOF

PASSFILE="$DATA/vnc.pass"
VNC_PASSWORD="123456"
x11vnc -storepasswd "$VNC_PASSWORD" "$PASSFILE" >/dev/null
printf '\nVNC password: %s\nPersistent storage: %s\n' "$VNC_PASSWORD" "$DATA"
printf '\nHomework Linux is ready. Run: bash scripts/start-vm.sh\n\n'
