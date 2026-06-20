import CoreGraphics

/// Screen Recording (TCC) permission, required for window content capture.
///
/// The base app does not need this permission; it is only requested when the
/// user opts into window previews. Detection and the prompt use the public
/// CoreGraphics APIs (macOS 11+); the capture itself uses the private
/// `WindowServer` API.
enum ScreenRecordingPermission {
    /// Whether the permission is currently granted, without prompting.
    static func isGranted() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Prompts for the permission if it has not been granted yet.
    ///
    /// Returns the current grant state. The very first call may show the system
    /// prompt; afterwards macOS may require the app to be relaunched before a
    /// freshly granted permission takes effect.
    @discardableResult
    static func request() -> Bool {
        CGRequestScreenCaptureAccess()
    }
}
