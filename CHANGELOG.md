# Changelog

## Release Install Note

The current GitHub Releases DMG is self-signed/not notarized. On first launch,
macOS may show "`WindowCycle` Not Opened" or "Apple could not verify
`WindowCycle` is free of malware." To open it, click `Done`, then go to
`System Settings` -> `Privacy & Security` -> `Security`, click `Open Anyway`
for WindowCycle, and confirm with `Open`.

After the app opens, grant Accessibility permission. If arrow navigation or
Escape is not consumed by the switcher, also grant Input Monitoring permission.

## 0.2.0 - 2026-06-20

- Optional window previews, off by default. Toggle in the new Settings window, with left/right/top/bottom placement, "selected window only" (a standalone preview panel) vs "all windows" (per-row thumbnails) modes, and five sizes (S–XXL). Requires Screen Recording permission, requested only when previews are enabled.
- Vim-style `J` / `K` keys move the selection alongside the arrow keys.
- Mouse hover no longer changes the selection until the cursor actually moves, so the keyboard stays authoritative and a panel appearing under the cursor does not steal the selection.
- Add a menu bar `Settings…` item.

## 0.1.1 - 2026-06-08

- Delay initial panel display briefly so quick press/release switching does not flash the UI.

## 0.1.0 - 2026-06-08

- Initial public prototype.
- Current-app window list with `Cmd + \`` and `Cmd + Shift + \``.
- Keyboard repeat cycling, arrow-key selection, mouse hover selection, and row click activation.
- Menu bar controls and permissions onboarding.
- Local app bundle, release app, install, and DMG scripts.
