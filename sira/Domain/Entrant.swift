import Foundation
import SwiftData

/// A player or a team of two, scored uniformly regardless of which.
///
/// Owned by its Match and removed with it: Entrants are deliberately **not**
/// shared between Matches, so two Matches with a player called Alice hold two
/// separate Entrants. See `docs/adr/0007` for why that direction is the cheap
/// one, and what a shared identity would have to look like if it is ever added.
@Model
final class Entrant {
    /// The identity everything else in the domain refers an Entrant by — Round
    /// deltas, Çifte callers, Rejoins and Standings are all keyed on it. Kept
    /// as our own UUID rather than leaning on `persistentModelID` so those keys
    /// mean the same thing before a Match is stored as after.
    ///
    /// Declaring it also decides what `Entrant.ID` means: it shadows the
    /// `PersistentModel` conformance's own `id`, so `Entrant.ID` is `UUID` and
    /// not `PersistentIdentifier`. `Round.deltas`, `cifteCallers` and
    /// `RejoinEvent` are all typed on that, so removing this property would
    /// quietly retype the whole domain rather than fail where it was deleted.
    var id: UUID
    var name: String
    /// This Entrant's **Seat** — where they sit at the table, assigned by the
    /// Match when it seats them, at Setup or at whichever Round they arrived
    /// at, and never changed afterwards. Entrants can be added to a Match;
    /// they can never be removed from one.
    ///
    /// Spelled `sequence` here and `seat` everywhere else — `EntrantName.seat`,
    /// `RosterAddition.seat`, `Match.nextSeat`, `CONTEXT.md` — because this is
    /// the stored property, and the storage-order argument it shares with
    /// `Round.sequence` is the reason it exists. Read it as "the Seat as
    /// stored"; renaming it is a schema change for a synonym, which is not a
    /// trade worth making.
    ///
    /// A Seat is carried here rather than by position in `Match.entrants`
    /// because position in a relationship array is not a guarantee a store can
    /// make, and a Seat decides its Entrant's dot-badge colour, which has no
    /// business changing between launches of a Match whose scores have not
    /// moved.
    ///
    /// Deliberately absent from `init`: an Entrant has no opinion about where
    /// they sit, so only a Match can stamp one, via `withSequence(_:)`.
    private(set) var sequence = 0
    /// Whether this Entrant took a free seat partway through the Match rather
    /// than sitting down at Setup. What it decides is *from when* they are
    /// scored: someone seated at Setup is in the Match from its first Round,
    /// while someone who arrived is in it from the Round carrying their
    /// `JoinEvent` — and in none of it at all where no Round carries one.
    ///
    /// Carried by the Entrant rather than derived from the Rounds, which is
    /// where it used to be read from and is one Undo away from being wrong.
    /// Undoing the Round a join sits on takes the JoinEvent with it, and an
    /// arrival derived from the JoinEvent alone would then read as an Entrant
    /// who had been at the table from the start on a total of zero — a player
    /// the Match invents rather than the orphan the Undo actually left.
    ///
    /// Defaults to `false`, which is what every Entrant stored before this
    /// existed truthfully is: seated at Setup.
    ///
    /// Deliberately absent from `init`, like `sequence`: an Entrant has no
    /// opinion about when they arrived, so only a Match can say, via
    /// `arrivingMidMatch()`.
    private(set) var arrivedMidMatch = false
    /// The Match that owns this Entrant. The inverse of `Match.storedEntrants`,
    /// declared there.
    ///
    /// Settable only from this file, so an Entrant cannot be moved to another
    /// Match or detached from the one it has. That is not tidiness: a Round's
    /// `deltas` and `cifteCallers` are keyed by `Entrant.ID` with no
    /// referential integrity behind them, and `docs/adr/0006` records that this
    /// is safe *only* while Entrants cannot be removed from a Match. Re-parent
    /// one and every key naming it silently orphans.
    private(set) var match: Match?

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    /// The uppercased first letter of `name` for dot-badge display, or `?`
    /// when the name is empty/whitespace-only.
    var initial: String { name.dotBadgeInitial }

    /// Stamps this Entrant as sitting at `sequence` in their Match and returns
    /// them. The only way to set a seat, so a caller reconstituting stored
    /// Entrants has to say so explicitly.
    ///
    /// An Entrant is a reference type, so this stamps **in place** and hands
    /// back the same object rather than a restamped copy.
    @discardableResult
    func withSequence(_ sequence: Int) -> Entrant {
        self.sequence = sequence
        return self
    }

    /// Marks this Entrant as having taken a free seat partway through their
    /// Match, and returns them. One-way: an arrival is a fact about how they
    /// got to the table, and undoing the Round their arrival was recorded
    /// against does not turn them into someone who was there all along.
    ///
    /// Stamps **in place** and hands back the same object, as `withSequence`
    /// does, for the same reason: an Entrant is a reference type.
    @discardableResult
    func arrivingMidMatch() -> Entrant {
        arrivedMidMatch = true
        return self
    }
}

extension String {
    /// The uppercased first non-whitespace letter for dot-badge display, or
    /// `?` when empty — shared by Entrant, EntrantStanding, and Setup's
    /// in-progress name rows so all three agree on the same fallback.
    var dotBadgeInitial: String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(1)).uppercased()
    }
}

/// Whether a Match's Entrants are individuals or teams. Stored on the Match,
/// so its raw values are part of the stored form and must stay stable — the
/// same contract `Variant.id` carries.
enum EntrantMode: String, Codable, Hashable {
    case players
    case teams

    /// What one Entrant is called on a Match played this way — `player`,
    /// `team`. The word every screen that has to name one reads from, so
    /// Setup's placeholder, the rename sheet's copy and the seat-derived
    /// fallback cannot drift apart into three spellings of the same idea.
    ///
    /// Lowercase, because that is how it reads mid-sentence; a caller starting
    /// a phrase with it capitalizes it there.
    var entrantNoun: String {
        switch self {
        case .players: return "player"
        case .teams: return "team"
        }
    }
}
