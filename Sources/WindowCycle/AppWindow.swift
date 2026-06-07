import AppKit
import ApplicationServices

struct AppWindow: Identifiable {
    let id = UUID()
    let pid: pid_t
    let appName: String
    let bundleIdentifier: String?
    let axElement: AXUIElement
    var title: String
    var frame: CGRect
    var isMinimized: Bool
    var indexHint: Int
}

enum WindowCycleDirection {
    case next
    case previous
}

