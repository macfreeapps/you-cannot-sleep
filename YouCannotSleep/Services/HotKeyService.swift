import AppKit
import Carbon
import Combine
import Foundation
import OSLog

@MainActor
final class HotKeyService: ObservableObject {
    static let missingModifierStatus = OSStatus(-50)
    var onHotKey: (() -> Void)?
    var onRegistrationError: ((OSStatus) -> Void)?
    @Published private(set) var registrationError: OSStatus?

    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "hotkey")
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    func register(_ combination: HotKeyCombination?) -> Bool {
        unregister()
        registrationError = nil
        guard let combination else { return true }
        guard hasRequiredModifier(combination.modifiers) else {
            registrationError = Self.missingModifierStatus
            onRegistrationError?(Self.missingModifierStatus)
            return false
        }
        guard installHandler() else { return false }

        let identifier = EventHotKeyID(signature: OSType(0x5963536C), id: 1)
        var registered: EventHotKeyRef?
        let result = RegisterEventHotKey(UInt32(combination.keyCode), carbonModifiers(combination.modifiers), identifier, GetApplicationEventTarget(), 0, &registered)
        guard result == noErr, let registered else {
            logger.error("Global shortcut registration failed: \(result)")
            registrationError = result
            onRegistrationError?(result)
            return false
        }
        hotKeyRef = registered
        registrationError = nil
        return true
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    func stop() {
        unregister()
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    private func installHandler() -> Bool {
        guard eventHandler == nil else { return true }
        var specification = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerProcPtr = { _, _, userData in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let service = Unmanaged<HotKeyService>.fromOpaque(userData).takeUnretainedValue()
            MainActor.assumeIsolated { service.onHotKey?() }
            return noErr
        }
        let result = InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &specification,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        if result != noErr {
            logger.error("Global shortcut event handler installation failed: \(result)")
            onRegistrationError?(result)
            return false
        }
        return true
    }

    private func hasRequiredModifier(_ flags: UInt32) -> Bool {
        let required = UInt32(NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.option.rawValue | NSEvent.ModifierFlags.control.rawValue)
        return flags & required != 0
    }

    private func carbonModifiers(_ flags: UInt32) -> UInt32 {
        var result: UInt32 = 0
        if flags & UInt32(NSEvent.ModifierFlags.command.rawValue) != 0 { result |= UInt32(cmdKey) }
        if flags & UInt32(NSEvent.ModifierFlags.option.rawValue) != 0 { result |= UInt32(optionKey) }
        if flags & UInt32(NSEvent.ModifierFlags.control.rawValue) != 0 { result |= UInt32(controlKey) }
        if flags & UInt32(NSEvent.ModifierFlags.shift.rawValue) != 0 { result |= UInt32(shiftKey) }
        return result
    }

}
