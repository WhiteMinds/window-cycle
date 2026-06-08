import CoreGraphics
import AppKit
import Carbon
import Foundation

final class ModifierReleaseMonitor {
    private let onCommandReleased: @MainActor () -> Void
    private let onEscape: @MainActor () -> Void
    private let onMoveSelection: @MainActor (WindowCycleDirection) -> Void
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var wasCommandDown = false
    private var isSwitcherActive = false

    var isEventTapActive: Bool {
        eventTap != nil
    }

    init(
        onCommandReleased: @escaping @MainActor () -> Void,
        onEscape: @escaping @MainActor () -> Void,
        onMoveSelection: @escaping @MainActor (WindowCycleDirection) -> Void
    ) {
        self.onCommandReleased = onCommandReleased
        self.onEscape = onEscape
        self.onMoveSelection = onMoveSelection
    }

    deinit {
        stop()
    }

    func start() {
        stop()

        startNSEventMonitors()
        startEventTap()
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }

        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }

        globalMonitor = nil
        localMonitor = nil

        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        runLoopSource = nil
        eventTap = nil
        wasCommandDown = false
        isSwitcherActive = false
    }

    func setSwitcherActive(_ isActive: Bool) {
        isSwitcherActive = isActive
    }

    private func startNSEventMonitors() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.flagsChanged]
        ) { [weak self] event in
            _ = self?.handle(nsEvent: event, canConsume: false)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.flagsChanged, .keyDown]
        ) { [weak self] event in
            guard let self else {
                return event
            }
            return self.handle(nsEvent: event, canConsume: true) ? nil : event
        }
    }

    private func startEventTap() {
        let mask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)
            | CGEventMask(1 << CGEventType.keyDown.rawValue)
        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: modifierReleaseCallback,
            userInfo: userInfo
        )

        guard let eventTap else {
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)

        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    fileprivate func handle(event: CGEvent, type: CGEventType) -> Bool {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return false
        }

        if event.type == .keyDown, isSwitcherActive {
            let flags = event.flags
            if handleSwitcherKeyDown(
                keyCode: Int(event.getIntegerValueField(.keyboardEventKeycode)),
                isCommandDown: flags.contains(.maskCommand),
                isShiftDown: flags.contains(.maskShift)
            ) {
                return true
            }
        }

        let isCommandDown = event.flags.contains(.maskCommand)
        handleCommandState(isCommandDown)
        return false
    }

    private func handle(nsEvent event: NSEvent, canConsume: Bool) -> Bool {
        if event.type == .keyDown, canConsume, isSwitcherActive {
            if handleSwitcherKeyDown(
                keyCode: Int(event.keyCode),
                isCommandDown: event.modifierFlags.contains(.command),
                isShiftDown: event.modifierFlags.contains(.shift)
            ) {
                return true
            }
        }

        let isCommandDown = event.modifierFlags.contains(.command)
        handleCommandState(isCommandDown)
        return false
    }

    private func handleSwitcherKeyDown(
        keyCode: Int,
        isCommandDown: Bool,
        isShiftDown: Bool
    ) -> Bool {
        switch keyCode {
        case kVK_Escape:
            Task { @MainActor [onEscape] in
                onEscape()
            }
            return true
        case kVK_UpArrow:
            moveSelection(.previous)
            return true
        case kVK_DownArrow:
            moveSelection(.next)
            return true
        case kVK_ANSI_Grave where isCommandDown:
            moveSelection(isShiftDown ? .previous : .next)
            return true
        default:
            return false
        }
    }

    private func moveSelection(_ direction: WindowCycleDirection) {
        Task { @MainActor [onMoveSelection] in
            onMoveSelection(direction)
        }
    }

    private func handleCommandState(_ isCommandDown: Bool) {
        if wasCommandDown && !isCommandDown {
            Task { @MainActor [onCommandReleased] in
                onCommandReleased()
            }
        }

        wasCommandDown = isCommandDown
    }
}

private let modifierReleaseCallback: CGEventTapCallBack = { _, _, event, userInfo in
    if let userInfo {
        let monitor = Unmanaged<ModifierReleaseMonitor>
            .fromOpaque(userInfo)
            .takeUnretainedValue()
        if monitor.handle(event: event, type: event.type) {
            return nil
        }
    }

    return Unmanaged.passUnretained(event)
}
