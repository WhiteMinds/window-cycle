# Current App Window Switcher

Prototype for a Contexts-like single feature:

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
- Listen-only `CGEvent.tapCreate` for Command release
- `NSEvent` global/local monitors as a fallback for Escape and modifier release

## Requirements

- Xcode 26.5 or newer
- Accessibility permission for the app/executable
- Input Monitoring may be needed for Command-release activation

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

The executable will ask for Accessibility permission. If Command-release activation does not work, grant Input Monitoring permission too or run the bundled app build below.

## Build A Local .app Bundle

```sh
Scripts/build-app.sh
open .build/WindowCycle.app
```

The bundle sets `LSUIElement = true`, so it behaves like an agent app without a normal Dock icon.
Use the menu bar icon to quit the app if the switcher panel gets stuck.

The build script signs the app bundle with the stable bundle identifier
`dev.local.WindowCycle`. By default it uses ad-hoc signing because this machine
does not currently have a valid code signing identity:

```sh
Scripts/build-app.sh
```

If you create an Apple Development or local code signing certificate, pass it to
the script so macOS privacy permissions can survive rebuilds more reliably:

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
