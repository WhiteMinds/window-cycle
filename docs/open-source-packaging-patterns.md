# Open Source Packaging Patterns

Last updated: 2026-06-08

This note captures a few open-source macOS app repo layouts that are useful to
borrow from when WindowCycle moves from local prototype to public release.

## Surveyed Repos

### alt-tab-macos

Repository: https://github.com/lwouis/alt-tab-macos

Observed structure:

- `scripts/` for build and release helpers
- `docs/` for user-facing notes
- `changelog.md`
- `appcast.xml`
- `release.config.js`
- `.github/workflows/ci_cd.yml`

Useful pattern:

- release automation is explicit and separate from app code
- Sparkle/appcast support is already part of the repo shape
- root stays busy, but the release surface is still discoverable

### Ice

Repository: https://github.com/jordanbaird/Ice

Observed structure:

- `README.md`
- `LICENSE`
- `Resources/`
- `Ice.xcodeproj`
- `.github/workflows/lint.yml`

Useful pattern:

- very lean root for a small Swift/AppKit app
- no extra release machinery until it is actually needed

### CodeEdit

Repository: https://github.com/CodeEditApp/CodeEdit

Observed structure:

- `Documentation.docc`
- `Configs/`
- `Resources/`
- multiple targets and test bundles
- `AppCast/`
- rich `.github/workflows/`

Useful pattern:

- when an app grows, docs and release metadata get their own homes
- appcast/update plumbing can live beside the app without polluting source code

### syncthing-macos

Repository: https://github.com/syncthing/syncthing-macos

Observed structure:

- `Makefile`
- `syncthing.xcodeproj`
- `syncthing.xcworkspace`
- `cmd/`
- `extra/`
- `.github/workflows/build-syncthing-macos.yml`
- `.github/workflows/generate-appcast.yml`

Useful pattern:

- a single top-level orchestration file is handy once release steps grow
- separate build and appcast workflows keep automation readable

## Takeaways For WindowCycle

- Keep the root focused: `README.md`, `LICENSE`, `CHANGELOG.md`, `VERSION`,
  `docs/`, `Scripts/`, and `.github/workflows/`.
- Keep release scripts explicit and easy to run locally.
- Hold off on Sparkle/appcast until automatic updates are real.
- If release packaging grows, add a dedicated release workflow before adding
  more shell glue.
