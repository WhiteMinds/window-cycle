# Current State

Last updated: 2026-06-08

`WindowCycle` is a native macOS prototype for switching between windows of the current frontmost app with `Cmd + \``.

## Implemented Behavior

- `Cmd + \`` starts switching and cycles forward.
- `Cmd + Shift + \`` cycles backward.
- The panel is delayed briefly on hotkey open so a quick press/release can switch to the next window without flashing the UI.
- Holding `Cmd + \`` or `Cmd + Shift + \`` continues moving the selection with macOS key repeat while switching is active.
- When opening forward, the focused/current window is placed first and the default selection moves to the second window when there is more than one window.
- Releasing Command activates the selected window and hides the switcher.
- `Esc` hides the switcher.
- `Up` and `Down` move the selection while switching is active.
- Hovering a row with the mouse selects that window, and clicking a row activates it.
- `Up`, `Down`, repeated grave key presses, and `Esc` are consumed by the event tap while switching is active so the underlying app should not also receive them.
- A menu bar status item provides Show, Settings, Hide, Permissions, and Quit.
- A permissions panel checks Accessibility and keyboard event tap availability and links to System Settings.
- Optional window previews (off by default). When enabled in Settings, each window's image is captured and shown either as a single large preview of the selected window or as a thumbnail beside every row, on the left or right side. Requires Screen Recording permission, requested on enable; degrades to a plain list when not granted.
- The switcher is a compact upper-screen floating panel, not centered.
- Empty AX window titles use the app display name as a fallback for cases like installed browser web apps.
- Window metadata is read with batched AX attributes and keeps subrole, modal, main, focused, minimized, and frame state.
- Non-minimized windows with clearly non-renderable frames are filtered out.

## Current Project Shape

- Swift package executable target: `WindowCycle`
- Bundle path: `.build/WindowCycle.app`
- Bundle identifier: `app.windowcycle.WindowCycle`
- Local signing identity: `WindowCycle Local Code Signing`
- App type: `LSUIElement = true` agent app
- App icon: `Resources/AppIcon.icns`
- Entitlements: `Resources/WindowCycle.entitlements`

## Important Commands

```sh
swift build
Scripts/build-app.sh
Scripts/build-release.sh
Scripts/build-dmg.sh
Scripts/install-local.sh
open .build/WindowCycle.app
pkill -x WindowCycle
```

Open in Xcode:

```sh
open Package.swift
```

## Known Permission Notes

- Accessibility is required for AX window enumeration and `AXRaise`.
- Input Monitoring may be required for the active `CGEvent` tap that consumes arrow/Escape key events.
- If arrow navigation stops working or stops being consumed, check Input Monitoring first.
- For local permission testing, prefer `Scripts/install-local.sh` so the signed app is installed, registered, and launched from `/Applications`.
- If System Settings does not list the app automatically, use the `+` button in the relevant privacy list and choose `WindowCycle.app` from Applications.
- The local self-signed certificate helps preserve TCC permissions on this machine across rebuilds.

## Release Outputs

- Release app: `dist/WindowCycle.app`
- DMG: `dist/WindowCycle-<VERSION>.dmg`
- `dist/` is git-ignored.
- The current DMG is self-signed/not notarized.
