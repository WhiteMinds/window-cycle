# CLAUDE.md

## Project Summary

`WindowCycle` is a Swift/AppKit/SwiftUI macOS agent app for switching between windows of the current frontmost app with `Cmd + \``.

## Build and Run

```sh
swift build
Scripts/build-app.sh
Scripts/build-release.sh
Scripts/build-dmg.sh
open .build/WindowCycle.app
```

Stop the running app:

```sh
pkill -x WindowCycle
```

Open in Xcode:

```sh
open Package.swift
```

## Current Behavior

- `Cmd + \`` opens/cycles forward.
- `Cmd + Shift + \`` cycles backward.
- First forward open selects the second row when multiple windows exist.
- Releasing Command activates the selected window.
- `Esc` cancels.
- `Up` / `Down` (or `K` / `J`, Vim-style) move one row while the switcher is visible.
- `Up` / `Down` / `J` / `K` / `Esc` are consumed while the switcher is visible.
- Mouse hover only changes the selection after the cursor actually moves, so a panel appearing under a stationary cursor does not steal the selection.
- The panel appears near the upper screen region.
- Optional window previews (off by default): toggle in Settings, choose left/right side and "selected window only" vs "all windows".

## Permissions

- Accessibility is required for AX APIs.
- Input Monitoring may be required for the active event tap.
- Screen Recording is required only for window previews; it is requested when the user enables previews in Settings, and previews degrade to a plain list when not granted.
- Local development uses the self-signed identity `WindowCycle Local Code Signing`.
- Release outputs are written to `dist/`.

## Files to Read First

- `docs/current-state.md`
- `docs/architecture.md`
- `docs/signing-distribution.md`
- `docs/open-source-packaging-patterns.md`
- `AGENTS.md`

## Implementation Notes

- Use public APIs first.
- Do not use private CGS/SLS Spaces APIs unless explicitly requested.
- Window previews are the sanctioned exception: they use the private `_AXUIElementGetWindow` (AX→CGWindowID bridge) and the private SkyLight `CGSHWCaptureWindowList` capture API (linked via `Package.swift` linker flags). These were explicitly requested to guarantee capture of minimized/occluded windows. Declarations live in `PrivateWindowAPI.swift`.
- Do not copy third-party code or assets.
- Keep UI compact and operational, not marketing-like.
- Run `swift build` before handing off changes.
