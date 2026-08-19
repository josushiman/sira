import Foundation

/// The Home screen's Active / All / Archived chips.
enum MatchFilter: String, CaseIterable, Identifiable {
    case active = "Active"
    case all = "All"
    case archived = "Archived"

    var id: String { rawValue }

    func includes(_ match: Match) -> Bool {
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
