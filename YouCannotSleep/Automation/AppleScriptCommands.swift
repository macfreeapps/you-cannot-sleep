import AppKit
import Foundation

@objc(QuitYouCannotSleepCommand)
final class QuitYouCannotSleepCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated { NSApp.terminate(nil) }
        return nil
    }
}

@objc(ToggleYouCannotSleepCommand)
final class ToggleYouCannotSleepCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated { AppRuntime.sessionController?.toggle() }
        return nil
    }
}

@objc(TurnOnYouCannotSleepCommand)
final class TurnOnYouCannotSleepCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let arguments = evaluatedArguments ?? [:]
        let duration = (arguments["for"] as? Int).map { SessionDuration.minutes(SessionDuration.clamped($0)) }
        MainActor.assumeIsolated { AppRuntime.sessionController?.activate(duration: duration) }
        return nil
    }
}

@objc(TurnOffYouCannotSleepCommand)
final class TurnOffYouCannotSleepCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated { AppRuntime.sessionController?.deactivate(reason: .user) }
        return nil
    }
}
