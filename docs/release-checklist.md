# Release Checklist

Last updated: 2026-06-08

## Project Structure Notes

See [Open Source Packaging Patterns](open-source-packaging-patterns.md) for a short survey of comparable repo layouts.

Comparable open-source macOS app projects commonly include:

- `LICENSE`
- `README.md`
- `CHANGELOG.md` or release notes
- a version source such as `VERSION`
- `docs/`
- release/build scripts
- optional GitHub Actions CI
- optional Sparkle `appcast.xml` when automatic updates are implemented

WindowCycle currently uses the no-cost local/self-signed distribution path, so Sparkle appcasts and notarization automation are intentionally not included yet.

## Preflight

```sh
git status --short
swift build
Scripts/build-release.sh
Scripts/build-dmg.sh
codesign --verify --strict --verbose=2 dist/WindowCycle.app
hdiutil imageinfo "dist/WindowCycle-$(cat VERSION).dmg"
```

Before publishing, also scan public docs for accidental local paths, private research notes, and machine-specific identifiers.

## GitHub Release

The release workflow in `.github/workflows/release.yml` creates a draft GitHub
Release on tag push.

Current behavior:

- tag push `v<version>`
- verify the tag version matches `VERSION`
- import the self-signed codesigning identity from environment secrets
- build `dist/WindowCycle-<VERSION>.dmg`
- create a draft GitHub Release with `CHANGELOG.md` notes

Required `release` environment secrets:

- `WINDOWCYCLE_CODESIGN_P12_BASE64`
- `WINDOWCYCLE_CODESIGN_PASSWORD`

For a smoother public release flow later, add Developer ID signing,
notarization, stapling, and then publish the notarized DMG from the same
workflow.
