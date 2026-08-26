import Foundation

/// What the player may start, and what Home's heading row has to say about it.
///
/// The one question the views ask about the paywall, with three answers and no
/// fourth: the app is Unlocked, or it is on its Free Matches with some left,
/// or it is **Locked** (`CONTEXT.md`). `HomeView` and the offer sheet read this
/// and nothing else — neither touches StoreKit and neither counts Matches, so
/// there is one place the paywall's rule is written down and one place a
/// change to it has to reach.
///
/// Derived rather than stored. Both halves it is made of are already the truth
/// somewhere else — the tally in `MatchStore`, the entitlement in
/// `UnlockStore` — and a third copy would be the one that goes stale.
enum GameAccess: Equatable {
    /// The Unlock is held. No meter, no wall, no offer: a player who has paid
    /// should be unable to tell the app ever had a paywall.
    case unlocked
    /// No Unlock, and Free Matches left to start. Carries them, because the
    /// meter draws the remainder rather than merely the fact of one.
    case free(FreeMatches)
    /// No Unlock and no Free Matches left. Starting a game raises the offer;
    /// nothing else in the app changes.
    case locked

    /// The answer, from the two things that decide it.
    ///
    /// The Unlock is asked about first and answers on its own: a player who has
    /// paid is Unlocked whatever the tally says, and the tally keeps counting
    /// underneath because nothing stops it — see `FreeMatches`.
    static func resolved(freeMatches: FreeMatches, isUnlocked: Bool) -> GameAccess {
        if isUnlocked { return .unlocked }
        return freeMatches.isExhausted ? .locked : .free(freeMatches)
    }

    /// What Home's meter should draw, or nothing at all when there is no meter
    /// to draw.
    ///
    /// Present while Locked, and full: the player has watched three marks fill
    /// and the third filling is what the wall is about — taking the meter away
    /// at exactly the moment it finishes explaining itself would be the one
    /// version of this that ambushes them. Gone only once Unlocked.
    var meter: FreeMatches? {
        switch self {
        case .unlocked: return nil
        case let .free(freeMatches): return freeMatches
        case .locked: return FreeMatches(startedMatches: FreeMatches.allowance)
        }
    }

    /// Whether tapping Gonga or Okey raises the offer instead of opening the
    /// Variant picker. The wall, and the whole of it.
    var isLocked: Bool { self == .locked }
}
