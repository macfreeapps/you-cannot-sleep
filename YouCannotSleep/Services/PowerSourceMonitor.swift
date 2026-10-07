import Foundation
import IOKit
import IOKit.ps
import OSLog

struct PowerState: Equatable {
    var hasBattery: Bool
    var isOnAC: Bool
    var batteryPercent: Int?

    static let unavailable = PowerState(hasBattery: false, isOnAC: true, batteryPercent: nil)
}

@MainActor
final class PowerSourceMonitor {
    var onChange: ((PowerState) -> Void)?
    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "power")
    private var source: CFRunLoopSource?

    init() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        if let unmanaged = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let monitor = Unmanaged<PowerSourceMonitor>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async { monitor.refresh() }
        }, context) {
            source = unmanaged.takeRetainedValue()
            if let source {
                CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            }
        } else {
            logger.error("Could not create power source notification run loop source")
        }
        refresh()
    }

    func refresh() {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            onChange?(.unavailable)
            return
        }
        let powerSourceType = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() as String?
        let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] ?? []
        var hasBattery = false
        var capacity: Int?

        for source in list {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any] else { continue }
            let isPresent = description[kIOPSIsPresentKey] as? Bool ?? true
            let sourceType = description[kIOPSTypeKey] as? String
            guard isPresent, sourceType == kIOPSInternalBatteryType else { continue }
            hasBattery = true
            let current = description[kIOPSCurrentCapacityKey] as? Int
            let maximum = description[kIOPSMaxCapacityKey] as? Int ?? 100
            if let current, maximum > 0 {
                capacity = min(max((current * 100) / maximum, 0), 100)
            }
        }

        let state = PowerState(hasBattery: hasBattery, isOnAC: powerSourceType == kIOPSACPowerValue, batteryPercent: capacity)
        onChange?(state)
    }

    func stop() {
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            self.source = nil
        }
    }
}
