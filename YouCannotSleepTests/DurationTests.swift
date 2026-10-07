import Foundation
import XCTest
@testable import YouCannotSleep

@MainActor
final class DurationTests: XCTestCase {
    func testDurationClampsToOneMinuteThroughOneDay() {
        XCTAssertEqual(SessionDuration.clamped(-4), 1)
        XCTAssertEqual(SessionDuration.clamped(2_000), 1_440)
        XCTAssertEqual(SessionDuration.minutes(30).endDate(from: Date(timeIntervalSince1970: 10)), Date(timeIntervalSince1970: 1_810))
    }

    func testDurationPersistsAsStableIdentifier() throws {
        let encoded = try JSONEncoder().encode(SessionDuration.minutes(30))
        XCTAssertEqual(try JSONDecoder().decode(SessionDuration.self, from: encoded), .minutes(30))
        XCTAssertEqual(SessionDuration(id: "minutes:9999"), .minutes(1_440))
    }

    func testSavedDefaultDurationReloadsFromUserDefaults() {
        let suiteName = "DurationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        let settings = AppSettings(defaults: defaults)
        settings.defaultDuration = .minutes(75)
        XCTAssertEqual(AppSettings(defaults: defaults).defaultDuration, .minutes(75))
    }
}
