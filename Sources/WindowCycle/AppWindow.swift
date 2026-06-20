import AppKit
import ApplicationServices

struct AppWindow: Identifiable {
    let id = UUID()
    let pid: pid_t
    let appName: String
    let bundleIdentifier: String?
    let appIcon: NSImage?
    let axElement: AXUIElement
    var cgWindowID: CGWindowID?
    var title: String
    var subrole: String
    var frame: CGRect
    var isMinimized: Bool
    var isModal: Bool
    var isMain: Bool
    var isFocused: Bool
    var indexHint: Int
}

enum WindowCycleDirection {
    case next
    case previous
}
