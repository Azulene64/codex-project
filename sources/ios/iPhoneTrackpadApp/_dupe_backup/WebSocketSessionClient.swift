import Foundation
import TrackpadCore

final class WebSocketSessionClient {
    var onConnectionStateChanged: ((Bool) -> Void)?

    private let session = URLSession(configuration: .default)
    private var task: URLSessionWebSocketTask?
    private let encoder = JSONEncoder()
    private let deviceID = UUID().uuidString
    private var sessionID = UUID().uuidString
    private var sequence = SequenceGenerator()
    private let reconnect = ReconnectPolicy()
    private var reconnectAttempt = 0

    func connect(host: String, port: Int) {
        guard let url = URL(string: "ws://\(host):\(port)/ws") else { return }
        task?.cancel()
        task = session.webSocketTask(with: url)
        task?.resume()
        listen()
        sendPing()
        onConnectionStateChanged?(true)
    }

    private func listen() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.reconnectAttempt = 0
                self.listen()
            case .failure:
                self.onConnectionStateChanged?(false)
                self.scheduleReconnect()
            }
        }
    }

    private func scheduleReconnect() {
        reconnectAttempt += 1
        let delay = reconnect.delay(attempt: reconnectAttempt)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            // host/port保持はMVP次工程で設定ストアに移譲
            self.onConnectionStateChanged?(false)
        }
    }

    private func sendPing() {
        task?.sendPing { _ in }
    }

    func send(gesture: GestureOutput) {
        let envelope = TrackpadEnvelope(
            type: eventType(for: gesture),
            tsMs: Int64(Date().timeIntervalSince1970 * 1000),
            seq: sequence.next(),
            deviceID: deviceID,
            sessionID: sessionID
        )

        do {
            let messageData: Data
            switch gesture {
            case let .move(dx, dy), let .dragMove(dx, dy):
                let payload = MovePayload(dx: dx, dy: dy)
                messageData = try encoder.encode(TransportEvent(envelope: envelope, payload: payload))
            case .leftClick:
                let payload = ClickPayload(button: .left, count: 1)
                messageData = try encoder.encode(TransportEvent(envelope: envelope, payload: payload))
            case .leftDoubleClick:
                let payload = ClickPayload(button: .left, count: 2)
                messageData = try encoder.encode(TransportEvent(envelope: envelope, payload: payload))
            case .dragStart, .dragEnd:
                messageData = try encoder.encode(TransportEvent(envelope: envelope, payload: [String: String]()))
            }

            task?.send(.data(messageData)) { _ in }
        } catch {
            onConnectionStateChanged?(false)
        }
    }

    private func eventType(for gesture: GestureOutput) -> TrackpadEventType {
        switch gesture {
        case .move:
            return .move
        case .leftClick, .leftDoubleClick:
            return .click
        case .dragStart:
            return .dragStart
        case .dragMove:
            return .dragMove
        case .dragEnd:
            return .dragEnd
        }
    }
}
