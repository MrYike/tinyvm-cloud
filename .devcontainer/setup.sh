#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/persistent/webtop/Downloads"
chmod +x "$ROOT/scripts/start-vm.sh" "$ROOT/scripts/stop-vm.sh"

echo "Homework Webtop storage is ready at $ROOT/persistent/webtop"
