import Foundation

struct Match: Identifiable, Hashable {
    let id: UUID
    var game: Game
    var variant: Variant
    var mode: EntrantMode
    var entrants: [Entrant]
    var rounds: [Round]
    var archived: Bool
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        game: Game,
        variant: Variant,
        mode: EntrantMode,
        entrants: [Entrant],
        rounds: [Round] = [],
        archived: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.game = game
        self.variant = variant
        self.mode = mode
        self.entrants = entrants
        self.rounds = rounds
        self.archived = archived
        self.updatedAt = updatedAt
    }

    /// Removes the most recently added Round, including any Rejoin attached to it.
    /// Every downstream Standing recomputes from `rounds`, so this alone reverses
    /// totals, Out status, and Rejoins for any Engine.
    mutating func undoLastRound() {
        guard !rounds.isEmpty else { return }
        rounds.removeLast()
    }
}
