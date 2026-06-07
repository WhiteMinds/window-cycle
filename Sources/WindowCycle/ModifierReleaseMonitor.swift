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
    }

    private func startNSEventMonitors() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.flagsChanged, .keyDown]
        ) { [weak self] event in
            self?.handle(nsEvent: event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.flagsChanged, .keyDown]
        ) { [weak self] event in
            self?.handle(nsEvent: event)
            return event
        }
    }

    private func startEventTap() {
        let mask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)
            | CGEventMask(1 << CGEventType.keyDown.rawValue)
        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
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

    fileprivate func handle(event: CGEvent) {
        if event.type == .keyDown {
            switch Int(event.getIntegerValueField(.keyboardEventKeycode)) {
            case kVK_Escape:
                Task { @MainActor [onEscape] in
                    onEscape()
                }
                return
            case kVK_UpArrow:
                Task { @MainActor [onMoveSelection] in
                    onMoveSelection(.previous)
                }
                return
            case kVK_DownArrow:
                Task { @MainActor [onMoveSelection] in
                    onMoveSelection(.next)
                }
                return
            default:
                break
            }
        }

        let isCommandDown = event.flags.contains(.maskCommand)
        handleCommandState(isCommandDown)
    }

    private func handle(nsEvent event: NSEvent) {
        if event.type == .keyDown, eventTap == nil {
            switch Int(event.keyCode) {
            case kVK_Escape:
                Task { @MainActor [onEscape] in
                    onEscape()
                }
                return
            case kVK_UpArrow:
                Task { @MainActor [onMoveSelection] in
                    onMoveSelection(.previous)
                }
                return
            case kVK_DownArrow:
                Task { @MainActor [onMoveSelection] in
                    onMoveSelection(.next)
                }
                return
            default:
                break
            }
        }

        let isCommandDown = event.modifierFlags.contains(.command)
        handleCommandState(isCommandDown)
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
        monitor.handle(event: event)
    }

    return Unmanaged.passUnretained(event)
}
