# Architecture

Last updated: 2026-06-20

The app intentionally uses public APIs first. The one sanctioned exception is the optional window preview feature, which uses the private `_AXUIElementGetWindow` (AX→CGWindowID) bridge and the private SkyLight `CGSHWCaptureWindowList` capture API. Private CGS/SLS Spaces APIs are not used.

## Main Components

### `AppController`

Owns the app lifecycle and wires services together:

- starts hotkeys
- starts event monitoring
- shows and hides the switcher panel
- activates the selected window
- keeps `ModifierReleaseMonitor` informed about whether a switcher session is active, so keyboard events are only consumed while needed
- delays initial panel presentation by about 125ms, allowing quick press/release switching without a visible panel flash

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
- mouse hover selects a row
- mouse click selects and activates the row

The previous key-hint column was removed because it had no implemented behavior yet.

### Window Previews

Optional, off by default, opt-in via Settings.

- `PrivateWindowAPI` declares the private bridges: `AXUIElement.cgWindowID()` via `_AXUIElementGetWindow`, and `WindowServer.captureImage(of:)` via SkyLight `CGSHWCaptureWindowList`. SkyLight is linked through `Package.swift` linker flags.
- `WindowThumbnailService` captures images on a background queue and caches them by `CGWindowID`. The cache is stale-while-revalidate: a cached image shows immediately, and a window is only re-captured once older than a short refresh interval. Results are delivered on the main actor via `onCapture`.
- `ScreenRecordingPermission` wraps the public `CGPreflightScreenCaptureAccess`/`CGRequestScreenCaptureAccess`. Permission is requested only when the user enables previews.
- `PreviewSettings` persists the three options (enabled, position left/right, mode selected-only/all) in `UserDefaults`.
- `SettingsWindowController` hosts the SwiftUI settings form.
- `AppController` pre-warms thumbnails on switcher open (during the ~125ms panel delay), capturing the selected window first.
- In "all windows" mode `SwitcherView` renders a per-row thumbnail inside the list.
- In "selected window only" mode `PreviewPanelController` shows a separate floating panel beside the list (left or right), so the list panel's size and layout are never affected by previews. `SwitcherPanelController` owns it and positions it relative to its own frame.

### `ModifierReleaseMonitor`

Uses:

- `CGEvent.tapCreate` with `.defaultTap` for flags/keyDown
- `NSEvent` monitors as fallback paths

Responsibilities:

- detect Command release and trigger activation
- consume `Up`, `Down`, and `Esc` when a switcher session is active
- consume repeated grave key events while Command is held, using macOS key repeat to keep cycling
- ignore navigation keys when no switcher session is active
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
- Settings UI covers window previews only; other behavior is not yet configurable.
- No cross-Space/full-screen private API behavior.
- Window ordering is focused-first plus AX order, not a full recent/z-order model.
- Input Monitoring onboarding is not polished.
- DMG is not notarized.
