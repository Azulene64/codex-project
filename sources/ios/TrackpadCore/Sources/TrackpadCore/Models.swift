import Foundation

public enum TrackpadEventType: String, Codable {
    case move, click, dragStart = "drag_start", dragMove = "drag_move", dragEnd = "drag_end"
    case scroll, zoom, ping, pong, error
}

public struct TrackpadEnvelope: Codable, Equatable {
    public let type: TrackpadEventType
    public let tsMs: Int64
    public let seq: Int64
    public let deviceID: String
    public let sessionID: String

    enum CodingKeys: String, CodingKey {
        case type, seq
        case tsMs = "ts_ms"
        case deviceID = "device_id"
        case sessionID = "session_id"
    }

    public init(type: TrackpadEventType, tsMs: Int64, seq: Int64, deviceID: String, sessionID: String) {
        self.type = type
        self.tsMs = tsMs
        self.seq = seq
        self.deviceID = deviceID
        self.sessionID = sessionID
    }
}

public struct MovePayload: Codable, Equatable {
    public let dx: Double
    public let dy: Double

    public init(dx: Double, dy: Double) {
        self.dx = dx
        self.dy = dy
    }
}

public struct ClickPayload: Codable, Equatable {
    public enum Button: String, Codable {
        case left
        case right
    }

    public let button: Button
    public let count: Int

    public init(button: Button, count: Int) {
        self.button = button
        self.count = count
    }
}

public struct ScrollPayload: Codable, Equatable {
    public let dx: Double
    public let dy: Double

    public init(dx: Double, dy: Double) {
        self.dx = dx
        self.dy = dy
    }
}

public struct ZoomPayload: Codable, Equatable {
    public let steps: Int

    public init(steps: Int) {
        self.steps = steps
    }
}

public struct TransportEvent<Payload: Codable & Equatable>: Codable, Equatable {
    public let envelope: TrackpadEnvelope
    public let payload: Payload

    public init(envelope: TrackpadEnvelope, payload: Payload) {
        self.envelope = envelope
        self.payload = payload
    }
}

public final class SequenceGenerator {
    private var value: Int64

    public init(seed: Int64 = 0) {
        self.value = seed
    }

    public func next() -> Int64 {
        value += 1
        return value
    }
}
