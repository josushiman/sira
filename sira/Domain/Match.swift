import Foundation
import SwiftData

/// One game being kept score of: who is playing, under which Variant's rules,
/// and every Round entered so far.
///
/// A model class rather than a value type — the domain types *are* the stored
/// types, with no mapping layer between them (`docs/adr/0006`). The practical
/// consequence for callers is that a Match handed around is one shared object:
/// mutating it is visible everywhere at once, and screens hold it directly
/// instead of through a `Binding`.
@Model
final class Match {
    var id: UUID
    var game: Game
    /// The id of the Variant this Match is played under, rather than a copy of
    /// the Variant itself, so a rule correction shipped in a later release
    /// reaches Matches that already exist instead of only new ones. See
    /// `Variant.id` for the frozen-id contract this creates, and
    /// `docs/adr/0007` for why it is stored this way.
    var variantId: String
    /// The Round count chosen at Setup, for the Variants that take one
    /// (Okey 101's 8 or 12). `nil` where the Round count isn't a Setup choice,
    /// in which case the Variant's own value stands.
    var roundCount: Int?
    var mode: EntrantMode
    /// The Entrants as held, owned by this Match and deleted with it, and not
    /// shared with any other Match (`docs/adr/0007`). Carries no ordering
    /// guarantee of its own: never read this for seating order — read
    /// `entrants`, which sorts by `Entrant.sequence`.
    @Relationship(deleteRule: .cascade, inverse: \Entrant.match)
    private(set) var storedEntrants: [Entrant]
    /// The Rounds as held, carrying no ordering guarantee of their own. Never
    /// read this for order — read `rounds`, which sorts by `Round.sequence`.
    @Relationship(deleteRule: .cascade, inverse: \Round.match)
    private(set) var storedRounds: [Round]
    var archived: Bool
    /// When the Match was started. Home lists Matches newest-first by this,
    /// and each card is titled with it, so it never changes after creation.
    var createdAt: Date

    /// Builds a Match from Entrants and Rounds that already carry their
    /// sequence, in whatever order they happen to be in — so a caller holding
    /// stored objects whose order means nothing doesn't have to invent one to
    /// build a Match.
    init(
        id: UUID = UUID(),
        game: Game,
        variantId: String,
        roundCount: Int? = nil,
        mode: EntrantMode,
        storedEntrants: [Entrant],
        storedRounds: [Round],
        archived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.game = game
        self.variantId = variantId
        self.roundCount = roundCount
        self.mode = mode
        self.storedEntrants = storedEntrants
        self.storedRounds = storedRounds
        self.archived = archived
        self.createdAt = createdAt
    }

    convenience init(
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
            // `entrants` is given in the order Setup wrote the names down and
            // `rounds` in the order they were played, so position is the
            // sequence — this is the only place that equivalence is allowed to
            // hold, and it holds because the caller has just stated the order.
            storedEntrants: entrants.enumerated().map { index, entrant in
                entrant.withSequence(index)
            },
            storedRounds: rounds.enumerated().map { index, round in
                round.withSequence(index)
            },
            archived: archived,
            createdAt: createdAt
        )
    }

    /// The Entrants in the order Setup seated them, which is the order the
    /// player expects to read them in and the order their dot-badge colours
    /// are picked from.
    var entrants: [Entrant] {
        storedEntrants.sorted { $0.sequence < $1.sequence }
    }

    /// The Rounds in the order they were played, which is the order every
    /// cumulative total, delta, Scoresheet row number and Undo depends on.
    var rounds: [Round] {
        storedRounds.sorted { $0.sequence < $1.sequence }
    }

    /// The sequence the next Round added will take. One past the highest in
    /// use, so an Undo followed by a new Round reuses the number it freed.
    private var nextSequence: Int {
        (storedRounds.map(\.sequence).max() ?? -1) + 1
    }

    /// Adds `round` as the Match's latest, stamping it with the next sequence.
    /// Whatever sequence the Round arrived with is overwritten: where a Round
    /// sits is the Match's to say, not the Round's.
    func addRound(_ round: Round) {
        storedRounds.append(round.withSequence(nextSequence))
    }

    /// Attaches `rejoin` to the latest Round, so undoing that Round undoes the
    /// Rejoin with it. A no-op with no Rounds, which the Rejoin flow can't
    /// reach — it is only offered in response to a Round just added.
    func recordRejoin(_ rejoin: RejoinEvent) {
        rounds.last?.rejoins.append(rejoin)
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

    /// Detaches the most recently added Round, including any Rejoin attached to
    /// it, and hands it back so its owner can delete it — leaving the Round out
    /// of the relationship is not the same as it ceasing to exist, and a Round
    /// belonging to no Match is an orphan (`MatchStore.undoLastRound(in:)`).
    ///
    /// Every downstream Standing recomputes from `rounds`, so this alone
    /// reverses totals, Out status, and Rejoins for any Engine.
    ///
    /// Deliberately not `@discardableResult`: throwing the Round away is the
    /// mistake this signature exists to make visible, so a caller with no use
    /// for it has to say `_ =` and mean it.
    func undoLastRound() -> Round? {
        guard let latest = rounds.last else { return nil }
        storedRounds.removeAll { $0.id == latest.id }
        return latest
    }

    /// Hides this Match from the Active filter without locking it — Rounds can
    /// still be added and standings still recompute normally.
    func archive() {
        archived = true
    }

    /// Returns an archived Match to the Active filter.
    func restore() {
        archived = false
    }
}

extension Match {
    /// Starts a Match under `variant`, recording its id and the Round count it
    /// carries. The Variant itself is not stored — `variant` resolves it afresh
    /// on every read — so this is a starting point rather than a copy.
    convenience init(
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
