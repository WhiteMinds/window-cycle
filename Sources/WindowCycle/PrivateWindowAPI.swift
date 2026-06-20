import ApplicationServices
import CoreGraphics

// MARK: - Accessibility -> CGWindowID bridge

/// Returns the `CGWindowID` backing an `AXUIElement`.
///
/// This attribute is missing from the public `ApplicationServices.HIServices`
/// surface, so it is declared here against the private SPI. It is a private
/// Accessibility function (not a CGS/SLS Spaces API) and resolves through the
/// already-linked `ApplicationServices` framework. It is the same bridge used
/// by alt-tab, yabai, and similar tools, and is stable across macOS 10.10+.
@_silgen_name("_AXUIElementGetWindow") @discardableResult
private func _AXUIElementGetWindow(
    _ element: AXUIElement,
    _ identifier: UnsafeMutablePointer<CGWindowID>
) -> AXError

extension AXUIElement {
    /// Resolves the `CGWindowID` for this element, or `nil` when unavailable.
    func cgWindowID() -> CGWindowID? {
        var id = CGWindowID(0)
        guard _AXUIElementGetWindow(self, &id) == .success, id != 0 else {
            return nil
        }
        return id
    }
}

// MARK: - Window Server capture (SkyLight)

typealias CGSConnectionID = UInt32

/// Options accepted by `CGSHWCaptureWindowList`. Raw values mirror the private
/// SkyLight definitions.
struct CGSWindowCaptureOptions: OptionSet {
    let rawValue: UInt32
    static let ignoreGlobalClipShape = CGSWindowCaptureOptions(rawValue: 1 << 11)
    /// On a retina display, nominal resolution is 1/4 of best resolution.
    static let nominalResolution = CGSWindowCaptureOptions(rawValue: 1 << 9)
    static let bestResolution = CGSWindowCaptureOptions(rawValue: 1 << 8)
    /// Keeps full-size screenshots even when Stage Manager would skew them.
    static let fullSize = CGSWindowCaptureOptions(rawValue: 1 << 19)
}

@_silgen_name("CGSMainConnectionID")
private func CGSMainConnectionID() -> CGSConnectionID

/// Captures images of the windows whose IDs are passed in `windowList`.
///
/// Unlike `CGWindowListCreateImage`, this works on minimized windows and
/// windows on other Spaces, which is exactly what window previews need.
@_silgen_name("CGSHWCaptureWindowList")
private func CGSHWCaptureWindowList(
    _ cid: CGSConnectionID,
    _ windowList: UnsafeMutablePointer<CGWindowID>,
    _ windowCount: UInt32,
    _ options: CGSWindowCaptureOptions
) -> Unmanaged<CFArray>

/// Thin wrapper over the private Window Server capture API.
enum WindowServer {
    /// The shared connection to the Window Server. Initialized lazily and
    /// reused for the app lifetime.
    static let connection: CGSConnectionID = CGSMainConnectionID()

    /// Captures a still image of the given window, or `nil` on failure.
    ///
    /// Requires Screen Recording permission to return real content; without it
    /// the call still succeeds but yields wallpaper/placeholder pixels.
    static func captureImage(of windowID: CGWindowID) -> CGImage? {
        var id = windowID
        let array = CGSHWCaptureWindowList(
            connection,
            &id,
            1,
            [.ignoreGlobalClipShape, .nominalResolution]
        ).takeRetainedValue() as? [CGImage]
        return array?.first
    }
}
