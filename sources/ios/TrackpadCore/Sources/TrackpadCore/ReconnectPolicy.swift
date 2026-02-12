import Foundation

public struct ReconnectPolicy {
    private let schedule: [TimeInterval] = [0.5, 1, 2, 4, 5]

    public init() {}

    public func delay(attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return schedule[0] }
        if attempt <= schedule.count {
            return schedule[attempt - 1]
        }
        return schedule[schedule.count - 1]
    }
}
