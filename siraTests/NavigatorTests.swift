import XCTest
@testable import sira

final class NavigatorTests: XCTestCase {
    /// Both routes into Play have to be cleared, not just the one that is
    /// currently set: a Match reached through the Variant picker leaves that
    /// item standing, and a Match opened from a Home card leaves the other.
    func test_goHomeClearsEveryPushedRoute() {
        let navigator = Navigator()
        navigator.pickingVariantsFor = .okey
        navigator.openMatchID = UUID()

        navigator.goHome()

        XCTAssertNil(navigator.pickingVariantsFor)
        XCTAssertNil(navigator.openMatchID)
    }

    func test_goHomeFromHomeIsANoOp() {
        let navigator = Navigator()

        navigator.goHome()

        XCTAssertNil(navigator.pickingVariantsFor)
        XCTAssertNil(navigator.openMatchID)
    }
}
