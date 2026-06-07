# Agent Notes

This project is a native macOS prototype for a current-app window switcher.

## Current Goal

Implement one feature only:

- `Cmd + \`` / `Cmd + Shift + \`` switch between windows of the current frontmost app.

Keep the scope focused on current-app window switching unless explicitly requested.

## Important Commands

```sh
swift build
Scripts/build-app.sh
open .build/WindowCycle.app
pkill -x WindowCycle
```

The build script uses `WindowCycle Local Code Signing` when available and falls back to ad-hoc signing.

## Architecture Pointers

- `AppController.swift`: lifecycle and wiring
- `HotKeyService.swift`: Carbon hotkeys
- `AXWindowService.swift`: Accessibility window enumeration/activation
- `ModifierReleaseMonitor.swift`: Command release, Escape, arrow navigation, event consumption
- `SwitcherPanelController.swift`: AppKit `NSPanel`
- `SwitcherView.swift`: SwiftUI list content

Read `docs/current-state.md` and `docs/architecture.md` before making changes.

## Constraints

- Prefer public macOS APIs.
- Do not use private CGS/SLS Spaces APIs in the MVP without an explicit decision.
- Do not copy third-party code/assets/resources.
- Keep the app lightweight and agent-style (`LSUIElement = true`).
- After code changes, run `swift build`.
- After app bundle/signing changes, run `Scripts/build-app.sh`.
- If the app is already running, restart it with `pkill -x WindowCycle` then `open .build/WindowCycle.app`.

## UX Notes

- The first forward open should select the second row when multiple windows exist, because the first row is the current/focused window.
- `Up` and `Down` should move exactly one row.
- `Up`, `Down`, and `Esc` should be consumed while the switcher is visible so the underlying IDE/app does not also receive them.
- The panel should appear in the upper visible screen region, not dead center.
- Avoid non-functional key hints. Add them back only if quick filtering/jump behavior is implemented.
