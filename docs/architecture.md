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
- move the focused window to the first list position
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
- ignore navigation keys when the switcher is not visible
- re-enable the event tap if macOS disables it after a timeout

## Current Limitations

- No AXObserver cache yet; windows are refreshed when the switcher opens.
- No settings UI.
- No DMG/release automation yet.
- No cross-Space/full-screen private API behavior.
- Window ordering is focused-first plus AX order, not a full recent/z-order model.
- Input Monitoring onboarding is not polished.
