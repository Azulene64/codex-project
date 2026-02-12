import Foundation

public struct GestureThresholds {
    public let tapMaxDurationMs: Int
    public let tapMaxMovementPx: Double
    public let doubleTapIntervalMs: Int
    public let doubleTapPositionTolerancePx: Double
    public let longPressMs: Int
    public let longPressCancelMovementPx: Double

    public init(
        tapMaxDurationMs: Int = 180,
        tapMaxMovementPx: Double = 10,
        doubleTapIntervalMs: Int = 250,
        doubleTapPositionTolerancePx: Double = 20,
        longPressMs: Int = 2000,
        longPressCancelMovementPx: Double = 15
    ) {
        self.tapMaxDurationMs = tapMaxDurationMs
        self.tapMaxMovementPx = tapMaxMovementPx
        self.doubleTapIntervalMs = doubleTapIntervalMs
        self.doubleTapPositionTolerancePx = doubleTapPositionTolerancePx
        self.longPressMs = longPressMs
        self.longPressCancelMovementPx = longPressCancelMovementPx
    }
}

public struct TouchPoint: Equatable {
    public let x: Double
    public let y: Double
    public let timestampMs: Int64

    public init(x: Double, y: Double, timestampMs: Int64) {
        self.x = x
        self.y = y
        self.timestampMs = timestampMs
    }

    public func distance(from other: TouchPoint) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}

public enum GestureOutput: Equatable {
    case move(dx: Double, dy: Double)
    case leftClick
    case leftDoubleClick
    case dragStart
    case dragMove(dx: Double, dy: Double)
    case dragEnd
}

public final class GestureStateMachine {
    private enum State {
        case idle
        case touching(start: TouchPoint, last: TouchPoint)
        case dragging(last: TouchPoint)
    }

    private var state: State = .idle
    private let thresholds: GestureThresholds
    private var lastTap: TouchPoint?

    public init(thresholds: GestureThresholds = .init()) {
        self.thresholds = thresholds
    }

    public func onTouchBegan(_ point: TouchPoint) {
        state = .touching(start: point, last: point)
    }

    public func onTouchMoved(_ point: TouchPoint) -> GestureOutput? {
        switch state {
        case .idle:
            return nil
        case let .touching(start, last):
            let moved = point.distance(from: start)
            if point.timestampMs - start.timestampMs >= Int64(thresholds.longPressMs),
               moved <= thresholds.longPressCancelMovementPx {
                state = .dragging(last: point)
                return .dragStart
            }

            state = .touching(start: start, last: point)
            return .move(dx: point.x - last.x, dy: point.y - last.y)
        case let .dragging(last):
            state = .dragging(last: point)
            return .dragMove(dx: point.x - last.x, dy: point.y - last.y)
        }
    }

    public func onTouchEnded(_ point: TouchPoint) -> GestureOutput? {
        defer { state = .idle }
        switch state {
        case .idle:
            return nil
        case let .touching(start, _):
            let duration = point.timestampMs - start.timestampMs
            let movement = point.distance(from: start)
            guard duration <= Int64(thresholds.tapMaxDurationMs), movement <= thresholds.tapMaxMovementPx else {
                return nil
            }

            if let lastTap,
               point.timestampMs - lastTap.timestampMs <= Int64(thresholds.doubleTapIntervalMs),
               point.distance(from: lastTap) <= thresholds.doubleTapPositionTolerancePx {
                self.lastTap = nil
                return .leftDoubleClick
            }

            self.lastTap = point
            return .leftClick
        case .dragging:
            return .dragEnd
        }
    }
}
