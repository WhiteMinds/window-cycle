# Contributing

Thanks for helping improve WindowCycle.

## Local Setup

```sh
swift build
Scripts/build-app.sh
Scripts/install-local.sh
```

The app needs Accessibility permission. Input Monitoring may be needed for the active event tap that consumes navigation keys while the switcher is visible.

## Pull Request Checklist

- Run `swift build`.
- For packaging changes, run `Scripts/build-release.sh` and `Scripts/build-dmg.sh`.
- Keep public docs free of local machine paths and private research notes.
- Prefer public macOS APIs unless a change is explicitly marked experimental.
