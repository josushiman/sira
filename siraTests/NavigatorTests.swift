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

    // MARK: - Routes Play cannot follow

    /// The guarantee Home's `openMatch` binding makes, pinned at the seam it
    /// is made from: a route naming a Match this build cannot score resolves
    /// to nothing, so Play is never pushed in front of one and the player is
    /// left on Home rather than on a screen with nothing on it.
    func test_aRouteNamingAMatchPlayCannotScoreResolvesToNothing() {
        let navigator = Navigator()
        let stranger = Match(
            game: .gonga,
            variantId: "gonga-from-a-later-release",
            mode: .players,
            entrants: [Entrant(name: "Alice")]
        )
        navigator.openMatchID = stranger.id

        XCTAssertNil([stranger].scorableMatch(navigator.openMatchID))
    }

    /// The other way a route stops resolving: the Match it names is gone, so
    /// the id finds nothing among the Matches that are left.
    func test_aRouteOutlivingTheMatchItNamesResolvesToNothing() {
        let navigator = Navigator()
        let deleted = Match(
            game: .gonga,
            variant: .gongaStandard,
            mode: .players,
            entrants: [Entrant(name: "Alice")]
        )
        navigator.openMatchID = deleted.id

        XCTAssertNil([Match]().scorableMatch(navigator.openMatchID))
    }

    /// The route Play should follow still resolves, or the gate would close
    /// on every Match rather than the two it is there for.
    func test_aRouteNamingAScorableMatchStillResolves() {
        let navigator = Navigator()
        let playable = Match(
            game: .okey,
            variant: .okeyStandard,
            mode: .teams,
            entrants: [Entrant(name: "Kırmızı"), Entrant(name: "Mavi")]
        )
        navigator.openMatchID = playable.id

        XCTAssertEqual([playable].scorableMatch(navigator.openMatchID)?.id, playable.id)
    }
}
