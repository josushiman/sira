import Foundation
import SwiftData

/// An Entrant returning to a Survival Match at a given total, recorded against
/// the Round that put them Out so that undoing that Round undoes the Rejoin
/// with it.
///
/// Stored inline on its Round rather than as a relationship of its own: per
/// `docs/adr/0005` the Engines read a whole Round and derive from it, and
/// nothing queries into Rejoins, so a relationship would buy query power that
/// is never used (`docs/adr/0006`).
struct RejoinEvent: Codable, Hashable {
    let id: Entrant.ID
    let to: Int
}

/// An Entrant taking a free seat partway through a Match, recorded against the
/// Round they arrived at so that undoing that Round undoes the arrival with it.
///
/// Deliberately not a `RejoinEvent`, though the two carry the same two fields
/// and land on a total the same way. A Rejoin returns an Entrant the Match has
/// been scoring all along; a Join is the first Round an Entrant is scored at,
/// and the Rounds before it are ones they were not at the table for. Only the
/// Join answers "from when", and that is the whole question the Standings ask
/// of it — folding them into one type would leave the Engine unable to tell an
/// Entrant seated at Setup from one who arrived at Round 3.
struct JoinEvent: Codable, Hashable {
    let id: Entrant.ID
    /// The total the Entrant starts on, agreed at the table before they sit.
    let to: Int
}

@Model
final class Round {
    /// The identity a Scoresheet row is keyed on, and the one `undoLastRound`
    /// matches against. Our own UUID rather than `persistentModelID` so it
    /// means the same thing before a Round is stored as after.
    var id: UUID
    /// Where this Round sits in its Match, assigned by the Match when the
    /// Round is added and never renumbered afterwards. Order is carried here
    /// rather than by position in `Match.rounds` because position is not a
    /// guarantee a store can make: Rounds loaded from the database arrive in
    /// whatever order the framework pleases, and every cumulative total in the
    /// app depends on getting it right.
    ///
    /// Only the last Round is ever removed (Undo), so removal frees the
    /// highest sequence and the next Round added takes it again.
    ///
    /// Sequences are unique within a Match — `addRound` always takes one past
    /// the highest in use — so sorting by this is a total order and needs no
    /// tie-break. It is deliberately absent from `init`: a Round has no
    /// opinion about where it sits, so only a Match can stamp one, via
    /// `addRound` or `withSequence(_:)`.
    private(set) var sequence = 0
    /// Per-Entrant deltas for the keypad entry styles (Survival, Fixed Rounds),
    /// stored **raw** — exactly the counts the player entered, never scaled by
    /// Çifte, Okey atmak or any other Round modifier. The Engines are the only
    /// place a multiplier is applied (`docs/adr/0005`). Unused by Elimination
    /// Rounds, which are described instead by `losingEntrantID` and
    /// `gostergeFinderID`.
    ///
    /// Keyed by `Entrant.ID`, which SwiftData gives no referential integrity —
    /// a removed Entrant would orphan these keys. Safe only because Entrants
    /// cannot be removed from a Match (`docs/adr/0006`).
    var deltas: [Entrant.ID: Int]
    var rejoins: [RejoinEvent]
    /// The Entrants who joined the Match at this Round, taking a free seat
    /// partway through. Empty for every Round of a Match whose roster was
    /// settled at Setup, which is every Match until one is added to.
    ///
    /// Stored inline on the Round for the same reason `rejoins` is, and on the
    /// Round rather than on the Entrant so that Undo — which removes only the
    /// last Round — reverses an arrival exactly as it reverses a score.
    var joins: [JoinEvent] = []
    /// The Entrants who called Çifte this Round. A fact, not an instruction:
    /// what it does to each Entrant's delta is derived in `multipliers(for:)`,
    /// because the rule resolves on who won the Round.
    var cifteCallers: Set<Entrant.ID>
    /// The Entrant who finished this Round by discarding the joker — the Okey
    /// atan — or `nil` if nobody did. At most one per Round.
    var okeyAtanID: Entrant.ID?
    /// Elimination only: the Entrant that lost this Round, taking the −2 penalty.
    var losingEntrantID: Entrant.ID?
    /// Elimination only: the Entrant that found the Gösterge this Round, or
    /// `nil` if nobody did. There is one Gösterge per Round, so at most one
    /// Entrant can find it.
    var gostergeFinderID: Entrant.ID?
    /// The Match that owns this Round. The inverse of `Match.storedRounds`,
    /// declared there.
    ///
    /// Settable only from this file, for the same reason `sequence` is: a Round
    /// moved to another Match would arrive carrying a sequence stamped by its
    /// old one, colliding with the sequences already in use there and
    /// bypassing `addRound`, which is the only thing entitled to say where a
    /// Round sits.
    private(set) var match: Match?

    init(
        id: UUID = UUID(),
        deltas: [Entrant.ID: Int] = [:],
        rejoins: [RejoinEvent] = [],
        joins: [JoinEvent] = [],
        cifteCallers: Set<Entrant.ID> = [],
        okeyAtanID: Entrant.ID? = nil,
        losingEntrantID: Entrant.ID? = nil,
        gostergeFinderID: Entrant.ID? = nil
    ) {
        self.id = id
        self.deltas = deltas
        self.rejoins = rejoins
        self.joins = joins
        self.cifteCallers = cifteCallers
        self.okeyAtanID = okeyAtanID
        self.losingEntrantID = losingEntrantID
        self.gostergeFinderID = gostergeFinderID
    }
}

extension Round {
    /// Stamps this Round as sitting at `sequence` in its Match and returns it.
    /// The only way to set a sequence other than by adding the Round to a
    /// Match, so a caller reconstituting stored Rounds has to say so
    /// explicitly.
    ///
    /// A Round is a reference type, so this stamps **in place** and hands back
    /// the same object rather than a restamped copy.
    @discardableResult
    func withSequence(_ sequence: Int) -> Round {
        self.sequence = sequence
        return self
    }

    /// This Round's multiplier per Entrant — the one derivation all three
    /// Engines share, so Çifte and Okey atmak can't drift apart between Win
    /// Conditions (`docs/adr/0005`).
    ///
    /// Base ×1. Çifte contributes ×2 to an Entrant if *any* caller's rule
    /// reaches them — a caller who lost the Round doubles themselves, a caller
    /// who won doubles everyone *else* — and contributes ×2 at most, however
    /// many people called. Okey atmak contributes a uniform ×2 to everyone.
    /// The two contributions multiply, so ×4 is the ceiling for one Entrant.
    ///
    /// What each Engine scales with the result is its own business: Survival
    /// and Fixed Rounds scale every delta, Elimination scales only the loss
    /// penalty and never a Gösterge find. The Match comes in whole because
    /// "won the Round" is read differently per Win Condition — which the
    /// calling Engine states, rather than it being re-derived from the Match.
    func multipliers(in match: Match, winCondition: WinCondition) -> [Entrant.ID: Int] {
        let entrantIDs = match.entrants.map(\.id)
        switch winCondition {
        case .elimination:
            // Okey records the team that lost; the other one won.
            return multipliers(for: entrantIDs) { $0 != losingEntrantID }
        case .survival, .fixedRounds:
            return keypadMultipliers(for: entrantIDs)
        }
    }

    /// The same derivation as the keypad Variants' Engines read it: winning
    /// the Round is an entered 0 or being the Okey atan, and nothing entered
    /// is not a win — that Entrant takes no score this Round either, so no
    /// multiplier of theirs is ever applied.
    ///
    /// Exposed so the entry screen's live preview can share this body rather
    /// than restate the rules: what a row shows before saving is then the same
    /// arithmetic the Engine performs after, by construction.
    func keypadMultipliers(for entrantIDs: [Entrant.ID]) -> [Entrant.ID: Int] {
        multipliers(for: entrantIDs) { id in
            // Okey atmak *is* winning the Round, so the atan counts as having
            // won whatever value ends up recorded against them — otherwise a
            // stray digit typed after the marker went on would quietly turn
            // them into a loser and flip every Çifte caller's effect.
            if id == okeyAtanID { return true }
            guard let delta = deltas[id] else { return false }
            return delta == 0
        }
    }

    /// - Parameter wonRound: Whether an Entrant won this Round, which only the
    ///   Win Condition can answer — it's read from an entered 0 in the keypad
    ///   Variants and from the recorded loser in Okey.
    private func multipliers(
        for entrantIDs: [Entrant.ID],
        wonRound: (Entrant.ID) -> Bool
    ) -> [Entrant.ID: Int] {
        let okeyAtmakMultiplier = okeyAtanID == nil ? 1 : 2
        var result: [Entrant.ID: Int] = [:]
        for id in entrantIDs {
            let doubledByCifte = cifteCallers.contains { caller in
                wonRound(caller) ? caller != id : caller == id
            }
            result[id] = (doubledByCifte ? 2 : 1) * okeyAtmakMultiplier
        }
        return result
    }
}
