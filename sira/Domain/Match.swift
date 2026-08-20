import Foundation

struct Match: Identifiable, Hashable {
    let id: UUID
    var game: Game
    /// The id of the Variant this Match is played under, rather than a copy of
    /// the Variant itself, so a rule correction shipped in a later release
    /// reaches Matches that already exist instead of only new ones. See
    /// `Variant.id` for the frozen-id contract this creates.
    var variantId: String
    /// The Round count chosen at Setup, for the Variants that take one
    /// (Okey 101's 8 or 12). `nil` where the Round count isn't a Setup choice,
    /// in which case the Variant's own value stands.
    var roundCount: Int?
    var mode: EntrantMode
    var entrants: [Entrant]
    var rounds: [Round]
    var archived: Bool
    /// When the Match was started. Home lists Matches newest-first by this,
    /// and each card is titled with it, so it never changes after creation.
    let createdAt: Date

    init(
        id: UUID = UUID(),
        game: Game,
        variantId: String,
        roundCount: Int? = nil,
        mode: EntrantMode,
        entrants: [Entrant],
        rounds: [Round] = [],
        archived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.game = game
        self.variantId = variantId
        self.roundCount = roundCount
        self.mode = mode
        self.entrants = entrants
        self.rounds = rounds
        self.archived = archived
        self.createdAt = createdAt
    }

    /// The Variant this Match is played under, resolved from `variantId`
    /// against the Variants shipped for its Game, with the Setup-chosen Round
    /// count applied on top.
    ///
    /// `nil` when the id resolves to nothing — a Match naming a Variant this
    /// build doesn't know is skipped rather than scored by a substitute, so a
    /// downgrade or a bad write stays recoverable rather than becoming terminal.
    var variant: Variant? {
        guard var resolved = Variant.all(for: game).first(where: { $0.id == variantId }) else {
            return nil
        }
        if let roundCount {
            resolved.roundCount = roundCount
        }
        return resolved
    }

    /// Removes the most recently added Round, including any Rejoin attached to it.
    /// Every downstream Standing recomputes from `rounds`, so this alone reverses
    /// totals, Out status, and Rejoins for any Engine.
    mutating func undoLastRound() {
        guard !rounds.isEmpty else { return }
        rounds.removeLast()
    }

    /// Hides this Match from the Active filter without locking it — Rounds can
    /// still be added and standings still recompute normally.
    mutating func archive() {
        archived = true
    }

    /// Returns an archived Match to the Active filter.
    mutating func restore() {
        archived = false
    }
}

extension Match {
    /// Starts a Match under `variant`, recording its id and the Round count it
    /// carries. The Variant itself is not stored — `variant` resolves it afresh
    /// on every read — so this is a starting point rather than a copy.
    init(
        id: UUID = UUID(),
        game: Game,
        variant: Variant,
        mode: EntrantMode,
        entrants: [Entrant],
        rounds: [Round] = [],
        archived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.init(
            id: id,
            game: game,
            variantId: variant.id,
            roundCount: variant.roundCount,
            mode: mode,
            entrants: entrants,
            rounds: rounds,
            archived: archived,
            createdAt: createdAt
        )
    }
}
