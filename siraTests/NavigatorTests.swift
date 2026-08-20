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

    /// Deletion is the one way a Match a route names can stop existing. The
    /// route has to go with it: a `navigationDestination` naming a Match that
    /// is no longer there has nothing to draw.
    func test_aRouteNamingADeletedMatchIsCleared() {
        let navigator = Navigator()
        let deleted = UUID()
        navigator.openMatchID = deleted

        navigator.closeDeletedMatch(deleted)

        XCTAssertNil(navigator.openMatchID)
    }

    /// Only the Match that was deleted. Another Match being removed from Home
    /// is no reason to close the one the player is looking at.
    func test_aRouteNamingAnotherMatchIsLeftAlone() {
        let navigator = Navigator()
        let open = UUID()
        navigator.openMatchID = open

        navigator.closeDeletedMatch(UUID())

        XCTAssertEqual(navigator.openMatchID, open)
    }

    func test_goHomeFromHomeIsANoOp() {
        let navigator = Navigator()

        navigator.goHome()

        XCTAssertNil(navigator.pickingVariantsFor)
        XCTAssertNil(navigator.openMatchID)
    }
}
