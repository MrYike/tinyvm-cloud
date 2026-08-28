#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  xfce4 xfce4-terminal xfce4-goodies dbus-x11 xvfb x11vnc novnc websockify epiphany-browser \
  thunar mousepad xarchiver gvfs gvfs-backends fonts-liberation \
  wget gnupg ca-certificates

# Ubuntu's own repos only offer Firefox as a snap, which doesn't run reliably
# inside a container. Install the real .deb build from Mozilla's official APT repo.
sudo install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | \
  sudo tee /etc/apt/keyrings/packages.mozilla.org.asc >/dev/null

echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | \
  sudo tee /etc/apt/sources.list.d/mozilla.list >/dev/null

echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla >/dev/null

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y firefox

mkdir -p "$HOME/tinyvm-data"
chmod +x scripts/start-vm.sh scripts/stop-vm.sh

PASSFILE="$HOME/tinyvm-data/vnc.pass"
if [[ ! -f "$PASSFILE" ]]; then
  VNC_PASSWORD="123456"
  x11vnc -storepasswd "$VNC_PASSWORD" "$PASSFILE" >/dev/null
  printf '\nVNC password (needed to open the desktop): %s\n(saved to %s)\n' "$VNC_PASSWORD" "$PASSFILE"
fi

printf '\nTinyVM Linux is ready. Run: bash scripts/start-vm.sh\n\n'
