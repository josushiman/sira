import Foundation

/// The Home screen's Active / All / Archived chips.
enum MatchFilter: String, CaseIterable, Identifiable {
    case active = "Active"
    case all = "All"
    case archived = "Archived"

    var id: String { rawValue }

    /// Whether this filter lists `match`.
    ///
    /// Started is asked first, and of every filter alike: Home lists games
    /// that have been scored, and the three chips are views of that list
    /// rather than three separate answers to what belongs on Home. "All" means
    /// all of the Started ones — a Match nobody has scored is not history
    /// hidden under the wrong chip, it is not history at all.
    ///
    /// Read off the flag rather than the Round count, which is the difference
    /// between a Match whose only Round was undone staying on Home and
    /// vanishing while the player corrects a mistake (`Match.started`).
    func includes(_ match: Match) -> Bool {
        guard match.started else { return false }
        switch self {
        case .active: return !match.archived
        case .all: return true
        case .archived: return match.archived
        }
    }

    /// The Matches this filter shows, newest-started first — the order Home
    /// lists them in under every filter.
    func apply(to matches: [Match]) -> [Match] {
        matches
            .filter(includes)
            .sorted { $0.createdAt > $1.createdAt }
    }
}
