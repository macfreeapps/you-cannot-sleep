import AppKit
import ServiceManagement
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    let session: SessionController
    let loginItems: LoginItemService
    let notifications: NotificationService
    @ObservedObject var hotKey: HotKeyService

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var loginError: String?

    var body: some View {
        TabView {
            generalTab.tabItem { Label(String(localized: "General"), systemImage: "gearshape") }
            behaviorTab.tabItem { Label(String(localized: "Behavior"), systemImage: "hand.tap") }
            if session.powerState.hasBattery {
                batteryTab.tabItem { Label(String(localized: "Battery"), systemImage: "battery.75percent") }
            }
            appearanceTab.tabItem { Label(String(localized: "Appearance"), systemImage: "paintpalette") }
            shortcutTab.tabItem { Label(String(localized: "Shortcut"), systemImage: "keyboard") }
            automationTab.tabItem { Label(String(localized: "Automation"), systemImage: "arrow.triangle.branch") }
        }
        .padding(18)
        .frame(minWidth: 480, minHeight: 430)
        .onAppear {
            notifications.authorizationStatus { notificationStatus = $0 }
            _ = hotKey.register(settings.hotKey)
        }
    }

    private var generalTab: some View {
        Form {
            Toggle(String(localized: "Activate on launch"), isOn: $settings.activateOnLaunch)
            HStack {
                Toggle(String(localized: "Launch at login"), isOn: Binding(
                    get: { loginItems.isEnabled },
                    set: { value in
                        do { try loginItems.setEnabled(value); settings.launchAtLogin = value; loginError = nil }
                        catch { loginError = error.localizedDescription }
                    }
                ))
                if loginItems.status == .requiresApproval {
                    Button(String(localized: "Open Login Items")) { loginItems.openLoginItemsSettings() }
                }
            }
            if let loginError { Text(loginError).foregroundStyle(.red).font(.caption) }
            Toggle(String(localized: "Notifications"), isOn: Binding(
                get: { settings.notifications },
                set: { value in
                    settings.notifications = value
                    if value { notifications.requestAuthorization { notificationStatus = $0 } }
                }
            ))
            if notificationStatus == .denied {
                HStack {
                    Text(String(localized: "Notifications are disabled in System Settings."))
                        .font(.caption).foregroundStyle(.secondary)
                    Button(String(localized: "Open Settings")) {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") { NSWorkspace.shared.open(url) }
                    }
                }
            }
            Picker(String(localized: "Default duration"), selection: $settings.defaultDuration) {
                ForEach(SessionDuration.presets, id: \.self) { duration in
                    Text(duration.displayName).tag(duration)
                }
                if !SessionDuration.presets.contains(settings.defaultDuration) {
                    Text(settings.defaultDuration.displayName).tag(settings.defaultDuration)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var behaviorTab: some View {
        Form {
            Toggle(String(localized: "Allow display to sleep"), isOn: $settings.allowDisplaySleep)
            Toggle(String(localized: "Allow screen saver"), isOn: $settings.allowScreenSaver)
            Toggle(String(localized: "Toggle with left click"), isOn: $settings.toggleWithLeftClick)
            Text(String(localized: "Control-click always opens the menu."))
                .font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    private var batteryTab: some View {
        Form {
            Toggle(String(localized: "Turn off on battery power"), isOn: $settings.turnOffOnBattery)
            Toggle(String(localized: "Turn off below battery level"), isOn: $settings.batteryThresholdEnabled)
            Stepper(value: $settings.batteryThreshold, in: 5...50, step: 5) {
                Text(String(localized: "Battery threshold: \(settings.batteryThreshold)%"))
            }
            .disabled(!settings.batteryThresholdEnabled)
            Toggle(String(localized: "Turn on when charger is connected"), isOn: $settings.turnOnWhenChargerConnected)
        }
        .formStyle(.grouped)
    }

    private var appearanceTab: some View {
        Form {
            Toggle(String(localized: "Show remaining time in menu bar"), isOn: $settings.showRemainingTime)
        }
        .formStyle(.grouped)
    }

    private var shortcutTab: some View {
        Form {
            HStack {
                Text(String(localized: "Toggle session"))
                Spacer()
                HotKeyRecorderView(combination: $settings.hotKey)
                    .frame(width: 170, height: 26)
                Button(String(localized: "Clear")) { settings.hotKey = nil; _ = hotKey.register(nil) }
            }
            if let error = hotKey.registrationError {
                let message = error == HotKeyService.missingModifierStatus
                    ? String(localized: "Include Command, Option, or Control.")
                    : String(localized: "That shortcut is already in use.")
                Text(message).foregroundStyle(.red).font(.caption)
            }
            Text(String(localized: "Suggested shortcut: Control–Option–Command–S"))
                .font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    private var automationTab: some View {
        Form {
            automationRow("Shortcuts", detail: String(localized: "Toggle, turn on, turn off, and get status."), copy: "Toggle You Cannot Sleep")
            automationRow("AppleScript", detail: "toggle · turn on for 30 · turn off · get active", copy: "tell application \"You Cannot Sleep\" to toggle")
            automationRow("URL scheme", detail: "youcannotsleep://toggle · //on?minutes=30 · //off", copy: "open 'youcannotsleep://toggle'")
        }
        .formStyle(.grouped)
    }

    private func automationRow(_ title: LocalizedStringKey, detail: String, copy: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Button(String(localized: "Copy")) { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(copy, forType: .string) }
            }
            Text(detail).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
        }
    }
}
