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
    /// The Rounds as stored, in no particular order. Never read this for
    /// order — read `rounds`, which sorts by `Round.sequence`. It is exposed
    /// only so a store can hand back what it loaded without pretending the
    /// order it arrived in means anything.
    private(set) var unorderedRounds: [Round]
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
        self.init(
            id: id,
            game: game,
            variantId: variantId,
            roundCount: roundCount,
            mode: mode,
            entrants: entrants,
            // `rounds` is given in the order it was played, so position is the
            // sequence — this is the only place that equivalence is allowed to
            // hold, and it holds because the caller has just stated the order.
            unorderedRounds: rounds.enumerated().map { index, round in
                var numbered = round
                numbered.sequence = index
                return numbered
            },
            archived: archived,
            createdAt: createdAt
        )
    }

    /// Builds a Match from Rounds that already carry their sequence, in
    /// whatever order they came back in. This is the load path: a store
    /// reconstitutes a Match without having to preserve, or invent, an order.
    init(
        id: UUID = UUID(),
        game: Game,
        variantId: String,
        roundCount: Int? = nil,
        mode: EntrantMode,
        entrants: [Entrant],
        unorderedRounds: [Round],
        archived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.game = game
        self.variantId = variantId
        self.roundCount = roundCount
        self.mode = mode
        self.entrants = entrants
        self.unorderedRounds = unorderedRounds
        self.archived = archived
        self.createdAt = createdAt
    }

    /// The Rounds in the order they were played, which is the order every
    /// cumulative total, delta, Scoresheet row number and Undo depends on.
    var rounds: [Round] {
        unorderedRounds.sorted { $0.sequence < $1.sequence }
    }

    /// The sequence the next Round added will take. One past the highest in
    /// use, so an Undo followed by a new Round reuses the number it freed.
    private var nextSequence: Int {
        (unorderedRounds.map(\.sequence).max() ?? -1) + 1
    }

    /// Adds `round` as the Match's latest, stamping it with the next sequence.
    /// Whatever sequence the Round arrived with is overwritten: where a Round
    /// sits is the Match's to say, not the Round's.
    mutating func addRound(_ round: Round) {
        var round = round
        round.sequence = nextSequence
        unorderedRounds.append(round)
    }

    /// Attaches `rejoin` to the latest Round, so undoing that Round undoes the
    /// Rejoin with it. A no-op with no Rounds, which the Rejoin flow can't
    /// reach — it is only offered in response to a Round just added.
    mutating func recordRejoin(_ rejoin: RejoinEvent) {
        guard let latest = rounds.last,
              let index = unorderedRounds.firstIndex(where: { $0.id == latest.id })
        else { return }
        unorderedRounds[index].rejoins.append(rejoin)
    }

    /// Empties the Match of Rounds, freeing every sequence. Used to rebuild a
    /// Match Round by Round — the Scoresheet's derivation — rather than to
    /// discard history.
    mutating func removeAllRounds() {
        unorderedRounds.removeAll()
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
        guard let latest = rounds.last else { return }
        unorderedRounds.removeAll { $0.id == latest.id }
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
