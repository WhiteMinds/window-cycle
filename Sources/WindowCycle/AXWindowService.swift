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
        let role = readStringAttribute(kAXRoleAttribute as String, from: element)
        guard role == kAXWindowRole else {
            return nil
        }

        let rawTitle = readStringAttribute(kAXTitleAttribute as String, from: element)

        let frame = readFrame(from: element) ?? .zero
        let minimized = readBoolAttribute(kAXMinimizedAttribute as String, from: element) ?? false

        return AppWindow(
            pid: application.processIdentifier,
            appName: application.localizedName ?? "Unknown App",
            bundleIdentifier: application.bundleIdentifier,
            appIcon: application.icon,
            axElement: element,
            title: resolveWindowTitle(rawTitle, application: application),
            frame: frame,
            isMinimized: minimized,
            indexHint: index
        )
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
