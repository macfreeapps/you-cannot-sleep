import AppKit
import Foundation
import ServiceManagement
import OSLog

@MainActor
final class LoginItemService {
    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "login-item")

    var status: SMAppService.Status { SMAppService.mainApp.status }
    var isEnabled: Bool { status == .enabled }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
        logger.info("Launch at login changed to \(enabled, privacy: .public)")
    }

    func openLoginItemsSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
    }
}
