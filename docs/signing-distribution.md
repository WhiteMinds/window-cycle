# Permissions, Signing, and Distribution

Last updated: 2026-06-08

## Permissions

The app needs macOS privacy permissions:

- Accessibility: enumerate windows and raise selected windows with AX APIs.
- Input Monitoring: may be needed for the active event tap that consumes arrow/Escape key events.

TCC permissions are tied to code identity, not just app name. A rebuilt app may lose permission matching if its code identity changes.

## Local Self-Signed Signing

This machine has a local self-signed code signing identity:

```text
WindowCycle Local Code Signing
```

The build script automatically uses it when available:

```sh
Scripts/build-app.sh
```

Expected signature shape:

```text
Identifier=dev.local.WindowCycle
Authority=WindowCycle Local Code Signing
designated => identifier "dev.local.WindowCycle" and certificate leaf = H"..."
```

This is good for local development. It should keep Accessibility/Input Monitoring permissions more stable than ad-hoc signing, as long as the same certificate/private key and bundle identifier are reused.

## Ad-Hoc Signing Problem

Ad-hoc signing often produces a designated requirement tied to `cdhash`. Code changes can change the hash, so macOS may treat the rebuild as a new app for privacy permissions.

## Public Distribution Options

### No-Cost Prototype Distribution

Viable for small/technical audiences:

- open source on GitHub
- users build locally
- optional experimental self-signed DMG

Downsides:

- Gatekeeper warnings are scary
- no notarization
- users may need right-click Open or System Settings Open Anyway
- users should not be asked to install/trust the developer's self-signed root certificate

### Proper Public DMG Distribution

Best user experience, but costs Apple Developer Program membership:

- Developer ID Application certificate
- hardened runtime
- notarization
- staple notarization ticket
- signed/notarized DMG on GitHub Releases

Expected user flow:

1. Download DMG from GitHub Releases.
2. Open DMG.
3. Drag app to `/Applications`.
4. First launch shows the normal Gatekeeper downloaded-from-Internet confirmation.
5. App guides user through Accessibility/Input Monitoring permissions.

## Current Recommendation

For now:

- keep local self-signed signing for development
- open source the project
- document local build/sign instructions
- optionally ship an experimental, not-notarized DMG for advanced users

Consider Developer ID only after the app has enough real users to justify the yearly cost.

## Release TODO

- choose a final bundle identifier, for example `com.example.WindowCycle`
- add a real app icon
- add release build script
- add DMG creation script
- add permission onboarding UI
- add a privacy note explaining that keyboard events are not recorded
- decide whether to include a self-signed experimental DMG in GitHub Releases
