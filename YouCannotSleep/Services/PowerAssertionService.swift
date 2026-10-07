import Foundation
import IOKit
import IOKit.pwr_mgt
import OSLog

enum PowerAssertion: Hashable {
    case preventSystemSleep
    case preventDisplaySleep

    var type: CFString {
        switch self {
        case .preventSystemSleep: kIOPMAssertionTypePreventUserIdleSystemSleep as CFString
        case .preventDisplaySleep: kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString
        }
    }
}

@MainActor
protocol PowerAssertionService: AnyObject {
    func apply(_ assertions: Set<PowerAssertion>) throws
    func releaseAll()
}

enum PowerAssertionError: LocalizedError {
    case creationFailed(PowerAssertion, IOReturn)

    var errorDescription: String? {
        switch self {
        case .creationFailed(_, let result):
            String(localized: "Power assertion failed with status \(result)")
        }
    }
}

@MainActor
final class IOKitPowerAssertionService: PowerAssertionService {
    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "assertions")
    private var held: [PowerAssertion: IOPMAssertionID] = [:]
    private let assertionName = "You Cannot Sleep is keeping your Mac awake" as CFString

    func apply(_ assertions: Set<PowerAssertion>) throws {
        for (assertion, identifier) in held where !isActive(identifier) {
            held.removeValue(forKey: assertion)
            logger.info("Recreating missing assertion \(String(describing: assertion), privacy: .public)")
        }
        let additions = assertions.subtracting(held.keys)
        var staged: [PowerAssertion: IOPMAssertionID] = [:]

        do {
            for assertion in additions {
                staged[assertion] = try create(assertion)
            }
        } catch {
            staged.values.forEach { IOPMAssertionRelease($0) }
            throw error
        }

        // Keep existing assertion types in place while adding new ones, then release obsolete types.
        held.merge(staged) { _, new in new }
        for assertion in held.keys.filter({ !assertions.contains($0) }) {
            if let identifier = held.removeValue(forKey: assertion) {
                let result = IOPMAssertionRelease(identifier)
                if result != kIOReturnSuccess {
                    logger.error("Failed to release assertion \(String(describing: assertion), privacy: .public): \(result)")
                }
            }
        }
    }

    func releaseAll() {
        for (assertion, identifier) in held {
            let result = IOPMAssertionRelease(identifier)
            if result != kIOReturnSuccess {
                logger.error("Failed to release assertion \(String(describing: assertion), privacy: .public): \(result)")
            }
        }
        held.removeAll()
    }

    private func create(_ assertion: PowerAssertion) throws -> IOPMAssertionID {
        var identifier: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(assertion.type, IOPMAssertionLevel(kIOPMAssertionLevelOn), assertionName, &identifier)
        guard result == kIOReturnSuccess else {
            logger.error("Failed to create assertion \(String(describing: assertion), privacy: .public): \(result)")
            throw PowerAssertionError.creationFailed(assertion, result)
        }
        return identifier
    }

    private func isActive(_ identifier: IOPMAssertionID) -> Bool {
        guard let unmanaged = IOPMAssertionCopyProperties(identifier) else { return false }
        let properties = unmanaged.takeRetainedValue() as NSDictionary
        guard let level = properties[kIOPMAssertionLevelKey] as? NSNumber else { return false }
        return level.intValue == Int(kIOPMAssertionLevelOn)
    }

    deinit {
        for identifier in held.values {
            IOPMAssertionRelease(identifier)
        }
    }
}
