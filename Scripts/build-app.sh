#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_CONFIGURATION="${BUILD_CONFIGURATION:-debug}"
APP_DIR="${APP_DIR:-$ROOT_DIR/.build/WindowCycle.app}"
BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER:-app.windowcycle.WindowCycle}"
DEFAULT_MARKETING_VERSION="0.1.1"
if [[ -f "$ROOT_DIR/VERSION" ]]; then
  DEFAULT_MARKETING_VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
fi
MARKETING_VERSION="${MARKETING_VERSION:-$DEFAULT_MARKETING_VERSION}"
BUILD_VERSION="${BUILD_VERSION:-2}"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ENTITLEMENTS_FILE="$ROOT_DIR/Resources/WindowCycle.entitlements"
ICON_FILE="$ROOT_DIR/Resources/AppIcon.icns"
LOCAL_CODESIGN_IDENTITY="WindowCycle Local Code Signing"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-}"

if [[ -z "$CODESIGN_IDENTITY" ]]; then
  if security find-identity -v -p codesigning | grep -Fq "\"$LOCAL_CODESIGN_IDENTITY\""; then
    CODESIGN_IDENTITY="$LOCAL_CODESIGN_IDENTITY"
  else
    CODESIGN_IDENTITY="-"
  fi
fi

cd "$ROOT_DIR"
swift build -c "$BUILD_CONFIGURATION"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/.build/$BUILD_CONFIGURATION/WindowCycle" "$MACOS_DIR/WindowCycle"

if [[ -f "$ICON_FILE" ]]; then
  cp "$ICON_FILE" "$RESOURCES_DIR/AppIcon.icns"
fi

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>WindowCycle</string>
  <key>CFBundleIdentifier</key>
  <string>dev.local.WindowCycle</string>
  <key>CFBundleName</key>
  <string>WindowCycle</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.1</string>
  <key>CFBundleVersion</key>
  <string>2</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>Local prototype</string>
</dict>
</plist>
PLIST

plutil -replace CFBundleIdentifier -string "$BUNDLE_IDENTIFIER" "$CONTENTS_DIR/Info.plist"
plutil -replace CFBundleShortVersionString -string "$MARKETING_VERSION" "$CONTENTS_DIR/Info.plist"
plutil -replace CFBundleVersion -string "$BUILD_VERSION" "$CONTENTS_DIR/Info.plist"
plutil -insert CFBundleDisplayName -string "WindowCycle" "$CONTENTS_DIR/Info.plist"
plutil -insert CFBundleIconFile -string "AppIcon" "$CONTENTS_DIR/Info.plist"
plutil -insert LSApplicationCategoryType -string "public.app-category.utilities" "$CONTENTS_DIR/Info.plist"
plutil -insert NSHighResolutionCapable -bool true "$CONTENTS_DIR/Info.plist"

codesign_args=(
  --force
  --sign "$CODESIGN_IDENTITY"
  --identifier "$BUNDLE_IDENTIFIER"
  --options runtime
)

if [[ -f "$ENTITLEMENTS_FILE" ]]; then
  codesign_args+=(--entitlements "$ENTITLEMENTS_FILE")
fi

codesign "${codesign_args[@]}" "$APP_DIR"
codesign --verify --strict --verbose=2 "$APP_DIR"

echo "Built $APP_DIR ($BUILD_CONFIGURATION) with signing identity: $CODESIGN_IDENTITY"
