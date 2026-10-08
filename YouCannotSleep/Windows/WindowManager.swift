import AppKit
import SwiftUI

@MainActor
final class WindowManager: NSObject, NSWindowDelegate {
    private enum Kind: Hashable { case settings, welcome, about }
    private var windows: [Kind: NSWindow] = [:]
    private let settings: AppSettings
    private let session: SessionController
    private let loginItems: LoginItemService
    private let notifications: NotificationService
    private let hotKey: HotKeyService

    init(settings: AppSettings, session: SessionController, loginItems: LoginItemService, notifications: NotificationService, hotKey: HotKeyService) {
        self.settings = settings
        self.session = session
        self.loginItems = loginItems
        self.notifications = notifications
        self.hotKey = hotKey
    }

    func openSettings() {
        present(.settings, title: String(localized: "Settings"), size: NSSize(width: 520, height: 500)) {
            SettingsView(settings: self.settings, session: self.session, loginItems: self.loginItems, notifications: self.notifications, hotKey: self.hotKey)
        }
    }

    func openWelcome() {
        present(.welcome, title: String(localized: "Welcome"), size: NSSize(width: 430, height: 360)) {
            WelcomeView(settings: self.settings, loginItems: self.loginItems, onDone: { [weak self] in
                self?.settings.completeWelcome()
                self?.close(.welcome)
            })
        }
    }

    func openAbout() {
        present(.about, title: String(localized: "About You Cannot Sleep"), size: NSSize(width: 420, height: 510)) {
            AboutView(onWelcome: { [weak self] in self?.openWelcome() })
        }
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        windows = windows.filter { $0.value !== window }
    }

    private func close(_ kind: Kind) {
        windows[kind]?.close()
    }

    private func present<Content: View>(_ kind: Kind, title: String, size: NSSize, @ViewBuilder content: () -> Content) {
        if let existing = windows[kind] {
            NSApp.activate(ignoringOtherApps: true)
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.isReleasedWhenClosed = false
        window.center()
        window.contentViewController = NSHostingController(rootView: content())
        window.setContentSize(size)
        window.delegate = self
        window.identifier = NSUserInterfaceItemIdentifier("YouCannotSleep.\(kind)")
        windows[kind] = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
