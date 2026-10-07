import AppKit
import Foundation

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let session: SessionController
    private let settings: AppSettings
    private let menuBuilder: MenuBuilder
    private var countdownTimer: Timer?
    private var colorObserver: NSObjectProtocol?

    init(session: SessionController, settings: AppSettings, menuBuilder: MenuBuilder) {
        self.session = session
        self.settings = settings
        self.menuBuilder = menuBuilder
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.setAccessibilityRole(.button)
        }
        colorObserver = NotificationCenter.default.addObserver(
            forName: NSColor.systemColorsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        }
        update()
    }

    func update() {
        guard let button = statusItem.button else { return }
        let active = session.isActive
        let tint = active && settings.useAccentColor ? NSColor.controlAccentColor : nil
        button.image = BeaconMenuIcon.image(active: active, tint: tint)
        if settings.showRemainingTime, let remaining = session.remainingMinutes() {
            button.title = countdownText(remaining)
            button.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        } else {
            button.title = ""
        }
        let accessibility: String
        if active, let remaining = session.remainingMinutes() {
            accessibility = String(localized: "You Cannot Sleep, active, \(remaining) minutes remaining")
        } else if active {
            accessibility = String(localized: "You Cannot Sleep, active")
        } else {
            accessibility = String(localized: "You Cannot Sleep, inactive")
        }
        button.setAccessibilityLabel(accessibility)
        button.setAccessibilityHelp(String(localized: "Open the menu or toggle the awake session."))
        menuBuilder.update()
        scheduleCountdownRefresh()
    }

    func stop() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        if let colorObserver {
            NotificationCenter.default.removeObserver(colorObserver)
            self.colorObserver = nil
        }
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isControlClick = event?.modifierFlags.contains(.control) == true
        if isControlClick {
            menuBuilder.popup(in: sender)
            return
        }
        let isRightClick = event?.type == .rightMouseUp
        let shouldToggle = settings.toggleWithLeftClick ? !isRightClick : isRightClick
        if shouldToggle {
            session.toggle()
            update()
        } else {
            menuBuilder.popup(in: sender)
        }
    }

    private func scheduleCountdownRefresh() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        guard settings.showRemainingTime, session.isActive, let endDate = session.endDate else { return }
        let interval: TimeInterval = endDate.timeIntervalSinceNow <= 60 ? 1 : 60
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        }
        timer.tolerance = interval == 1 ? 0.2 : 3
        RunLoop.main.add(timer, forMode: .common)
        countdownTimer = timer
    }

    private func countdownText(_ minutes: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .brief
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .dropAll
        return formatter.string(from: TimeInterval(max(minutes, 1) * 60)) ?? String(localized: "\(minutes) min")
    }
}
