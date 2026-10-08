import AppKit
import SwiftUI

@MainActor
final class MenuBuilder: NSObject, NSPopoverDelegate {
    private let session: SessionController
    private let settings: AppSettings
    private let loginItems: LoginItemService
    private let notifications: NotificationService
    private let windows: WindowManager
    private let popover = NSPopover()

    init(session: SessionController, settings: AppSettings, loginItems: LoginItemService, notifications: NotificationService, windows: WindowManager) {
        self.session = session
        self.settings = settings
        self.loginItems = loginItems
        self.notifications = notifications
        self.windows = windows
        super.init()
        popover.behavior = .transient
        popover.delegate = self
    }

    func popup(in button: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        let availableHeight = button.window?.screen?.visibleFrame.height ?? 700
        let height = min(540, max(320, availableHeight - 70))
        let view = MenuBarPanelView(
            session: session,
            settings: settings,
            loginItems: loginItems,
            notifications: notifications,
            height: height,
            onCustomDuration: { [weak self] in self?.openCustomDuration() },
            onSettings: { [weak self] in
                self?.popover.performClose(nil)
                self?.windows.openSettings()
            },
            onAbout: { [weak self] in
                self?.popover.performClose(nil)
                self?.windows.openAbout()
            },
            onClose: { [weak self] in self?.popover.performClose(nil) }
        )
        popover.contentViewController = NSHostingController(rootView: view)
        popover.contentSize = NSSize(width: 344, height: height)
        popover.animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    func popoverDidClose(_ notification: Notification) {
        // Unmount the panel so its visible-only countdown stops refreshing.
        popover.contentViewController = nil
    }

    func stop() {
        popover.performClose(nil)
        popover.contentViewController = nil
    }

    private func openCustomDuration() {
        popover.performClose(nil)
        windows.openCustomDuration { [weak session] duration in
            session?.choose(duration)
        }
    }
}
