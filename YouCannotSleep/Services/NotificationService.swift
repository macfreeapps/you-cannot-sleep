import Foundation
import UserNotifications
import OSLog

@MainActor
final class NotificationService {
    private let center = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "notifications")
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    func requestAuthorization(completion: (@MainActor (UNAuthorizationStatus) -> Void)? = nil) {
        Task { @MainActor [logger, center] in
            do {
                let granted = try await center.requestAuthorization(options: [.alert])
                if !granted { logger.info("Notification permission was not granted") }
                let setting = await center.notificationSettings()
                completion?(setting.authorizationStatus)
            } catch {
                logger.error("Notification authorization failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func authorizationStatus(_ completion: @escaping @MainActor (UNAuthorizationStatus) -> Void) {
        Task { @MainActor [center] in
            let setting = await center.notificationSettings()
            completion(setting.authorizationStatus)
        }
    }

    func post(_ title: String, body: String, required: Bool = false) {
        guard required || settings.notifications else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            var setting = await center.notificationSettings()
            switch setting.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                await self.deliver(title, body: body)
            case .notDetermined:
                do {
                    let granted = try await center.requestAuthorization(options: [.alert])
                    if granted {
                        setting = await center.notificationSettings()
                        if setting.authorizationStatus == .authorized || setting.authorizationStatus == .provisional {
                            await self.deliver(title, body: body)
                        }
                    }
                } catch {
                    logger.error("Notification authorization failed: \(error.localizedDescription, privacy: .public)")
                }
            case .denied:
                break
            @unknown default:
                break
            }
        }
    }

    private func deliver(_ title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        do {
            try await center.add(request)
        } catch {
            logger.error("Could not deliver notification: \(error.localizedDescription, privacy: .public)")
        }
    }
}
