import AppKit
import Carbon
import Foundation
import OSLog

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "application")
    private var settings: AppSettings?
    private var session: SessionController?
    private var powerMonitor: PowerSourceMonitor?
    private var systemMonitor: SystemEventsMonitor?
    private var notifications: NotificationService?
    private var loginItems: LoginItemService?
    private var hotKey: HotKeyService?
    private var windows: WindowManager?
    private var menuBuilder: MenuBuilder?
    private var statusItem: StatusItemController?
    private var pendingURLs: [URL] = []
    private var servicesAreReady = false
    private var receivedURLDuringStartup = false

    @objc dynamic var active: Bool { session?.isActive ?? false }
    @objc dynamic var remainingMinutes: Int { session?.remainingMinutes() ?? 0 }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReplyEvent:)),
            forEventClass: OSType(kInternetEventClass),
            andEventID: OSType(kAEGetURL)
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        guard !anotherInstanceIsRunning else {
            NSApp.terminate(nil)
            return
        }

        let settings = AppSettings()
        let notifications = NotificationService(settings: settings)
        let loginItems = LoginItemService()
        let hotKey = HotKeyService()
        let session = SessionController(settings: settings, assertions: IOKitPowerAssertionService(), notifications: notifications)
        let controllerSettingsHandler = settings.onChange
        settings.onChange = { [weak settings, weak hotKey] key in
            controllerSettingsHandler?(key)
            if key == .hotKey, let settings { _ = hotKey?.register(settings.hotKey) }
        }
        let windows = WindowManager(settings: settings, session: session, loginItems: loginItems, notifications: notifications, hotKey: hotKey)
        let menuBuilder = MenuBuilder(session: session, settings: settings, loginItems: loginItems, notifications: notifications, windows: windows)
        let statusItem = StatusItemController(session: session, settings: settings, menuBuilder: menuBuilder)
        let powerMonitor = PowerSourceMonitor()
        let systemMonitor = SystemEventsMonitor()

        self.settings = settings
        self.session = session
        self.powerMonitor = powerMonitor
        self.systemMonitor = systemMonitor
        self.notifications = notifications
        self.loginItems = loginItems
        self.hotKey = hotKey
        self.windows = windows
        self.menuBuilder = menuBuilder
        self.statusItem = statusItem
        AppRuntime.sessionController = session
        servicesAreReady = true

        session.onChange = { [weak statusItem, weak menuBuilder] in
            statusItem?.update()
            menuBuilder?.update()
        }
        powerMonitor.onChange = { [weak session] state in session?.updatePowerState(state) }
        powerMonitor.refresh()
        systemMonitor.onWake = { [weak session] in session?.handleWakeOrClockChange() }
        systemMonitor.onClockChange = { [weak session] in session?.handleWakeOrClockChange() }
        hotKey.onHotKey = { [weak session, weak notifications] in
            session?.toggle()
            let body = session?.isActive == true
                ? String(localized: "Your Mac cannot sleep now.")
                : String(localized: "Your Mac can sleep again.")
            notifications?.post(String(localized: "Awake session"), body: body)
        }
        hotKey.onRegistrationError = { [weak self] status in
            self?.logger.error("Shortcut registration failed with status \(status)")
        }
        _ = hotKey.register(settings.hotKey)

        for url in pendingURLs { handle(url) }
        pendingURLs.removeAll()

        let showWelcome = settings.shouldShowWelcome
        let activateOnLaunch = showWelcome || settings.activateOnLaunch
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) { [weak self] in
            MainActor.assumeIsolated {
                guard let self, !self.receivedURLDuringStartup else { return }
                if showWelcome { windows.openWelcome() }
                if activateOnLaunch { session.activate(duration: settings.defaultDuration, manual: false) }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        session?.applicationWillTerminate()
        powerMonitor?.stop()
        systemMonitor?.stop()
        hotKey?.stop()
        statusItem?.stop()
        AppRuntime.sessionController = nil
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls { receive(url) }
    }

    func application(_ application: NSApplication, delegateHandlesKey key: String) -> Bool {
        key == "active" || key == "remainingMinutes"
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private var anotherInstanceIsRunning: Bool {
        let bundleID = Bundle.main.bundleIdentifier ?? AppInfo.bundleIdentifier
        return NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .contains { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
    }

    @objc private func handleGetURL(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let rawURL = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: rawURL) else { return }
        receive(url)
    }

    private func receive(_ url: URL) {
        if url.scheme?.lowercased() == AppInfo.urlScheme {
            receivedURLDuringStartup = true
        }
        guard servicesAreReady else {
            pendingURLs.append(url)
            return
        }
        handle(url)
    }

    private func handle(_ url: URL) {
        guard let command = URLCommandHandler.parse(url), let session else {
            logger.info("Ignored unknown URL command: \(url.absoluteString, privacy: .public)")
            return
        }
        switch command {
        case .toggle:
            session.toggle()
        case .turnOn(let minutes):
            let duration = minutes.map(SessionDuration.minutes) ?? settings?.defaultDuration ?? .indefinite
            session.activate(duration: duration)
        case .turnOff:
            session.deactivate(reason: .user)
        }
    }
}
