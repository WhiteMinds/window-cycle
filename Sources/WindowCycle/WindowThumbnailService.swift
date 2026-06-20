import AppKit

/// Captures and caches window preview images.
///
/// Captures run on a background queue and results are delivered on the main
/// actor via ``onCapture``. The cache persists across switcher sessions so a
/// previously seen window shows instantly (stale-while-revalidate); a window's
/// image is only re-captured once it is older than ``refreshInterval``.
@MainActor
final class WindowThumbnailService {
    /// Carries an immutable `CGImage` across the queue boundary. `CGImage` is
    /// thread-safe and immutable, so this is safe to mark `@unchecked Sendable`.
    private struct CaptureResult: @unchecked Sendable {
        let windowID: CGWindowID
        let cgImage: CGImage
    }

    private struct Entry {
        let image: NSImage
        let capturedAt: Date
    }

    /// How long a cached image is considered fresh enough to skip re-capture.
    private static let refreshInterval: TimeInterval = 0.4

    /// Invoked on the main actor whenever a window's image is (re)captured.
    var onCapture: ((CGWindowID, NSImage) -> Void)?

    private var cache: [CGWindowID: Entry] = [:]
    private let queue = DispatchQueue(
        label: "app.windowcycle.thumbnails",
        qos: .userInitiated,
        attributes: .concurrent
    )

    /// Returns the cached image for a window, if any.
    func image(for windowID: CGWindowID) -> NSImage? {
        cache[windowID]?.image
    }

    /// Drops cached images for windows that are no longer present.
    func prune(keeping windowIDs: Set<CGWindowID>) {
        cache = cache.filter { windowIDs.contains($0.key) }
    }

    /// Captures the given windows (in priority order) that are missing or stale.
    ///
    /// Fresh cache entries are skipped so rapid re-opens and selection moves do
    /// not re-capture the same window repeatedly.
    func prefetch(_ windowIDs: [CGWindowID]) {
        let now = Date()
        let stale = windowIDs.filter { id in
            guard let entry = cache[id] else { return true }
            return now.timeIntervalSince(entry.capturedAt) >= Self.refreshInterval
        }

        for windowID in stale {
            queue.async { [weak self] in
                guard let cgImage = WindowServer.captureImage(of: windowID) else {
                    return
                }
                let result = CaptureResult(windowID: windowID, cgImage: cgImage)
                Task { @MainActor [weak self] in
                    self?.store(result)
                }
            }
        }
    }

    private func store(_ result: CaptureResult) {
        let cgImage = result.cgImage
        let image = NSImage(
            cgImage: cgImage,
            size: NSSize(width: cgImage.width, height: cgImage.height)
        )
        cache[result.windowID] = Entry(image: image, capturedAt: Date())
        onCapture?(result.windowID, image)
    }
}
