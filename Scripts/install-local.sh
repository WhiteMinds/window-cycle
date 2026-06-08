#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="WindowCycle"
SOURCE_APP="$ROOT_DIR/dist/$APP_NAME.app"
TARGET_APP="/Applications/$APP_NAME.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

"$ROOT_DIR/Scripts/build-release.sh"

osascript -e "quit app \"$APP_NAME\"" >/dev/null 2>&1 || true
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

rm -rf "$TARGET_APP"
ditto "$SOURCE_APP" "$TARGET_APP"
"$LSREGISTER" -f "$TARGET_APP"

open "$TARGET_APP"

echo "Installed and launched $TARGET_APP"
