import AppKit
import ApplicationServices

enum AXWindowServiceError: Error, CustomStringConvertible {
    case accessibilityNotTrusted
    case noFrontmostApplication
    case attributeReadFailed(String, AXError)
    case invalidAttribute(String)
    case actionFailed(String, AXError)

    var description: String {
        switch self {
        case .accessibilityNotTrusted:
            return "Accessibility permission is not granted."
        case .noFrontmostApplication:
            return "No frontmost application found."
        case let .attributeReadFailed(attribute, error):
            return "Could not read AX attribute \(attribute): \(error.rawValue)."
        case let .invalidAttribute(attribute):
            return "AX attribute \(attribute) had an unexpected value."
        case let .actionFailed(action, error):
            return "AX action \(action) failed: \(error.rawValue)."
        }
    }
}

final class AXWindowService {
    func isAccessibilityTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityIfNeeded() -> Bool {
        // String value of kAXTrustedCheckOptionPrompt; using the literal avoids
        // Swift 6 concurrency warnings for the C global.
        let promptKey = "AXTrustedCheckOptionPrompt"
        let options = [promptKey: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func currentApplicationWindows() throws -> [AppWindow] {
        guard requestAccessibilityIfNeeded() else {
            throw AXWindowServiceError.accessibilityNotTrusted
        }

        guard let application = NSWorkspace.shared.frontmostApplication else {
            throw AXWindowServiceError.noFrontmostApplication
        }

        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        let rawWindows = try readArrayAttribute(
            kAXWindowsAttribute as String,
            from: appElement
        ) as [AXUIElement]
        let focusedWindow = readAXElementAttribute(kAXFocusedWindowAttribute as String, from: appElement)

        let windows = rawWindows.enumerated().compactMap { index, element in
            makeWindowInfo(
                element: element,
                application: application,
                index: index + 1
            )
        }

        return orderWindows(windows, focusedWindow: focusedWindow)
    }

    func activate(_ window: AppWindow) throws {
        if window.isMinimized {
            let minimized: CFBoolean = kCFBooleanFalse!
            AXUIElementSetAttributeValue(
                window.axElement,
                kAXMinimizedAttribute as CFString,
                minimized
            )
        }

        if let app = NSRunningApplication(processIdentifier: window.pid) {
            app.activate(options: [])
        }

        let error = AXUIElementPerformAction(
            window.axElement,
            kAXRaiseAction as CFString
        )

        guard error == .success else {
            throw AXWindowServiceError.actionFailed(kAXRaiseAction, error)
        }
    }

    private func makeWindowInfo(
        element: AXUIElement,
        application: NSRunningApplication,
        index: Int
    ) -> AppWindow? {
        let snapshot = readWindowSnapshot(from: element)
        guard snapshot.role == kAXWindowRole,
              shouldIncludeWindow(snapshot)
        else {
            return nil
        }

        return AppWindow(
            pid: application.processIdentifier,
            appName: application.localizedName ?? "Unknown App",
            bundleIdentifier: application.bundleIdentifier,
            appIcon: application.icon,
            axElement: element,
            title: resolveWindowTitle(snapshot.title, application: application),
            subrole: snapshot.subrole,
            frame: snapshot.frame ?? .zero,
            isMinimized: snapshot.isMinimized,
            isModal: snapshot.isModal,
            isMain: snapshot.isMain,
            isFocused: snapshot.isFocused,
            indexHint: index
        )
    }

    private func shouldIncludeWindow(_ snapshot: WindowAttributeSnapshot) -> Bool {
        guard !snapshot.isMinimized, let frame = snapshot.frame else {
            return true
        }

        return frame.width >= 2 && frame.height >= 2
    }

    private func resolveWindowTitle(_ rawTitle: String, application: NSRunningApplication) -> String {
        let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty {
            return title
        }

        if let appName = application.localizedName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !appName.isEmpty {
            return appName
        }

        return "Untitled Window"
    }

    private func readWindowSnapshot(from element: AXUIElement) -> WindowAttributeSnapshot {
        let attributes = WindowAttributeSnapshot.attributeNames
        var rawValues: CFArray?
        let error = AXUIElementCopyMultipleAttributeValues(
            element,
            attributes as CFArray,
            AXCopyMultipleAttributeOptions(rawValue: 0),
            &rawValues
        )

        guard error == .success, let values = rawValues as? [Any] else {
            return WindowAttributeSnapshot(
                role: readStringAttribute(kAXRoleAttribute as String, from: element),
                subrole: readStringAttribute(kAXSubroleAttribute as String, from: element),
                title: readStringAttribute(kAXTitleAttribute as String, from: element),
                frame: readFrame(from: element),
                isMinimized: readBoolAttribute(kAXMinimizedAttribute as String, from: element) ?? false,
                isModal: readBoolAttribute(kAXModalAttribute as String, from: element) ?? false,
                isMain: readBoolAttribute(kAXMainAttribute as String, from: element) ?? false,
                isFocused: readBoolAttribute(kAXFocusedAttribute as String, from: element) ?? false
            )
        }

        return WindowAttributeSnapshot(values: values)
    }

    private func orderWindows(_ windows: [AppWindow], focusedWindow: AXUIElement?) -> [AppWindow] {
        guard let focusedWindow,
              let focusedIndex = windows.firstIndex(where: { CFEqual($0.axElement, focusedWindow) })
        else {
            return windows.enumerated().map { index, window in
                var window = window
                window.indexHint = index + 1
                return window
            }
        }

        var ordered = windows
        let focused = ordered.remove(at: focusedIndex)
        ordered.insert(focused, at: 0)

        return ordered.enumerated().map { index, window in
            var window = window
            window.indexHint = index + 1
            return window
        }
    }

    private func readArrayAttribute<T>(_ attribute: String, from element: AXUIElement) throws -> [T] {
        var rawValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &rawValue)

        guard error == .success else {
            throw AXWindowServiceError.attributeReadFailed(attribute, error)
        }

        guard let array = rawValue as? [T] else {
            throw AXWindowServiceError.invalidAttribute(attribute)
        }

        return array
    }

    private func readStringAttribute(_ attribute: String, from element: AXUIElement) -> String {
        var rawValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &rawValue)
        guard error == .success else {
            return ""
        }
        return rawValue as? String ?? ""
    }

    private func readBoolAttribute(_ attribute: String, from element: AXUIElement) -> Bool? {
        var rawValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &rawValue)
        guard error == .success else {
            return nil
        }
        return rawValue as? Bool
    }

    private func readAXElementAttribute(_ attribute: String, from element: AXUIElement) -> AXUIElement? {
        var rawValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &rawValue)
        guard error == .success,
              let value = rawValue,
              CFGetTypeID(value) == AXUIElementGetTypeID()
        else {
            return nil
        }
        return (value as! AXUIElement)
    }

    private func readFrame(from element: AXUIElement) -> CGRect? {
        guard
            let position = readCGPointAttribute(kAXPositionAttribute as String, from: element),
            let size = readCGSizeAttribute(kAXSizeAttribute as String, from: element)
        else {
            return nil
        }
        return CGRect(origin: position, size: size)
    }

    private func readCGPointAttribute(_ attribute: String, from element: AXUIElement) -> CGPoint? {
        var rawValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &rawValue)
        guard error == .success, let value = rawValue, CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = value as! AXValue
        var point = CGPoint.zero
        guard AXValueGetType(axValue) == .cgPoint, AXValueGetValue(axValue, .cgPoint, &point) else {
            return nil
        }
        return point
    }

    private func readCGSizeAttribute(_ attribute: String, from element: AXUIElement) -> CGSize? {
        var rawValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &rawValue)
        guard error == .success, let value = rawValue, CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = value as! AXValue
        var size = CGSize.zero
        guard AXValueGetType(axValue) == .cgSize, AXValueGetValue(axValue, .cgSize, &size) else {
            return nil
        }
        return size
    }
}

private struct WindowAttributeSnapshot {
    static let attributeNames = [
        kAXRoleAttribute as String,
        kAXSubroleAttribute as String,
        kAXTitleAttribute as String,
        kAXPositionAttribute as String,
        kAXSizeAttribute as String,
        kAXMinimizedAttribute as String,
        kAXModalAttribute as String,
        kAXMainAttribute as String,
        kAXFocusedAttribute as String
    ]

    let role: String
    let subrole: String
    let title: String
    let frame: CGRect?
    let isMinimized: Bool
    let isModal: Bool
    let isMain: Bool
    let isFocused: Bool

    init(
        role: String,
        subrole: String,
        title: String,
        frame: CGRect?,
        isMinimized: Bool,
        isModal: Bool,
        isMain: Bool,
        isFocused: Bool
    ) {
        self.role = role
        self.subrole = subrole
        self.title = title
        self.frame = frame
        self.isMinimized = isMinimized
        self.isModal = isModal
        self.isMain = isMain
        self.isFocused = isFocused
    }

    init(values: [Any]) {
        let position = Self.pointValue(values[safe: 3])
        let size = Self.sizeValue(values[safe: 4])
        let frame = position.flatMap { position in
            size.map { size in
                CGRect(origin: position, size: size)
            }
        }

        self.init(
            role: Self.stringValue(values[safe: 0]),
            subrole: Self.stringValue(values[safe: 1]),
            title: Self.stringValue(values[safe: 2]),
            frame: frame,
            isMinimized: Self.boolValue(values[safe: 5]),
            isModal: Self.boolValue(values[safe: 6]),
            isMain: Self.boolValue(values[safe: 7]),
            isFocused: Self.boolValue(values[safe: 8])
        )
    }

    private static func stringValue(_ value: Any?) -> String {
        value as? String ?? ""
    }

    private static func boolValue(_ value: Any?) -> Bool {
        if let bool = value as? Bool {
            return bool
        }

        if let number = value as? NSNumber {
            return number.boolValue
        }

        return false
    }

    private static func pointValue(_ value: Any?) -> CGPoint? {
        guard let axValue = axValue(value), AXValueGetType(axValue) == .cgPoint else {
            return nil
        }

        var point = CGPoint.zero
        return AXValueGetValue(axValue, .cgPoint, &point) ? point : nil
    }

    private static func sizeValue(_ value: Any?) -> CGSize? {
        guard let axValue = axValue(value), AXValueGetType(axValue) == .cgSize else {
            return nil
        }

        var size = CGSize.zero
        return AXValueGetValue(axValue, .cgSize, &size) ? size : nil
    }

    private static func axValue(_ value: Any?) -> AXValue? {
        guard let value, !(value is NSNull) else {
            return nil
        }

        let cfValue = value as CFTypeRef
        guard CFGetTypeID(cfValue) == AXValueGetTypeID() else {
            return nil
        }

        return (cfValue as! AXValue)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
