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
}
