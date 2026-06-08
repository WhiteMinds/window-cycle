# Roadmap

Last updated: 2026-06-08

## Near-Term Fixes

- Add diagnostics for event tap creation failure.
- Add a visible empty/no-windows state that fits the compact UI.
- Add configurable shortcuts.

## Window Behavior

- Add AXObserver-based cache instead of refreshing only on open.
- Improve ordering with recent/focused behavior.
- Investigate public CGWindow matching for z-order hints.
- Keep private CGS/SLS Spaces APIs out of the MVP.

## UI

- Keep the current compact list direction.
- Avoid adding key hints until they are functional.
- Possible future key hint behavior:
  - quick filtering
  - direct row jump
  - number/letter shortcuts

## Packaging

- Keep local self-signed signing for development.
- Document GitHub release caveats if distributing without Developer ID.
- Improve DMG presentation with a background and layout.
- Add optional notarization support for Developer ID users.

## Privacy/Trust

- Add a README privacy section:
  - no keystroke recording
  - event tap only reacts to configured shortcuts and navigation keys while the switcher is visible
  - no network behavior unless an updater is later added
