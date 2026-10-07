import Foundation
import OSLog

@MainActor
enum AppRuntime {
    static weak var sessionController: SessionController?
    static let intentsLogger = Logger(subsystem: AppInfo.bundleIdentifier, category: "intents")
}
