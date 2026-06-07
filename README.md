# Current App Window Switcher

Prototype for a current-application window switcher:

- `Cmd + \`` shows windows for the current frontmost app and cycles forward.
- `Cmd + Shift + \`` cycles backward.
- Releasing Command activates the selected window when the event tap is available.
- Escape hides the switcher.
- A menu bar status item provides Show, Hide, and Quit actions.

This is a prototype, not a finished product. It intentionally uses public APIs first:

- Carbon `RegisterEventHotKey`
- AppKit `NSPanel`
- SwiftUI panel content
- Accessibility / AX window enumeration and `AXRaise`
- `CGEvent.tapCreate` for Command release and consuming switcher navigation keys
- `NSEvent` global/local monitors as fallback paths

## Requirements

- Xcode 26.5 or newer
- Accessibility permission for the app/executable
- Input Monitoring may be needed for consuming arrow/Escape key events

## Run From Xcode

Open the package in Xcode:

```sh
open Package.swift
```

Run the `WindowCycle` executable target.

## Run From Terminal

```sh
swift run WindowCycle
```

The executable will ask for Accessibility permission. If arrow/Escape handling does not work or is not consumed by the switcher, grant Input Monitoring permission too or run the bundled app build below.

## Build A Local .app Bundle

```sh
Scripts/build-app.sh
open .build/WindowCycle.app
```

The bundle sets `LSUIElement = true`, so it behaves like an agent app without a normal Dock icon.
Use the menu bar icon to quit the app if the switcher panel gets stuck.

The build script signs the app bundle with the stable bundle identifier
`dev.local.WindowCycle`. On this machine it uses the local self-signed identity
`WindowCycle Local Code Signing` when available, and falls back to ad-hoc signing
otherwise:

```sh
Scripts/build-app.sh
```

You can override the signing identity explicitly:

```sh
CODESIGN_IDENTITY="Apple Development: Your Name (...)" Scripts/build-app.sh
```

macOS privacy permissions are tied to code identity, not just the visible app
name. With ad-hoc signing, code changes can still produce a new identity, so an
older enabled `WindowCycle` entry in Accessibility may not match a freshly
rebuilt app.

## Current Limitations

- No settings UI yet.
- No AXObserver cache yet; it refreshes the current app windows when the hotkey opens the panel.
- Cross-Space and full-screen behavior is not handled with private CGS/SLS APIs.
- Window sorting is currently AX order, not CGWindow z-order.
- Keyboard conflict handling is not polished.

## Docs

- [Current state](docs/current-state.md)
- [Architecture](docs/architecture.md)
- [Permissions, signing, and distribution](docs/signing-distribution.md)
- [Roadmap](docs/roadmap.md)
