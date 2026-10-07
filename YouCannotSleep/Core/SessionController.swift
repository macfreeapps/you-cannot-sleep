import Foundation
import Combine
import OSLog

enum SessionEndReason {
    case timedOut
    case batteryPolicy
    case user
    case failure
}

@MainActor
final class SessionController: ObservableObject {
    @Published private(set) var isActive = false { didSet { onChange?() } }
    @Published private(set) var endDate: Date? { didSet { onChange?() } }
    @Published private(set) var powerState: PowerState = .unavailable { didSet { onChange?() } }
    var onChange: (() -> Void)?

    private let settings: AppSettings
    private let assertions: PowerAssertionService
    private let clock: SessionClock
    private let notifications: NotificationService?
    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "power")
    private var endTask: ScheduledTask?
    private var sawPowerSource = false
    private var thresholdHasTripped = false
    private var manualBatteryOverride = false

    init(settings: AppSettings, assertions: PowerAssertionService, clock: SessionClock = SystemSessionClock(), notifications: NotificationService? = nil) {
        self.settings = settings
        self.assertions = assertions
        self.clock = clock
        self.notifications = notifications
        settings.onChange = { [weak self] key in self?.settingsDidChange(key) }
    }

    var selectedDuration: SessionDuration { settings.defaultDuration }

    func toggle(manual: Bool = true) {
        isActive ? deactivate(reason: .user) : activate(duration: settings.defaultDuration, manual: manual)
    }

    func choose(_ duration: SessionDuration) {
        settings.defaultDuration = duration
        activate(duration: duration, manual: true)
    }

    func activate(duration: SessionDuration? = nil, manual: Bool = true) {
        let chosen = duration ?? settings.defaultDuration
        if manual && powerState.hasBattery && !powerState.isOnAC {
            manualBatteryOverride = true
        }
        do {
            try assertions.apply(assertionsForCurrentSettings())
        } catch {
            logger.error("Could not keep the Mac awake: \(error.localizedDescription, privacy: .public)")
            assertions.releaseAll()
            endTask?.cancel()
            endTask = nil
            isActive = false
            endDate = nil
            notifications?.post(String(localized: "Couldn't keep your Mac awake"), body: String(localized: "Check your power settings and try again."), required: true)
            return
        }
        isActive = true
        endDate = chosen.endDate(from: clock.now)
        scheduleEnd()
        evaluateBatteryPolicy()
    }

    func deactivate(reason: SessionEndReason = .user) {
        let wasTimed = endDate != nil
        endTask?.cancel()
        endTask = nil
        endDate = nil
        isActive = false
        assertions.releaseAll()

        switch reason {
        case .timedOut where wasTimed:
            notifications?.post(String(localized: "Time's up"), body: String(localized: "Your Mac can sleep again."))
        case .batteryPolicy:
            notifications?.post(String(localized: "Session ended"), body: String(localized: "Your Mac can sleep again."))
        default:
            break
        }
    }

    func applicationWillTerminate() {
        endTask?.cancel()
        endTask = nil
        endDate = nil
        isActive = false
        assertions.releaseAll()
    }

    func handleWakeOrClockChange() {
        guard isActive else { return }
        if let endDate, endDate <= clock.now {
            deactivate(reason: .timedOut)
            return
        }
        do {
            try assertions.apply(assertionsForCurrentSettings())
            scheduleEnd()
        } catch {
            logger.error("Could not restore power assertions: \(error.localizedDescription, privacy: .public)")
            deactivate(reason: .failure)
            notifications?.post(String(localized: "Couldn't keep your Mac awake"), body: String(localized: "Check your power settings and try again."), required: true)
        }
    }

    func updatePowerState(_ newState: PowerState) {
        let oldState = powerState
        powerState = newState
        let isTransition = sawPowerSource && (oldState.hasBattery != newState.hasBattery || oldState.isOnAC != newState.isOnAC)
        sawPowerSource = true

        if let percent = newState.batteryPercent, percent > settings.batteryThreshold {
            thresholdHasTripped = false
        }

        if isTransition {
            manualBatteryOverride = false
            let disconnected = oldState.isOnAC && !newState.isOnAC
            let connected = !oldState.isOnAC && newState.isOnAC
            if disconnected && settings.turnOffOnBattery && isActive {
                deactivate(reason: .batteryPolicy)
                return
            }
            if connected && settings.turnOnWhenChargerConnected && !isActive {
                activate(duration: settings.defaultDuration, manual: false)
                notifications?.post(String(localized: "Charger connected"), body: String(localized: "Keeping your Mac awake."))
                return
            }
        }
        evaluateBatteryPolicy()
    }

    func remainingMinutes(at date: Date? = nil) -> Int? {
        guard let endDate else { return nil }
        return max(0, Int(ceil(endDate.timeIntervalSince(date ?? clock.now) / 60)))
    }

    private func settingsDidChange(_ key: SettingKey) {
        if isActive && (key == .allowDisplaySleep || key == .allowScreenSaver) {
            do {
                try assertions.apply(assertionsForCurrentSettings())
            } catch {
                logger.error("Could not update power assertions: \(error.localizedDescription, privacy: .public)")
                deactivate(reason: .failure)
                notifications?.post(String(localized: "Couldn't keep your Mac awake"), body: String(localized: "Check your power settings and try again."), required: true)
                return
            }
        }
        if key == .batteryThresholdEnabled || key == .batteryThreshold || key == .turnOffOnBattery {
            evaluateBatteryPolicy()
        }
        onChange?()
    }

    private func assertionsForCurrentSettings() -> Set<PowerAssertion> {
        var result: Set<PowerAssertion> = [.preventSystemSleep]
        if !settings.allowDisplaySleep && !settings.allowScreenSaver {
            result.insert(.preventDisplaySleep)
        }
        return result
    }

    private func scheduleEnd() {
        endTask?.cancel()
        guard let endDate else { return }
        endTask = clock.schedule(at: endDate, tolerance: 1) { [weak self] in
            guard let self, self.isActive, let deadline = self.endDate else { return }
            if deadline <= self.clock.now {
                self.deactivate(reason: .timedOut)
            } else {
                self.scheduleEnd()
            }
        }
    }

    private func evaluateBatteryPolicy() {
        guard isActive, powerState.hasBattery, !powerState.isOnAC, !manualBatteryOverride else { return }
        if settings.turnOffOnBattery {
            deactivate(reason: .batteryPolicy)
            return
        }
        if settings.batteryThresholdEnabled,
           let percent = powerState.batteryPercent,
           percent < settings.batteryThreshold,
           !thresholdHasTripped {
            thresholdHasTripped = true
            deactivate(reason: .batteryPolicy)
        }
    }
}
