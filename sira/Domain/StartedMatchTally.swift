import Foundation
import SwiftData

/// How many Matches have ever Started on this device — the number the Free
/// Match limit is measured against.
///
/// Stored alongside the Matches, in the same database, so that the tally and
/// the Round that moved it are written by one save and cannot disagree: a
/// Round on the disk with the Start it caused missing from the tally is a free
/// game given away, and the reverse is one taken.
///
/// A stored row rather than a count of Started Matches taken on demand,
/// because the two are not the same number and only this one is the truth.
/// Deleting a Started Match removes it from any such count; the game was still
/// played. The tally only ever goes up — see `recordStart()`.
///
/// Deliberately *not* in the Keychain. A reinstall takes this with it and the
/// player gets three fresh Matches, which is a choice rather than an
/// oversight: a counter that survives deleting the app is the kind of thing
/// players notice and resent, and the Unlock itself is restored by StoreKit
/// regardless.
///
/// There is one row. Nothing enforces that at the schema level — SwiftData has
/// no notion of a singleton — so `MatchStore` is the one place that reads or
/// creates it, and it creates one only when there is a Start to record.
@Model
final class StartedMatchTally {
    /// The count itself. Write it through `recordStart()`, never directly:
    /// this number is monotonic, and the only thing that may happen to it is
    /// going up by one.
    var startedMatches: Int

    init(startedMatches: Int = 0) {
        self.startedMatches = startedMatches
    }

    /// Records one Match Starting.
    ///
    /// One-way, like `Match.start()` and for the same reason: Undo removes a
    /// Round, never the fact that a game was played. Nothing decrements this —
    /// undoing a Round, deleting a Match and archiving one all leave it where
    /// it was.
    func recordStart() {
        startedMatches += 1
    }
}
