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
    // The number this Match is played at, in the three shapes the Win
    // Conditions take it in. At most one is non-`nil` for any given Match —
    // the one its Variant's Win Condition calls for — because a number that
    // does not describe a Match is worse than an absent one. Read through
    // `variantNumber`, never directly: that accessor is the only place that
    // knows which of the three this Match's Win Condition means.
    /// The score limit this Match is played to, for a Survival Match. `nil`
    /// on any other Win Condition, which is not played to a limit at all.
    var limit: Int?
    /// The score this Match's Entrants count down from, for an Elimination
    /// Match. `nil` on any other Win Condition.
    var startingScore: Int?
    /// The number of Rounds this Match runs for, for a Fixed Rounds Match.
    /// `nil` on any other Win Condition.
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
        limit: Int? = nil,
        startingScore: Int? = nil,
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
        self.limit = limit
        self.startingScore = startingScore
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
        limit: Int? = nil,
        startingScore: Int? = nil,
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
            limit: limit,
            startingScore: startingScore,
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
    /// against the Variants shipped for its Game.
    ///
    /// Shape only: how the Match is scored, and nothing about how far it runs.
    /// The number it is played at is the Match's own, and is read through
    /// `variantNumber`.
    ///
    /// `nil` when the id resolves to nothing — a Match naming a Variant this
    /// build doesn't know is skipped rather than scored by a substitute, so a
    /// downgrade or a bad write stays recoverable rather than becoming terminal.
    var variant: Variant? {
        Variant.all(for: game).first(where: { $0.id == variantId })
    }

    /// The number this Match is played at — the limit it is played to, the
    /// score it counts down from, or the count of Rounds it runs for,
    /// whichever its Variant's Win Condition takes.
    ///
    /// The one place that number is resolved. Before this existed, each caller
    /// resolved it off the Variant and invented its own answer for the case
    /// where it was missing — an unreachable limit in one place, a limit of
    /// zero in another — so the same unscoreable Match meant something
    /// different depending on who asked. Here it means one thing: `nil`.
    ///
    /// Resolved from the Match alone. The Variant supplies which of the three
    /// numbers the Match is played at, never the number itself — a limit is a
    /// table's decision, not a rule a later release could correct on their
    /// behalf, so there is nothing in the binary to stand in for it.
    ///
    /// A Match that resolves `nil` here is skipped at the `scorable` gate
    /// exactly as a Match naming an unknown Variant id is — never scored
    /// against a substitute, and never deleted (`docs/adr/0007`).
    var variantNumber: Int? {
        guard let variant else { return nil }
        switch variant.winCondition {
        case .survival: return limit
        case .elimination: return startingScore
        case .fixedRounds: return roundCount
        }
    }

    /// The number this Match is played at, as it reads beside the Variant's
    /// label — `to 101`, `from 21`, `12 rounds`. `nil` when there is no number
    /// to name it by.
    ///
    /// Here rather than on each screen because Home and Play name the same
    /// Match and must name it identically, and because the phrasing depends on
    /// the Win Condition, which is the Match's business to know and not a
    /// card's.
    var numberPhrase: String? {
        guard let variant, let number = variantNumber else { return nil }
        return VariantParameter.Kind(variant.winCondition).phrase(for: number)
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
    /// Whether this Match has been deleted — either deleted and not yet
    /// written out, or written out and gone.
    ///
    /// Two checks, because SwiftData answers the question differently on
    /// either side of the save. `isDeleted` is true from the moment the Match
    /// is deleted until the context is saved, and false afterwards; what marks
    /// it from then on is that it belonged to a store and no longer belongs to
    /// a context. A deletion here is saved the moment it is made, so the
    /// second half is the one that nearly always answers.
    ///
    /// Both halves of that second check are needed. A Match built and never
    /// inserted — a fixture, a Setup screen's Match before it is added — has
    /// no context either, and is perfectly readable; what it does not have is
    /// a store to have been removed from, which is what `storeIdentifier`
    /// says.
    ///
    /// Worth asking before reading anything else off a Match that was handed
    /// over rather than just built: a deleted Match has no backing data left,
    /// and every stored property traps rather than answering — `id` as much as
    /// any other, so this goes first in a predicate, not second. It is not, on
    /// its own, the defence — a screen that reads its Matches once and holds
    /// values needs no such check (`HomeCard`) — but Home's list is handed
    /// Matches by `@Query`, which can still name one for the redraw that
    /// follows the deletion.
    var isGone: Bool {
        if isDeleted { return true }
        return persistentModelID.storeIdentifier != nil && modelContext == nil
    }
}

extension Sequence<Match> {
    /// The Matches this build can score, each with its Variant already
    /// resolved.
    ///
    /// Two ways a Match can fail to be scorable, and the same answer to both:
    /// it names a Variant id that resolves to nothing, or it carries no number
    /// to be played at. Either is skipped rather than shown, and never
    /// deleted: its data stays exactly where it is, so a downgrade or a bad
    /// write is recoverable by the build that knows the id rather than
    /// terminal (`docs/adr/0007`).
    ///
    /// Skipping is a gate, not a guarantee the domain enforces. An Engine
    /// handed a Match with no number has nothing to score it by and says
    /// nothing at all about it — an empty Standings, not a wrong one — so what
    /// keeps a player from meeting that blank screen is that such a Match is
    /// filtered out here, before any screen can open it. The route into Play
    /// does not come through here: it names one Match by id, and gates on
    /// `scorableMatch` instead.
    var scorable: [(match: Match, variant: Variant)] {
        compactMap { match in
            guard let variant = match.variant, match.variantNumber != nil else { return nil }
            return (match: match, variant: variant)
        }
    }

    /// The Match a route names, if this build can score it.
    ///
    /// Home's list is not the only way into Play: a route names a Match by id,
    /// and that id is resolved here rather than against every stored Match, so
    /// the ways it can stop being scorable — the Match was deleted, its
    /// Variant id resolves to nothing, or it carries no number to be played at
    /// — all come back as `nil` rather than as a Match with no rules to score
    /// it by.
    ///
    /// One id, so one Variant resolved: `scorable` would resolve every Match's
    /// Variant to build a list this throws away.
    ///
    /// `isGone` is asked first, before the id it is guarding: reading `id`
    /// off a Match that has been deleted is itself a read of a stored
    /// property, and a deleted Match answers those by trapping. This walks
    /// whatever `@Query` last handed over, which can still name a Match that
    /// has gone.
    func scorableMatch(_ id: Match.ID?) -> Match? {
        guard let id,
              let match = first(where: { !$0.isGone && $0.id == id }),
              // One question covers both: a number resolves only through a
              // Variant, so an unknown id is already `nil` here.
              match.variantNumber != nil
        else {
            return nil
        }
        return match
    }
}

extension Match {
    /// Starts a Match under `variant`, recording its id and the number its Win
    /// Condition is played at. The Variant itself is not stored — `variant`
    /// resolves it afresh on every read — so this is a starting point rather
    /// than a copy.
    ///
    /// The number is recorded even when it is the value Setup preselected, so
    /// that every Match says what it was played at, and nothing downstream has
    /// to tell "the table chose this" from "nobody was asked".
    ///
    /// `number` is the number chosen for this Match at Setup, in whichever
    /// shape the Variant's Win Condition takes it, and is required: there is
    /// nothing left to fall back to. The Variants carry no numbers, and a
    /// Match without one is skipped at the `scorable` gate rather than scored.
    /// A caller nobody was asked for — a fixture, a test — states the number
    /// it means, rather than inheriting a constant a later release could move
    /// underneath it (`docs/adr/0007`).
    convenience init(
        id: UUID = UUID(),
        game: Game,
        variant: Variant,
        number: Int,
        mode: EntrantMode,
        entrants: [Entrant],
        rounds: [Round] = [],
        archived: Bool = false,
        createdAt: Date = Date()
    ) {
        // Matched rather than compared: this initializer is nonisolated, and
        // `WinCondition`'s synthesized `==` is not.
        let limit: Int?
        let startingScore: Int?
        let roundCount: Int?
        switch variant.winCondition {
        case .survival:
            (limit, startingScore, roundCount) = (number, nil, nil)
        case .elimination:
            (limit, startingScore, roundCount) = (nil, number, nil)
        case .fixedRounds:
            (limit, startingScore, roundCount) = (nil, nil, number)
        }

        self.init(
            id: id,
            game: game,
            variantId: variant.id,
            limit: limit,
            startingScore: startingScore,
            roundCount: roundCount,
            mode: mode,
            entrants: entrants,
            rounds: rounds,
            archived: archived,
            createdAt: createdAt
        )
    }
}
