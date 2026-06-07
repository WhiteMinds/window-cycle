import Carbon
import Foundation

final class HotKeyService {
    typealias Handler = (WindowCycleDirection) -> Void

    fileprivate enum HotKeyID: UInt32 {
        case next = 1
        case previous = 2
    }

    private let handler: Handler
    private var eventHandlerRef: EventHandlerRef?
    private var registeredHotKeys: [EventHotKeyRef?] = []

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    deinit {
        stop()
    }

    func start() throws {
        stop()

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let installStatus = InstallEventHandler(
            GetEventDispatcherTarget(),
            hotKeyCallback,
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        guard installStatus == noErr else {
            throw HotKeyServiceError.installEventHandlerFailed(installStatus)
        }

        try registerHotKey(.next, modifiers: UInt32(cmdKey))
        try registerHotKey(.previous, modifiers: UInt32(cmdKey | shiftKey))
    }

    func stop() {
        for hotKey in registeredHotKeys {
            if let hotKey {
                UnregisterEventHotKey(hotKey)
            }
        }
        registeredHotKeys.removeAll()

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    private func registerHotKey(_ hotKeyID: HotKeyID, modifiers: UInt32) throws {
        var carbonHotKey: EventHotKeyRef?
        let eventHotKeyID = EventHotKeyID(
            signature: fourCharCode("WCYC"),
            id: hotKeyID.rawValue
        )

        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_Grave),
            modifiers,
            eventHotKeyID,
            GetEventDispatcherTarget(),
            0,
            &carbonHotKey
        )

        guard status == noErr else {
            throw HotKeyServiceError.registerHotKeyFailed(String(describing: hotKeyID), status)
        }

        registeredHotKeys.append(carbonHotKey)
    }

    fileprivate func handle(event: EventRef?) -> OSStatus {
        guard let event else {
            return noErr
        }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr else {
            return status
        }

        switch HotKeyID(rawValue: hotKeyID.id) {
        case .next:
            handler(.next)
        case .previous:
            handler(.previous)
        case .none:
            break
        }

        return noErr
    }
}

enum HotKeyServiceError: Error, CustomStringConvertible {
    case installEventHandlerFailed(OSStatus)
    case registerHotKeyFailed(String, OSStatus)

    var description: String {
        switch self {
        case let .installEventHandlerFailed(status):
            return "InstallEventHandler failed with status \(status)."
        case let .registerHotKeyFailed(hotKeyID, status):
            return "RegisterEventHotKey failed for \(hotKeyID) with status \(status)."
        }
    }
}

private let hotKeyCallback: EventHandlerUPP = { _, event, userData in
    guard let userData else {
        return noErr
    }

    let service = Unmanaged<HotKeyService>.fromOpaque(userData).takeUnretainedValue()
    return service.handle(event: event)
}

private func fourCharCode(_ value: String) -> OSType {
    var result: OSType = 0
    for byte in value.utf8.prefix(4) {
        result = (result << 8) + OSType(byte)
    }
    return result
}
