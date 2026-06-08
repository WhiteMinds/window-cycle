#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT_DIR"

if [[ ! -f "$ROOT_DIR/Resources/AppIcon.icns" ]]; then
  swift "$ROOT_DIR/Scripts/generate-app-icon.swift" "$ROOT_DIR/Resources/AppIcon.icns"
fi

BUILD_CONFIGURATION=release \
APP_DIR="$ROOT_DIR/dist/WindowCycle.app" \
"$ROOT_DIR/Scripts/build-app.sh"

echo "Release app: $ROOT_DIR/dist/WindowCycle.app"
