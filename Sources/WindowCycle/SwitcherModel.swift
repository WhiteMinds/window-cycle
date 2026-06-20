import Foundation
import AppKit
import Combine

@MainActor
final class SwitcherModel: ObservableObject {
    @Published var appName = "Current App"
    @Published var statusText = ""
    @Published var windows: [AppWindow] = []
    @Published var selectedIndex = 0
    /// Captured preview images keyed by window ID. Populated asynchronously.
    @Published var thumbnails: [CGWindowID: NSImage] = [:]
    /// Increments on each new switcher session, so views can reset per-session
    /// state such as the mouse-hover baseline.
    @Published private(set) var sessionID = 0

    var selectedWindow: AppWindow? {
        guard windows.indices.contains(selectedIndex) else {
            return nil
        }
        return windows[selectedIndex]
    }

    func thumbnail(for window: AppWindow) -> NSImage? {
        window.cgWindowID.flatMap { thumbnails[$0] }
    }

    func setThumbnail(_ image: NSImage, for windowID: CGWindowID) {
        thumbnails[windowID] = image
    }

    func setWindows(_ windows: [AppWindow], direction: WindowCycleDirection) {
        self.windows = windows
        thumbnails = [:]
        sessionID &+= 1
        appName = windows.first?.appName ?? "Current App"
        statusText = windows.isEmpty ? "No windows found for the current app" : ""

        switch direction {
        case .next:
            selectedIndex = windows.count > 1 ? 1 : 0
        case .previous:
            selectedIndex = windows.isEmpty ? 0 : max(windows.count - 1, 0)
        }
    }

    func moveSelection(_ direction: WindowCycleDirection) {
        guard !windows.isEmpty else {
            selectedIndex = 0
            return
        }

        switch direction {
        case .next:
            selectedIndex = (selectedIndex + 1) % windows.count
        case .previous:
            selectedIndex = (selectedIndex - 1 + windows.count) % windows.count
        }
    }

    func selectWindow(at index: Int) {
        guard windows.indices.contains(index) else {
            return
        }

        selectedIndex = index
    }
}
