import Foundation

struct Entrant: Identifiable, Hashable {
    let id: UUID
    var name: String

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

enum EntrantMode: Hashable {
    case players
    case teams
}
