# Architecture

Last updated: 2026-06-08

The app intentionally uses public APIs first. Private CGS/SLS Spaces APIs are not used in the prototype.

## Main Components

### `AppController`

Owns the app lifecycle and wires services together:

- starts hotkeys
- starts event monitoring
- shows and hides the switcher panel
- activates the selected window
- keeps `ModifierReleaseMonitor` informed about whether the switcher is visible, so keyboard events are only consumed while needed

### `HotKeyService`

Carbon `RegisterEventHotKey` wrapper.

Current shortcuts:

- `Cmd + \`` -> next
- `Cmd + Shift + \`` -> previous

### `AXWindowService`

Uses Accessibility APIs to:

- request/check Accessibility trust
- enumerate current frontmost app windows via `kAXWindowsAttribute`
- read the focused window via `kAXFocusedWindowAttribute`
- batch-read role, subrole, title, position, size, minimized, modal, main, and focused attributes for each window
- move the focused window to the first list position
- fall back to the app display name when `AXTitle` is empty
- skip non-minimized windows whose frame is clearly non-renderable
- activate a selected window with `NSRunningApplication.activate` and `AXRaise`

### `SwitcherModel`

Stores visible windows and selected index.

Important selection rule:

- forward open selects index `1` when there are multiple windows, because index `0` is the current/focused window
- backward open selects the last item

### `SwitcherPanelController`

Owns the `NSPanel`.

Current panel characteristics:

- borderless non-activating panel
- clear AppKit background with SwiftUI regular material content
- floating level
- joins all Spaces and can appear as full-screen auxiliary
- horizontally centered and positioned in the upper visible screen region

### `SwitcherView`

SwiftUI list content inside `NSHostingView`.

Current row shape:

- app name
- app icon
- window title
- selected row uses accent color

The previous key-hint column was removed because it had no implemented behavior yet.

### `ModifierReleaseMonitor`

Uses:

- `CGEvent.tapCreate` with `.defaultTap` for flags/keyDown
- `NSEvent` monitors as fallback paths

Responsibilities:

- detect Command release and trigger activation
- consume `Up`, `Down`, and `Esc` when the switcher is visible
- consume repeated grave key events while Command is held, using macOS key repeat to keep cycling
- ignore navigation keys when the switcher is not visible
- re-enable the event tap if macOS disables it after a timeout

### `PermissionPanelController`

Owns the lightweight permissions onboarding panel.

It shows:

- Accessibility status
- keyboard event tap availability as the practical Input Monitoring indicator
- buttons that open the relevant System Settings panes
- a Finder reveal action for manually adding the installed app when System Settings does not auto-list it
- a refresh action that re-checks Accessibility and restarts the event tap

### Release Scripts

- `Scripts/build-app.sh`: builds and signs a local `.app`; configurable via environment variables.
- `Scripts/build-release.sh`: builds `dist/WindowCycle.app` with release configuration.
- `Scripts/build-dmg.sh`: builds `dist/WindowCycle-<version>.dmg` with the app and an Applications symlink.
- `Scripts/install-local.sh`: builds the release app, copies it to `/Applications`, registers it with Launch Services, and launches it.
- `Scripts/generate-app-icon.swift`: generates `Resources/AppIcon.icns`.

## Current Limitations

- No AXObserver cache yet; windows are refreshed when the switcher opens.
- No settings UI.
- No cross-Space/full-screen private API behavior.
- Window ordering is focused-first plus AX order, not a full recent/z-order model.
- Input Monitoring onboarding is not polished.
- DMG is not notarized.
