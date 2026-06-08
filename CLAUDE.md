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
- `Up` / `Down` move one row while the switcher is visible.
- `Up` / `Down` / `Esc` are consumed while the switcher is visible.
- The panel appears near the upper screen region.

## Permissions

- Accessibility is required for AX APIs.
- Input Monitoring may be required for the active event tap.
- Local development uses the self-signed identity `WindowCycle Local Code Signing`.
- Release outputs are written to `dist/`.

## Files to Read First

- `docs/current-state.md`
- `docs/architecture.md`
- `docs/signing-distribution.md`
- `AGENTS.md`

## Implementation Notes

- Use public APIs first.
- Do not use private CGS/SLS Spaces APIs unless explicitly requested.
- Do not copy third-party code or assets.
- Keep UI compact and operational, not marketing-like.
- Run `swift build` before handing off changes.
