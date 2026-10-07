import AppKit
import Foundation

@MainActor
final class MenuBuilder: NSObject, NSMenuDelegate {
    private enum Option: Int {
        case activateOnLaunch = 1, launchAtLogin, allowDisplaySleep, allowScreenSaver, turnOffOnBattery
        case batteryThreshold, turnOnWhenChargerConnected, notifications, toggleWithLeftClick, useAccentColor, showRemainingTime
    }

    private let session: SessionController
    private let settings: AppSettings
    private let loginItems: LoginItemService
    private let notifications: NotificationService
    private let windows: WindowManager
    private let menu = NSMenu()
    private let headerItem = NSMenuItem(title: String(localized: "Inactive"), action: nil, keyEquivalent: "")
    private let toggleItem = NSMenuItem(title: String(localized: "Turn On"), action: #selector(toggleSession), keyEquivalent: "")
    private var optionItems: [Option: NSMenuItem] = [:]
    private var quickDurationItems: [SessionDuration: NSMenuItem] = [:]
    private var durationItems: [SessionDuration: NSMenuItem] = [:]
    private var customDurationItem: NSMenuItem?
    private var menuTimer: Timer?

    init(session: SessionController, settings: AppSettings, loginItems: LoginItemService, notifications: NotificationService, windows: WindowManager) {
        self.session = session
        self.settings = settings
        self.loginItems = loginItems
        self.notifications = notifications
        self.windows = windows
        super.init()
        build()
        menu.delegate = self
        update()
    }

    func popup(in button: NSStatusBarButton) {
        update()
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 3), in: button)
    }

    func update() {
        headerItem.title = headerTitle
        toggleItem.title = (session.isActive ? String(localized: "Turn Off") : String(localized: "Turn On")) + shortcutSuffix
        for (duration, item) in durationItems {
            item.state = duration == settings.defaultDuration ? .on : .off
        }
        for (duration, item) in quickDurationItems {
            item.state = duration == settings.defaultDuration ? .on : .off
        }
        let durationHasMenuEntry = SessionDuration.presets.contains(settings.defaultDuration)
            || quickDurationItems[settings.defaultDuration] != nil
        customDurationItem?.state = durationHasMenuEntry ? .off : .on
        for (option, item) in optionItems {
            item.state = isEnabled(option) ? .on : .off
            if [.turnOffOnBattery, .batteryThreshold, .turnOnWhenChargerConnected].contains(option) {
                item.isHidden = !session.powerState.hasBattery
            }
        }
        optionItems[.batteryThreshold]?.title = String(localized: "Turn off below \(settings.batteryThreshold)%")
    }

    func menuWillOpen(_ menu: NSMenu) {
        update()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.headerItem.title = self?.headerTitle ?? String(localized: "Inactive")
                self?.toggleItem.title = (self?.session.isActive == true ? String(localized: "Turn Off") : String(localized: "Turn On")) + (self?.shortcutSuffix ?? "")
            }
        }
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .eventTracking)
        menuTimer = timer
    }

    func menuDidClose(_ menu: NSMenu) {
        menuTimer?.invalidate()
        menuTimer = nil
    }

    @objc private func toggleSession() {
        session.toggle()
        update()
    }

    @objc private func chooseDuration(_ sender: NSMenuItem) {
        let index = sender.tag
        guard SessionDuration.presets.indices.contains(index) else { return }
        session.choose(SessionDuration.presets[index])
        update()
    }

    @objc private func chooseQuickDuration(_ sender: NSMenuItem) {
        let duration = SessionDuration.minutes(sender.tag)
        guard quickDurationItems[duration] != nil else { return }
        session.choose(duration)
        update()
    }

    @objc private func chooseCustomDuration() {
        windows.openCustomDuration { [weak self] duration in
            self?.session.choose(duration)
            self?.update()
        }
    }

    @objc private func toggleOption(_ sender: NSMenuItem) {
        guard let option = Option(rawValue: sender.tag) else { return }
        let value = sender.state != .on
        switch option {
        case .activateOnLaunch: settings.activateOnLaunch = value
        case .launchAtLogin:
            do { try loginItems.setEnabled(value); settings.launchAtLogin = value }
            catch { NSSound.beep() }
        case .allowDisplaySleep: settings.allowDisplaySleep = value
        case .allowScreenSaver: settings.allowScreenSaver = value
        case .turnOffOnBattery: settings.turnOffOnBattery = value
        case .batteryThreshold: settings.batteryThresholdEnabled = value
        case .turnOnWhenChargerConnected: settings.turnOnWhenChargerConnected = value
        case .notifications:
            settings.notifications = value
            if value { notifications.requestAuthorization() }
        case .toggleWithLeftClick: settings.toggleWithLeftClick = value
        case .useAccentColor: settings.useAccentColor = value
        case .showRemainingTime: settings.showRemainingTime = value
        }
        update()
    }

    @objc private func openSettings() { windows.openSettings() }
    @objc private func openAbout() { windows.openAbout() }
    @objc private func quit() { NSApp.terminate(nil) }

    private func build() {
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        toggleItem.target = self
        toggleItem.action = #selector(toggleSession)
        menu.addItem(toggleItem)
        menu.addItem(.separator())

        let quickHeaderItem = NSMenuItem(title: String(localized: "Quick session"), action: nil, keyEquivalent: "")
        quickHeaderItem.isEnabled = false
        menu.addItem(quickHeaderItem)
        for minutes in [20, 50, 120] {
            let duration = SessionDuration.minutes(minutes)
            let item = NSMenuItem(title: duration.displayName, action: #selector(chooseQuickDuration(_:)), keyEquivalent: "")
            item.tag = minutes
            item.target = self
            quickDurationItems[duration] = item
            menu.addItem(item)
        }
        menu.addItem(.separator())

        let durationParent = NSMenuItem(title: String(localized: "Duration"), action: nil, keyEquivalent: "")
        let durationMenu = NSMenu()
        for (index, duration) in SessionDuration.presets.enumerated() {
            let item = NSMenuItem(title: duration.displayName, action: #selector(chooseDuration(_:)), keyEquivalent: "")
            item.tag = index
            item.target = self
            durationItems[duration] = item
            durationMenu.addItem(item)
        }
        durationMenu.addItem(.separator())
        let customItem = NSMenuItem(title: String(localized: "Custom…"), action: #selector(chooseCustomDuration), keyEquivalent: "")
        customItem.target = self
        customDurationItem = customItem
        durationMenu.addItem(customItem)
        durationParent.submenu = durationMenu
        menu.addItem(durationParent)

        let optionsParent = NSMenuItem(title: String(localized: "Options"), action: nil, keyEquivalent: "")
        let optionsMenu = NSMenu()
        addOption(.activateOnLaunch, title: String(localized: "Activate on launch"), to: optionsMenu)
        addOption(.launchAtLogin, title: String(localized: "Launch at login"), to: optionsMenu)
        optionsMenu.addItem(.separator())
        addOption(.allowDisplaySleep, title: String(localized: "Allow display to sleep"), to: optionsMenu)
        addOption(.allowScreenSaver, title: String(localized: "Allow screen saver"), to: optionsMenu)
        addOption(.turnOffOnBattery, title: String(localized: "Turn off on battery power"), to: optionsMenu)
        addOption(.batteryThreshold, title: String(localized: "Turn off below \(settings.batteryThreshold)%"), to: optionsMenu)
        addOption(.turnOnWhenChargerConnected, title: String(localized: "Turn on when charger connected"), to: optionsMenu)
        optionsMenu.addItem(.separator())
        addOption(.notifications, title: String(localized: "Notifications"), to: optionsMenu)
        addOption(.toggleWithLeftClick, title: String(localized: "Toggle with left click"), to: optionsMenu)
        addOption(.useAccentColor, title: String(localized: "Use accent color when active"), to: optionsMenu)
        addOption(.showRemainingTime, title: String(localized: "Show remaining time in menu bar"), to: optionsMenu)
        optionsParent.submenu = optionsMenu
        menu.addItem(optionsParent)

        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: String(localized: "Settings…"), action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = .command
        settingsItem.target = self
        menu.addItem(settingsItem)
        let aboutItem = NSMenuItem(title: String(localized: "About You Cannot Sleep"), action: #selector(openAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: String(localized: "Quit You Cannot Sleep"), action: #selector(quit), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = .command
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func addOption(_ option: Option, title: String, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: #selector(toggleOption(_:)), keyEquivalent: "")
        item.target = self
        item.tag = option.rawValue
        item.state = isEnabled(option) ? .on : .off
        optionItems[option] = item
        menu.addItem(item)
    }

    private var headerTitle: String {
        guard session.isActive else { return String(localized: "Inactive") }
        guard let remaining = session.remainingMinutes() else { return String(localized: "Active indefinitely") }
        return String(localized: "Active · \(remaining) min left")
    }

    private var shortcutSuffix: String {
        guard let shortcut = settings.hotKey?.displayString else { return "" }
        return "    \(shortcut)"
    }

    private func isEnabled(_ option: Option) -> Bool {
        switch option {
        case .activateOnLaunch: settings.activateOnLaunch
        case .launchAtLogin: loginItems.isEnabled
        case .allowDisplaySleep: settings.allowDisplaySleep
        case .allowScreenSaver: settings.allowScreenSaver
        case .turnOffOnBattery: settings.turnOffOnBattery
        case .batteryThreshold: settings.batteryThresholdEnabled
        case .turnOnWhenChargerConnected: settings.turnOnWhenChargerConnected
        case .notifications: settings.notifications
        case .toggleWithLeftClick: settings.toggleWithLeftClick
        case .useAccentColor: settings.useAccentColor
        case .showRemainingTime: settings.showRemainingTime
        }
    }
}
