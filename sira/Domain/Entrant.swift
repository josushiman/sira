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
    var id: UUID
    var name: String
    /// The Match that owns this Entrant. The inverse of `Match.entrants`,
    /// declared there.
    var match: Match?

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    /// The uppercased first letter of `name` for dot-badge display, or `?`
    /// when the name is empty/whitespace-only.
    var initial: String { name.dotBadgeInitial }
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
