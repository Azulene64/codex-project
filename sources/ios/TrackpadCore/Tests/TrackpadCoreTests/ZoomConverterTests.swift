import XCTest
@testable import TrackpadCore

final class ZoomConverterTests: XCTestCase {
    func testDeadzone() {
        let converter = ZoomConverter()
        XCTAssertNil(converter.steps(fromScale: 1.01))
    }

    func testClampPositive() {
        let converter = ZoomConverter()
        XCTAssertEqual(converter.steps(fromScale: 4.0), 4)
    }

    func testClampNegative() {
        let converter = ZoomConverter()
        XCTAssertEqual(converter.steps(fromScale: 0.2), -4)
    }
}
