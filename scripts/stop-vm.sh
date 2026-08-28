#!/usr/bin/env bash
set -euo pipefail

if command -v docker >/dev/null 2>&1; then
  docker stop homework-webtop >/dev/null 2>&1 || true
fi
