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

## Current Limitations

- No settings UI yet.
- No AXObserver cache yet; it refreshes the current app windows when the hotkey opens the panel.
- Cross-Space and full-screen behavior is not handled with private CGS/SLS APIs.
- Window sorting is currently AX order, not CGWindow z-order.
- Keyboard conflict handling is not polished.
