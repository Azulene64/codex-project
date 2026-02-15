import Foundation
import Combine
import TrackpadCore

@MainActor
final class TrackpadViewModel: ObservableObject {
    enum ConnectionState: String {
        case disconnected = "未接続"
        case connecting = "接続中"
        case connected = "接続済み"
    }

    @Published var state: ConnectionState = .disconnected
    @Published var sensitivityPreset: String = "標準"

    private let gestureMachine = GestureStateMachine()
    private let socketClient = WebSocketSessionClient()

    init() {
        socketClient.onConnectionStateChanged = { [weak self] connected in
            Task { @MainActor in
                self?.state = connected ? .connected : .disconnected
            }
        }
    }

    func connect(host: String, port: Int) {
        state = .connecting
        socketClient.connect(host: host, port: port)
    }

    func touchBegan(x: Double, y: Double, tsMs: Int64) {
        gestureMachine.onTouchBegan(TouchPoint(x: x, y: y, timestampMs: tsMs))
    }

    func touchMoved(x: Double, y: Double, tsMs: Int64) {
        if let output = gestureMachine.onTouchMoved(TouchPoint(x: x, y: y, timestampMs: tsMs)) {
            socketClient.send(gesture: output)
        }
    }

    func touchEnded(x: Double, y: Double, tsMs: Int64) {
        if let output = gestureMachine.onTouchEnded(TouchPoint(x: x, y: y, timestampMs: tsMs)) {
            socketClient.send(gesture: output)
        }
    }
}
