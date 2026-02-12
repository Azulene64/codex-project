import XCTest
@testable import TrackpadCore

final class ReconnectPolicyTests: XCTestCase {
    func testScheduleCapsAtFiveSeconds() {
        let policy = ReconnectPolicy()
        XCTAssertEqual(policy.delay(attempt: 1), 0.5)
        XCTAssertEqual(policy.delay(attempt: 2), 1)
        XCTAssertEqual(policy.delay(attempt: 3), 2)
        XCTAssertEqual(policy.delay(attempt: 4), 4)
        XCTAssertEqual(policy.delay(attempt: 5), 5)
        XCTAssertEqual(policy.delay(attempt: 8), 5)
    }
}
