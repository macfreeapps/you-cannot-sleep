import Foundation
import XCTest
@testable import YouCannotSleep

@MainActor
final class SessionControllerTests: XCTestCase {
    func testDefaultActivationRequestsSystemAndDisplayAssertions() {
        let harness = Harness()
        harness.session.activate()
        XCTAssertTrue(harness.session.isActive)
        XCTAssertEqual(harness.assertions.current, [.preventSystemSleep, .preventDisplaySleep])
        harness.session.deactivate()
        XCTAssertFalse(harness.session.isActive)
        XCTAssertTrue(harness.assertions.current.isEmpty)
    }

    func testAllowDisplaySleepAndScreenSaverUseSystemAssertionOnly() {
        let harness = Harness()
        harness.settings.allowDisplaySleep = true
        harness.session.activate()
        XCTAssertEqual(harness.assertions.current, [.preventSystemSleep])
        harness.settings.allowDisplaySleep = false
        harness.settings.allowScreenSaver = true
        XCTAssertEqual(harness.assertions.current, [.preventSystemSleep])
    }

    func testLiveOptionSwapNeverDropsAllAssertions() {
        let harness = Harness()
        harness.session.activate()
        harness.settings.allowDisplaySleep = true
        XCTAssertEqual(harness.assertions.current, [.preventSystemSleep])
        XCTAssertFalse(harness.assertions.history.contains([]))
    }

    func testTimerExpiresAtAbsoluteEndDateAndWakeCatchesUp() {
        let harness = Harness()
        harness.session.activate(duration: .minutes(5))
        XCTAssertEqual(harness.session.endDate, harness.clock.now.addingTimeInterval(300))
        harness.clock.advance(by: 300)
        XCTAssertFalse(harness.session.isActive)

        harness.session.activate(duration: .minutes(5))
        harness.clock.advanceWithoutFiring(by: 301)
        harness.session.handleWakeOrClockChange()
        XCTAssertFalse(harness.session.isActive)
    }

    func testAssertionFailureLeavesSessionInactiveAndReleasesAssertions() {
        let harness = Harness()
        harness.assertions.failure = true
        harness.session.activate()
        XCTAssertFalse(harness.session.isActive)
        XCTAssertTrue(harness.assertions.current.isEmpty)
    }

    func testAssertionUpdateFailureEndsActiveSession() {
        let harness = Harness()
        harness.session.activate()
        harness.assertions.failure = true
        harness.settings.allowDisplaySleep = true
        XCTAssertFalse(harness.session.isActive)
        XCTAssertTrue(harness.assertions.current.isEmpty)
    }

    func testBatteryThresholdRequiresManualActivationPrecedenceAndHysteresis() {
        let harness = Harness()
        harness.settings.batteryThresholdEnabled = true
        harness.settings.batteryThreshold = 20
        harness.session.updatePowerState(PowerState(hasBattery: true, isOnAC: false, batteryPercent: 15))
        harness.session.activate(manual: true)
        XCTAssertTrue(harness.session.isActive)

        harness.session.updatePowerState(PowerState(hasBattery: true, isOnAC: false, batteryPercent: 30))
        harness.session.updatePowerState(PowerState(hasBattery: true, isOnAC: false, batteryPercent: 18))
        XCTAssertTrue(harness.session.isActive)
    }

    func testThresholdTurnsOffAutomaticSessionOnceBelowLimit() {
        let harness = Harness()
        harness.settings.batteryThresholdEnabled = true
        harness.session.updatePowerState(PowerState(hasBattery: true, isOnAC: false, batteryPercent: 35))
        harness.session.activate(manual: false)
        harness.session.updatePowerState(PowerState(hasBattery: true, isOnAC: false, batteryPercent: 19))
        XCTAssertFalse(harness.session.isActive)
        harness.session.activate(manual: false)
        XCTAssertTrue(harness.session.isActive)
        harness.session.updatePowerState(PowerState(hasBattery: true, isOnAC: false, batteryPercent: 25))
        harness.session.activate(manual: false)
        harness.session.updatePowerState(PowerState(hasBattery: true, isOnAC: false, batteryPercent: 19))
        XCTAssertFalse(harness.session.isActive)
    }

    func testChargerConnectTurnsOnOnlyAfterObservedTransition() {
        let harness = Harness()
        harness.settings.turnOnWhenChargerConnected = true
        harness.session.updatePowerState(PowerState(hasBattery: true, isOnAC: true, batteryPercent: 80))
        XCTAssertFalse(harness.session.isActive)
        harness.session.updatePowerState(PowerState(hasBattery: true, isOnAC: false, batteryPercent: 70))
        harness.session.updatePowerState(PowerState(hasBattery: true, isOnAC: true, batteryPercent: 70))
        XCTAssertTrue(harness.session.isActive)
    }

    func testBatteryPolicyTurnsOffOnAcDisconnect() {
        let harness = Harness()
        harness.settings.turnOffOnBattery = true
        harness.session.updatePowerState(PowerState(hasBattery: true, isOnAC: true, batteryPercent: 90))
        harness.session.activate(manual: false)
        harness.session.updatePowerState(PowerState(hasBattery: true, isOnAC: false, batteryPercent: 89))
        XCTAssertFalse(harness.session.isActive)
    }
}

@MainActor
private final class Harness {
    let settings: AppSettings
    let assertions = FakeAssertions()
    let clock = FakeClock()
    let session: SessionController

    init() {
        let suiteName = "YouCannotSleepTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        settings = AppSettings(defaults: defaults)
        session = SessionController(settings: settings, assertions: assertions, clock: clock)
    }
}

@MainActor
private final class FakeAssertions: PowerAssertionService {
    var current: Set<PowerAssertion> = []
    var history: [Set<PowerAssertion>] = []
    var failure = false

    func apply(_ assertions: Set<PowerAssertion>) throws {
        if failure { throw NSError(domain: "fake", code: 1) }
        current = assertions
        history.append(assertions)
    }

    func releaseAll() { current.removeAll(); history.append([]) }
}

@MainActor
private final class FakeClock: SessionClock {
    private(set) var now = Date(timeIntervalSince1970: 1_800_000_000)
    private var tasks: [(date: Date, action: () -> Void, task: FakeScheduledTask)] = []

    func schedule(at date: Date, tolerance: TimeInterval, _ action: @escaping () -> Void) -> ScheduledTask {
        let task = FakeScheduledTask()
        tasks.append((date, action, task))
        return task
    }

    func advance(by interval: TimeInterval) {
        now.addTimeInterval(interval)
        fireDueTasks()
    }

    func advanceWithoutFiring(by interval: TimeInterval) { now.addTimeInterval(interval) }

    private func fireDueTasks() {
        let due = tasks.filter { !$0.task.cancelled && $0.date <= now }
        tasks.removeAll { $0.task.cancelled || $0.date <= now }
        due.forEach { $0.action() }
    }
}

@MainActor
private final class FakeScheduledTask: ScheduledTask {
    private(set) var cancelled = false
    func cancel() { cancelled = true }
}
