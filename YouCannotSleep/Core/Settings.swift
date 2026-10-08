import Foundation
import Combine

enum SettingKey: Hashable {
    case activateOnLaunch, launchAtLogin, notifications, allowDisplaySleep, allowScreenSaver
    case toggleWithLeftClick, turnOffOnBattery, batteryThresholdEnabled, batteryThreshold
    case turnOnWhenChargerConnected, showRemainingTime, defaultDuration
    case hotKey
}

struct HotKeyCombination: Codable, Equatable {
    var keyCode: UInt16
    var modifiers: UInt32

    var displayString: String {
        var result = ""
        if modifiers & (1 << 18) != 0 { result += "⌃" }
        if modifiers & (1 << 19) != 0 { result += "⌥" }
        if modifiers & (1 << 20) != 0 { result += "⌘" }
        if modifiers & (1 << 17) != 0 { result += "⇧" }
        return result + Self.keyName(keyCode)
    }

    private static func keyName(_ code: UInt16) -> String {
        let names: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 31: "O", 32: "U",
            34: "I", 35: "P", 37: "L", 38: "J", 40: "K", 45: "N", 46: "M", 49: String(localized: "Space")
        ]
        return names[code] ?? String(localized: "Key \(code)")
    }
}

@MainActor
final class AppSettings: ObservableObject {
    private enum Key {
        static let activateOnLaunch = "activateOnLaunch"
        static let launchAtLogin = "launchAtLogin"
        static let notifications = "notifications"
        static let allowDisplaySleep = "allowDisplaySleep"
        static let allowScreenSaver = "allowScreenSaver"
        static let toggleWithLeftClick = "toggleWithLeftClick"
        static let turnOffOnBattery = "turnOffOnBattery"
        static let batteryThresholdEnabled = "batteryThresholdEnabled"
        static let batteryThreshold = "batteryThreshold"
        static let turnOnWhenChargerConnected = "turnOnWhenChargerConnected"
        static let showRemainingTime = "showRemainingTime"
        static let defaultDuration = "defaultDuration"
        static let hotKey = "hotKey"
        static let didCompleteWelcome = "didCompleteWelcome"
    }

    private let defaults: UserDefaults
    var onChange: ((SettingKey) -> Void)?

    @Published var activateOnLaunch: Bool { didSet { save(activateOnLaunch, key: Key.activateOnLaunch, event: .activateOnLaunch) } }
    @Published var launchAtLogin: Bool { didSet { save(launchAtLogin, key: Key.launchAtLogin, event: .launchAtLogin) } }
    @Published var notifications: Bool { didSet { save(notifications, key: Key.notifications, event: .notifications) } }
    @Published var allowDisplaySleep: Bool { didSet { save(allowDisplaySleep, key: Key.allowDisplaySleep, event: .allowDisplaySleep) } }
    @Published var allowScreenSaver: Bool { didSet { save(allowScreenSaver, key: Key.allowScreenSaver, event: .allowScreenSaver) } }
    @Published var toggleWithLeftClick: Bool { didSet { save(toggleWithLeftClick, key: Key.toggleWithLeftClick, event: .toggleWithLeftClick) } }
    @Published var turnOffOnBattery: Bool { didSet { save(turnOffOnBattery, key: Key.turnOffOnBattery, event: .turnOffOnBattery) } }
    @Published var batteryThresholdEnabled: Bool { didSet { save(batteryThresholdEnabled, key: Key.batteryThresholdEnabled, event: .batteryThresholdEnabled) } }
    @Published private var storedBatteryThreshold: Int
    var batteryThreshold: Int {
        get { storedBatteryThreshold }
        set {
            storedBatteryThreshold = min(max(newValue, 5), 50)
            save(storedBatteryThreshold, key: Key.batteryThreshold, event: .batteryThreshold)
        }
    }
    @Published var turnOnWhenChargerConnected: Bool { didSet { save(turnOnWhenChargerConnected, key: Key.turnOnWhenChargerConnected, event: .turnOnWhenChargerConnected) } }
    @Published var showRemainingTime: Bool { didSet { save(showRemainingTime, key: Key.showRemainingTime, event: .showRemainingTime) } }
    @Published var defaultDuration: SessionDuration { didSet { save(defaultDuration.id, key: Key.defaultDuration, event: .defaultDuration) } }
    @Published var hotKey: HotKeyCombination? { didSet { saveHotKey(); onChange?(.hotKey) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        activateOnLaunch = defaults.object(forKey: Key.activateOnLaunch) as? Bool ?? true
        launchAtLogin = defaults.object(forKey: Key.launchAtLogin) as? Bool ?? false
        notifications = defaults.object(forKey: Key.notifications) as? Bool ?? false
        allowDisplaySleep = defaults.object(forKey: Key.allowDisplaySleep) as? Bool ?? false
        allowScreenSaver = defaults.object(forKey: Key.allowScreenSaver) as? Bool ?? false
        toggleWithLeftClick = defaults.object(forKey: Key.toggleWithLeftClick) as? Bool ?? false
        turnOffOnBattery = defaults.object(forKey: Key.turnOffOnBattery) as? Bool ?? false
        batteryThresholdEnabled = defaults.object(forKey: Key.batteryThresholdEnabled) as? Bool ?? false
        storedBatteryThreshold = min(max(defaults.object(forKey: Key.batteryThreshold) as? Int ?? 20, 5), 50)
        turnOnWhenChargerConnected = defaults.object(forKey: Key.turnOnWhenChargerConnected) as? Bool ?? false
        showRemainingTime = defaults.object(forKey: Key.showRemainingTime) as? Bool ?? false
        defaultDuration = SessionDuration(id: defaults.string(forKey: Key.defaultDuration) ?? "") ?? .indefinite
        if let data = defaults.data(forKey: Key.hotKey) {
            hotKey = try? JSONDecoder().decode(HotKeyCombination.self, from: data)
        } else {
            hotKey = nil
        }
    }

    var shouldShowWelcome: Bool { !defaults.bool(forKey: Key.didCompleteWelcome) }

    func completeWelcome() {
        defaults.set(true, forKey: Key.didCompleteWelcome)
    }

    private func save<T>(_ value: T, key: String, event: SettingKey) {
        defaults.set(value, forKey: key)
        onChange?(event)
    }

    private func saveHotKey() {
        if let hotKey, let data = try? JSONEncoder().encode(hotKey) {
            defaults.set(data, forKey: Key.hotKey)
        } else {
            defaults.removeObject(forKey: Key.hotKey)
        }
    }
}
