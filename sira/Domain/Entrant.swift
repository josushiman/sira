import Foundation

struct Entrant: Identifiable, Hashable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

enum EntrantMode: Hashable {
    case players
    case teams
}
