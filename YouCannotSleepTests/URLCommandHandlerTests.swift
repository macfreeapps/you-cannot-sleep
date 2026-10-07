import Foundation
import XCTest
@testable import YouCannotSleep

final class URLCommandHandlerTests: XCTestCase {
    func testParsesSupportedCommands() {
        XCTAssertEqual(URLCommandHandler.parse(URL(string: "youcannotsleep://toggle")!), .toggle)
        XCTAssertEqual(URLCommandHandler.parse(URL(string: "youcannotsleep://off")!), .turnOff)
        XCTAssertEqual(URLCommandHandler.parse(URL(string: "youcannotsleep://on")!), .turnOn(minutes: nil))
        XCTAssertEqual(URLCommandHandler.parse(URL(string: "youcannotsleep://on?minutes=45")!), .turnOn(minutes: 45))
    }

    func testClampsAndRejectsInvalidCommands() {
        XCTAssertEqual(URLCommandHandler.parse(URL(string: "youcannotsleep://on?minutes=5000")!), .turnOn(minutes: 1_440))
        XCTAssertEqual(URLCommandHandler.parse(URL(string: "youcannotsleep://on?minutes=0")!), .turnOn(minutes: 1))
        XCTAssertNil(URLCommandHandler.parse(URL(string: "youcannotsleep://on?minutes=invalid")!))
        XCTAssertNil(URLCommandHandler.parse(URL(string: "youcannotsleep://wake")!))
        XCTAssertNil(URLCommandHandler.parse(URL(string: "otherapp://toggle")!))
    }
}
