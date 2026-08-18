import Foundation

struct RejoinEvent: Hashable {
    let id: Entrant.ID
    let to: Int
}

struct Round: Identifiable, Hashable {
    let id: UUID
    var deltas: [Entrant.ID: Int]
    var rejoin: RejoinEvent?

    init(id: UUID = UUID(), deltas: [Entrant.ID: Int], rejoin: RejoinEvent? = nil) {
        self.id = id
        self.deltas = deltas
        self.rejoin = rejoin
    }
}
