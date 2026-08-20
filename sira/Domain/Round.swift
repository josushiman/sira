import Foundation

struct RejoinEvent: Hashable {
    let id: Entrant.ID
    let to: Int
}

struct Round: Identifiable, Hashable {
    let id: UUID
    /// Where this Round sits in its Match, assigned by the Match when the
    /// Round is added and never renumbered afterwards. Order is carried here
    /// rather than by position in `Match.rounds` because position is not a
    /// guarantee a store can make: once Rounds are loaded from a database the
    /// array arrives in whatever order the framework pleases, and every
    /// cumulative total in the app depends on getting it right.
    ///
    /// Only the last Round is ever removed (Undo), so removal frees the
    /// highest sequence and the next Round added takes it again.
    var sequence: Int
    /// Per-Entrant deltas for the keypad entry styles (Survival, Fixed Rounds),
    /// stored **raw** — exactly the counts the player entered, never scaled by
    /// Çifte, Okey atmak or any other Round modifier. The Engines are the only
    /// place a multiplier is applied (`docs/adr/0005`). Unused by Elimination
    /// Rounds, which are described instead by `losingEntrantID` and
    /// `gostergeFinderID`.
    var deltas: [Entrant.ID: Int]
    var rejoins: [RejoinEvent]
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

    init(
        id: UUID = UUID(),
        sequence: Int = 0,
        deltas: [Entrant.ID: Int] = [:],
        rejoins: [RejoinEvent] = [],
        cifteCallers: Set<Entrant.ID> = [],
        okeyAtanID: Entrant.ID? = nil,
        losingEntrantID: Entrant.ID? = nil,
        gostergeFinderID: Entrant.ID? = nil
    ) {
        self.id = id
        self.sequence = sequence
        self.deltas = deltas
        self.rejoins = rejoins
        self.cifteCallers = cifteCallers
        self.okeyAtanID = okeyAtanID
        self.losingEntrantID = losingEntrantID
        self.gostergeFinderID = gostergeFinderID
    }
}

extension Round {
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
            // Okey 21 records the team that lost; the other one won.
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
    ///   Variants and from the recorded loser in Okey 21.
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
