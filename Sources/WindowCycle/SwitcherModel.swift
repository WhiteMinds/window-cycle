import Foundation
import Combine

@MainActor
final class SwitcherModel: ObservableObject {
    @Published var appName = "Current App"
    @Published var statusText = ""
    @Published var windows: [AppWindow] = []
    @Published var selectedIndex = 0

    var selectedWindow: AppWindow? {
        guard windows.indices.contains(selectedIndex) else {
            return nil
        }
        return windows[selectedIndex]
    }

    func setWindows(_ windows: [AppWindow], direction: WindowCycleDirection) {
        self.windows = windows
        appName = windows.first?.appName ?? "Current App"
        statusText = windows.isEmpty ? "No windows found for the current app" : ""

        switch direction {
        case .next:
            selectedIndex = windows.isEmpty ? 0 : 0
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
}
