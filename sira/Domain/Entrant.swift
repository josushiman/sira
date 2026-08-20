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
    /// Where this Entrant sits at the table, assigned by the Match when it is
    /// built and never changed afterwards — Entrants cannot be added to or
    /// removed from a Match. Order is carried here rather than by position in
    /// `Match.entrants` for the same reason `Round.sequence` exists: position
    /// in a relationship array is not a guarantee a store can make, and an
    /// Entrant's seat decides their dot-badge colour, which has no business
    /// changing between launches of a Match whose scores have not moved.
    ///
    /// Deliberately absent from `init`: an Entrant has no opinion about where
    /// they sit, so only a Match can stamp one, via `withSequence(_:)`.
    private(set) var sequence = 0
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
}
