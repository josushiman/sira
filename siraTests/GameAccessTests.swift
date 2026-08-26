import XCTest
@testable import sira

/// The one question the views ask about the paywall, asserted directly.
///
/// Worth its own file rather than being inferred from a snapshot: `HomeView`
/// and the offer sheet read this and nothing else, so every rule the paywall
/// has is either here or nowhere.
final class GameAccessTests: XCTestCase {
    private func access(started: Int, unlocked: Bool) -> GameAccess {
        .resolved(freeMatches: FreeMatches(startedMatches: started), isUnlocked: unlocked)
    }

    func test_noGamesPlayedIsFreeWithThreeLeft() {
        XCTAssertEqual(access(started: 0, unlocked: false), .free(FreeMatches(startedMatches: 0)))
        XCTAssertEqual(access(started: 0, unlocked: false).meter?.remaining, 3)
    }

    func test_oneGamePlayedIsFreeWithTwoLeft() {
        XCTAssertEqual(access(started: 1, unlocked: false).meter?.remaining, 2)
        XCTAssertFalse(access(started: 1, unlocked: false).isLocked)
    }

    func test_twoGamesPlayedIsFreeWithOneLeft() {
        XCTAssertEqual(access(started: 2, unlocked: false).meter?.remaining, 1)
        XCTAssertFalse(access(started: 2, unlocked: false).isLocked)
    }

    func test_threeGamesPlayedIsLocked() {
        XCTAssertEqual(access(started: 3, unlocked: false), .locked)
        XCTAssertTrue(access(started: 3, unlocked: false).isLocked)
    }

    /// A player who kept playing past the allowance — which ticket 02 left
    /// possible and this ticket closes — is Locked, not something else.
    func test_playingPastTheAllowanceIsStillJustLocked() {
        XCTAssertEqual(access(started: 9, unlocked: false), .locked)
    }

    /// The Unlock answers on its own. The tally keeps counting underneath, and
    /// none of it changes anything.
    func test_theUnlockedPlayerIsUnlockedWhateverTheMeterSays() {
        for started in [0, 1, 2, 3, 40] {
            XCTAssertEqual(access(started: started, unlocked: true), .unlocked, "after \(started)")
            XCTAssertFalse(access(started: started, unlocked: true).isLocked, "after \(started)")
        }
    }

    /// Every trace of the paywall goes, the meter first.
    func test_anUnlockedPlayerHasNoMeterToDraw() {
        XCTAssertNil(access(started: 2, unlocked: true).meter)
    }

    /// And the meter is still there at the wall, full — the third mark filling
    /// is the thing the offer is about, so it is not taken away at the moment
    /// it finishes explaining itself.
    func test_aLockedPlayerStillHasAFullMeter() {
        let meter = access(started: 3, unlocked: false).meter
        XCTAssertEqual(meter?.used, 3)
        XCTAssertEqual(meter?.remaining, 0)
    }
}
