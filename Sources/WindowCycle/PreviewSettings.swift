import Foundation
import CoreGraphics
import Combine

/// Which side of the window list the preview is shown on.
///
/// `top`/`bottom` only apply to the standalone preview in "selected window
/// only" mode; the in-list thumbnails of "all windows" mode use the horizontal
/// sides only.
enum PreviewPosition: String, CaseIterable, Identifiable {
    case left
    case right
    case top
    case bottom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        case .top: return "Top"
        case .bottom: return "Bottom"
        }
    }

    /// Whether an in-list thumbnail should sit at the leading edge of the row.
    var isLeading: Bool {
        self == .left || self == .top
    }

    /// The positions that make sense for the given preview mode.
    static func available(for mode: PreviewMode) -> [PreviewPosition] {
        switch mode {
        case .selectedOnly: return allCases
        case .all: return [.left, .right]
        }
    }
}

/// How many window previews are shown at once.
enum PreviewMode: String, CaseIterable, Identifiable {
    /// A single large preview of the currently selected window.
    case selectedOnly
    /// A thumbnail beside every window in the list.
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .selectedOnly: return "Selected window only"
        case .all: return "All windows"
        }
    }
}

/// Preview image size. Scales both the standalone selected-window panel and the
/// in-list thumbnails of "all windows" mode.
enum PreviewSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large
    case extraLarge
    case huge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        case .extraLarge: return "XL"
        case .huge: return "XXL"
        }
    }

    /// Size of the standalone preview in "selected window only" mode.
    var paneSize: CGSize {
        switch self {
        case .small: return CGSize(width: 200, height: 130)
        case .medium: return CGSize(width: 260, height: 168)
        case .large: return CGSize(width: 340, height: 220)
        case .extraLarge: return CGSize(width: 440, height: 284)
        case .huge: return CGSize(width: 560, height: 360)
        }
    }

    /// Size of the per-row thumbnail in "all windows" mode.
    var rowThumbnail: CGSize {
        switch self {
        case .small: return CGSize(width: 72, height: 42)
        case .medium: return CGSize(width: 96, height: 54)
        case .large: return CGSize(width: 132, height: 76)
        case .extraLarge: return CGSize(width: 176, height: 100)
        case .huge: return CGSize(width: 224, height: 128)
        }
    }

    /// Row height in "all windows" mode, sized to fit `rowThumbnail`.
    var rowHeight: CGFloat {
        switch self {
        case .small: return 50
        case .medium: return 62
        case .large: return 84
        case .extraLarge: return 110
        case .huge: return 140
        }
    }
}

/// User-configurable window preview options, persisted in `UserDefaults`.
@MainActor
final class PreviewSettings: ObservableObject {
    private enum Key {
        static let enabled = "preview.enabled"
        static let position = "preview.position"
        static let mode = "preview.mode"
        static let size = "preview.size"
    }

    private let defaults: UserDefaults

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Key.enabled) }
    }

    @Published var position: PreviewPosition {
        didSet { defaults.set(position.rawValue, forKey: Key.position) }
    }

    @Published var mode: PreviewMode {
        didSet {
            defaults.set(mode.rawValue, forKey: Key.mode)
            normalizePositionForMode()
        }
    }

    @Published var size: PreviewSize {
        didSet { defaults.set(size.rawValue, forKey: Key.size) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Previews are opt-in: off by default so the base app needs no Screen
        // Recording permission until the user enables them. Default layout is
        // a single selected-window preview below the list.
        isEnabled = defaults.bool(forKey: Key.enabled)
        position = defaults.string(forKey: Key.position)
            .flatMap(PreviewPosition.init(rawValue:)) ?? .bottom
        mode = defaults.string(forKey: Key.mode)
            .flatMap(PreviewMode.init(rawValue:)) ?? .selectedOnly
        size = defaults.string(forKey: Key.size)
            .flatMap(PreviewSize.init(rawValue:)) ?? .medium
        normalizePositionForMode()
    }

    /// Keeps `position` within the set valid for the current `mode`, mapping a
    /// vertical position to its horizontal equivalent for "all windows" mode.
    private func normalizePositionForMode() {
        guard !PreviewPosition.available(for: mode).contains(position) else {
            return
        }
        position = position.isLeading ? .left : .right
    }
}
