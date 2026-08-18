import Foundation

struct RejoinEvent: Hashable {
    let id: Entrant.ID
    let to: Int
}

struct Round: Identifiable, Hashable {
    let id: UUID
    var deltas: [Entrant.ID: Int]
    var rejoins: [RejoinEvent]
    /// Çifte: doubles this Round's deltas as each Engine applies them (every
    /// delta for Survival/Fixed Rounds, only the penalty for Elimination).
    var cifte: Bool

    init(id: UUID = UUID(), deltas: [Entrant.ID: Int], rejoins: [RejoinEvent] = [], cifte: Bool = false) {
        self.id = id
        self.deltas = deltas
        self.rejoins = rejoins
        self.cifte = cifte
    }
}
