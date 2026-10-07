import Foundation

@MainActor
protocol ScheduledTask: AnyObject {
    func cancel()
}

@MainActor
protocol SessionClock: AnyObject {
    var now: Date { get }
    func schedule(at date: Date, tolerance: TimeInterval, _ action: @escaping () -> Void) -> ScheduledTask
}

@MainActor
final class SystemSessionClock: SessionClock {
    var now: Date { Date() }

    func schedule(at date: Date, tolerance: TimeInterval, _ action: @escaping () -> Void) -> ScheduledTask {
        let timer = Timer(fireAt: date, interval: 0, target: BlockTimerTarget(action), selector: #selector(BlockTimerTarget.fire), userInfo: nil, repeats: false)
        timer.tolerance = max(0, tolerance)
        RunLoop.main.add(timer, forMode: .common)
        return TimerTask(timer: timer)
    }
}

@MainActor
private final class BlockTimerTarget: NSObject {
    private let action: () -> Void
    init(_ action: @escaping () -> Void) { self.action = action }
    @objc func fire() { action() }
}

@MainActor
private final class TimerTask: ScheduledTask {
    private var timer: Timer?
    init(timer: Timer) { self.timer = timer }
    func cancel() { timer?.invalidate(); timer = nil }
}
