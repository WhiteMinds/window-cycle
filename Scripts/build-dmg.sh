#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_MARKETING_VERSION="0.1.1"
if [[ -f "$ROOT_DIR/VERSION" ]]; then
  DEFAULT_MARKETING_VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
fi
MARKETING_VERSION="${MARKETING_VERSION:-$DEFAULT_MARKETING_VERSION}"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/WindowCycle.app"
DMG_ROOT="$ROOT_DIR/.build/dmg-root"
DMG_PATH="$DIST_DIR/WindowCycle-$MARKETING_VERSION.dmg"

cd "$ROOT_DIR"

"$ROOT_DIR/Scripts/build-release.sh"

rm -rf "$DMG_ROOT" "$DMG_PATH"
mkdir -p "$DMG_ROOT" "$DIST_DIR"

cp -R "$APP_DIR" "$DMG_ROOT/WindowCycle.app"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
  -volname "WindowCycle" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "DMG: $DMG_PATH"
