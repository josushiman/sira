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
    // Setup scores are read through `variantNumber`. The obsolete Round
    // target remains stored for migration compatibility but has no live meaning.
    /// The score limit this Match is played to, for a Survival Match. `nil`
    /// on any other Win Condition, which is not played to a limit at all.
    var limit: Int?
    /// The score this Match's Entrants count down from, for an Elimination
    /// Match. `nil` on any other Win Condition.
    var startingScore: Int?
    /// V1's obsolete Round target, retained only for migration compatibility.
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
    /// The persisted Okey 101 ending, independent of archive visibility and
    /// whether this Match has Started. V2 captures old count-based results
    /// here before the target-free lifecycle replaces that rule.
    var ended: Bool = false
    /// Whether a Round has ever been scored on this Match — see **Started** in
    /// `CONTEXT.md`. Home lists Started Matches only: a Match nobody has
    /// scored is an intention rather than history.
    ///
    /// A flag rather than a reading of `rounds.isEmpty`, and the difference is
    /// the whole point. Undoing the only Round leaves the Match Started, so a
    /// player correcting a mistake does not watch their game disappear from
    /// Home — and scoring the next Round does not Start it a second time,
    /// which is what lets anything counting Starts count them once.
    ///
    /// Write it through `start()`, never directly: Starting is permanent, and
    /// nothing in the app has cause to un-Start a Match.
    ///
    /// The default is here for the migration rather than for any caller — the
    /// initializer sets this from the Rounds regardless. A non-optional
    /// attribute added without one cannot be lightweight-migrated, which would
    /// turn opening an existing store into the `fatalError` in `forApp()`
    /// (`SiraSchema`, and `Entrant.arrivedMidMatch` before it). `false` is the
    /// wrong answer for a Match already carrying Rounds, and
    /// `MatchStore.discardUnstartedMatches()` is what corrects it at launch.
    var started: Bool = false
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
        // A Match handed its Rounds all at once has been scored just as surely
        // as one that took them one at a time, so it is Started here rather
        // than left to the caller to say — the same reconciliation the
        // arrivals below get, and for the same reason: every way of building a
        // Match says the same thing about the same facts.
        //
        // Not a parameter. Starting is what scoring does, and there is no
        // caller with standing to claim a Match with no Rounds was scored, or
        // that one with Rounds was not.
        self.started = !storedRounds.isEmpty
        // An Entrant some Round says arrived is one who arrived, reconciled
        // here — in the designated initializer, so that every way of building
        // a Match says the same thing about the same roster rather than each
        // caller having to remember to.
        //
        // Only ever additive: `arrivingMidMatch()` is one-way, so a caller
        // handing over an Entrant already marked keeps the mark even where no
        // Round carries their JoinEvent any more. That case is real — undoing
        // the Round an arrival sits on leaves exactly it — and it is why the
        // Rounds are read as a second source for this fact rather than as the
        // only one (`Entrant.arrivedMidMatch`).
        let arrivals = Set(storedRounds.flatMap(\.joins).map(\.id))
        for entrant in storedEntrants where arrivals.contains(entrant.id) {
            entrant.arrivingMidMatch()
        }
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

    /// The Entrant this Match holds under `id`, or `nil` where it holds none.
    ///
    /// Everything downstream of the Engines is keyed on `Entrant.ID` — a
    /// Standing, a Round's deltas, a Çifte caller — so getting from one of
    /// those back to the Entrant it names is a question asked often enough to
    /// be the Match's to answer rather than each caller's to walk.
    func entrant(_ id: Entrant.ID) -> Entrant? {
        storedEntrants.first { $0.id == id }
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
        guard !isReadOnly else { return }
        storedRounds.append(round.withSequence(nextSequence))
        // Scoring a Round is what Starts a Match, so it happens here rather
        // than at whichever screen happened to enter the Round. Whether this
        // was the Round that did it is `start()`'s answer, and nothing at this
        // level has a use for it — adding a Round is the same act either way.
        _ = start()
    }

    /// Records that this Match has been scored, and answers whether that was
    /// news — `true` the once, `false` every time after.
    ///
    /// The answer is what a caller counting Starts reads. Returning it from
    /// here rather than leaving each caller to check the flag first and set it
    /// second is what keeps "has this Match Started before?" and "it has now"
    /// from drifting apart.
    ///
    /// One-way: there is no `unstart()`. Undo removes the Round, never the
    /// fact that the Match was played.
    func start() -> Bool {
        guard !started else { return false }
        started = true
        return true
    }

    /// Attaches `rejoin` to the latest Round, so undoing that Round undoes the
    /// Rejoin with it. A no-op with no Rounds, which the Rejoin flow can't
    /// reach — it is only offered in response to a Round just added.
    func recordRejoin(_ rejoin: RejoinEvent) {
        guard !isReadOnly else { return }
        rounds.last?.rejoins.append(rejoin)
    }

    /// The seat the next Entrant to sit down takes. One past the highest in
    /// use rather than the count of Entrants, for the same reason
    /// `nextSequence` is: a seat decides a dot-badge colour, and two Entrants
    /// sharing one would share a colour.
    ///
    /// Unlike a Round's sequence, this is never freed and reused. Undoing the
    /// Round a join sits on takes the arrival with it but leaves the Entrant
    /// seated, so the seat stays spoken for.
    var nextSeat: Int {
        (storedEntrants.map(\.sequence).max() ?? -1) + 1
    }

    /// Seats `entrant` at the next free seat, entering on `total`, and records
    /// the arrival against the latest Round — so Undo reverses a mistaken add
    /// exactly as it reverses a mistaken score.
    ///
    /// With no Rounds there is nothing to attach the arrival to, and nothing
    /// worth attaching: an Entrant who has missed no Rounds is an Entrant
    /// seated at Setup, which is what the absence of a JoinEvent already
    /// means. That is the same rule arriving at the same place rather than a
    /// second one — with no Rounds played, the highest total still in *is*
    /// zero, so `total` is zero and there is no jump to record.
    ///
    /// No existing seat moves: this appends, and `withSequence` is the only
    /// thing that stamps one.
    func addEntrant(_ entrant: Entrant, joiningOn total: Int) {
        guard !isReadOnly else { return }
        storedEntrants.append(entrant.withSequence(nextSeat))
        guard let latest = rounds.last else { return }
        // Both halves, and in this order: the Entrant records *that* they
        // arrived, which no Undo takes back, and the Round records *where*,
        // which Undo takes back with the Round. Together they say an Entrant
        // whose arrival has been undone is in no Round of this Match at all —
        // which is the orphan, rather than a player on zero who was never
        // agreed to.
        entrant.arrivingMidMatch()
        latest.joins.append(JoinEvent(id: entrant.id, to: total))
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

    /// The required Setup score: Survival's limit or Elimination's starting
    /// score. Lowest Total has no parameter, even on a migrated Match that
    /// still carries an obsolete target. Missing required scores are never
    /// replaced by a substitute (`docs/adr/0007`).
    var variantNumber: Int? {
        guard let variant else { return nil }
        switch variant.winCondition {
        case .survival: return limit
        case .elimination: return startingScore
        case .lowestTotal: return nil
        }
    }

    /// A resolved Variant and every parameter its rules require. Lowest Total
    /// needs no number; the other Win Conditions still require theirs.
    var isScorable: Bool {
        guard let variant else { return false }
        return variant.parameterKind == nil || variantNumber != nil
    }

    /// The number this Match is played at, as it reads beside the Variant's
    /// label — `to 101` or `from 21`. `nil` when there is no number
    /// to name it by.
    ///
    /// Here rather than on each screen because Home and Play name the same
    /// Match and must name it identically, and because the phrasing depends on
    /// the Win Condition, which is the Match's business to know and not a
    /// card's.
    var numberPhrase: String? {
        guard let variant, let number = variantNumber else { return nil }
        return variant.parameterKind?.phrase(for: number)
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
        guard !isReadOnly else { return nil }
        guard let latest = rounds.last else { return nil }
        storedRounds.removeAll { $0.id == latest.id }
        return latest
    }

    /// Captures V1 count-based completion during migration only. Ordinary
    /// scoring never infers an ending from this obsolete target.
    func prepareCountBasedEnding() {
        // Frozen identity rather than the live Win Condition: the migration
        // must still recognize V1 results after Okey 101 changes its rules.
        guard game == .okey, variantId == "okey-101" else { return }
        ended = roundCount.map { storedRounds.count >= $0 } ?? false
    }

    /// Only an explicitly Ended Okey 101 result is locked for review. Other
    /// Variants keep their existing automatic-ending mutation behavior.
    var isReadOnly: Bool { variant?.winCondition == .lowestTotal && ended }

    /// Manual ending is available only after a currently scored Round.
    var canEnd: Bool {
        variant?.winCondition == .lowestTotal && !ended && !storedRounds.isEmpty
    }

    var prospectiveEndResult: LowestTotalResult? {
        guard canEnd else { return nil }
        return LowestTotalResult(ranked: LowestTotalEngine().standings(for: self).ranked)
    }

    /// Declares the current result and hides it from Active in one mutation.
    @discardableResult
    func end() -> Bool {
        guard canEnd else { return false }
        ended = true
        archived = true
        return true
    }

    /// Reopens the declared result and returns this same Match to Active.
    /// An ordinary live archive is restored separately, without changing play.
    @discardableResult
    func resume() -> Bool {
        guard isReadOnly else { return false }
        ended = false
        archived = false
        return true
    }

    /// Hides this Match from the Active filter without locking it — Rounds can
    /// still be added and standings still recompute normally.
    func archive() {
        archived = true
    }

    /// Returns an archived Match to the Active filter.
    func restore() {
        guard !isReadOnly else { return }
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
    /// Unresolved Variants and missing required parameters are skipped,
    /// never deleted (`docs/adr/0007`). Lowest Total needs no parameter.
    var scorable: [(match: Match, variant: Variant)] {
        compactMap { match in
            guard let variant = match.variant, match.isScorable else { return nil }
            return (match: match, variant: variant)
        }
    }

    /// The Match a route names, if this build can score it.
    ///
    /// Home's list is not the only way into Play: a route names a Match by id,
    /// and that id is resolved here rather than against every stored Match, so
    /// the ways it can stop being scorable — the Match was deleted, its
    /// Variant id resolves to nothing, or it lacks a required Setup score
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
              match.isScorable
        else {
            return nil
        }
        return match
    }
}

extension Match {
    /// Creates a Match under `variant`, storing its frozen identity and any
    /// required Setup score. Lowest Total always starts without a parameter.
    /// Missing Gonga/Okey scores remain unscorable rather than gaining defaults.
    convenience init(
        id: UUID = UUID(),
        game: Game,
        variant: Variant,
        number: Int? = nil,
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
        case .lowestTotal:
            (limit, startingScore, roundCount) = (nil, nil, nil)
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
