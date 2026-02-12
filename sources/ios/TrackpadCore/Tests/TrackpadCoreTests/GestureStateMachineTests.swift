import XCTest
@testable import TrackpadCore

final class GestureStateMachineTests: XCTestCase {
    func testSingleTap() {
        let machine = GestureStateMachine()
        machine.onTouchBegan(TouchPoint(x: 100, y: 100, timestampMs: 1000))
        let output = machine.onTouchEnded(TouchPoint(x: 101, y: 101, timestampMs: 1150))
        XCTAssertEqual(output, .leftClick)
    }

    func testDoubleTap() {
        let machine = GestureStateMachine()
        machine.onTouchBegan(TouchPoint(x: 100, y: 100, timestampMs: 1000))
        _ = machine.onTouchEnded(TouchPoint(x: 100, y: 100, timestampMs: 1120))

        machine.onTouchBegan(TouchPoint(x: 102, y: 102, timestampMs: 1200))
        let output = machine.onTouchEnded(TouchPoint(x: 102, y: 102, timestampMs: 1300))
        XCTAssertEqual(output, .leftDoubleClick)
    }

    func testLongPressStartsDrag() {
        let machine = GestureStateMachine()
        machine.onTouchBegan(TouchPoint(x: 10, y: 10, timestampMs: 1000))
        let start = machine.onTouchMoved(TouchPoint(x: 12, y: 10, timestampMs: 3005))
        XCTAssertEqual(start, .dragStart)

        let move = machine.onTouchMoved(TouchPoint(x: 15, y: 12, timestampMs: 3010))
        XCTAssertEqual(move, .dragMove(dx: 3, dy: 2))

        let end = machine.onTouchEnded(TouchPoint(x: 15, y: 12, timestampMs: 3020))
        XCTAssertEqual(end, .dragEnd)
    }
}
