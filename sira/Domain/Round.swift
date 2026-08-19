import Foundation

struct RejoinEvent: Hashable {
    let id: Entrant.ID
    let to: Int
}

struct Round: Identifiable, Hashable {
    let id: UUID
    /// Per-Entrant deltas for the keypad entry styles (Survival, Fixed Rounds),
    /// stored **raw** — exactly the counts the player entered, never scaled by
    /// Çifte, Okey atmak or any other Round modifier. The Engines are the only
    /// place a multiplier is applied (`docs/adr/0005`). Unused by Elimination
    /// Rounds, which are described instead by `losingEntrantID` and
    /// `gostergeFinds`.
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
    /// Elimination only: Gösterge finds per Entrant this Round, capped at 1 each.
    var gostergeFinds: [Entrant.ID: Int]

    init(
        id: UUID = UUID(),
        deltas: [Entrant.ID: Int] = [:],
        rejoins: [RejoinEvent] = [],
        cifteCallers: Set<Entrant.ID> = [],
        okeyAtanID: Entrant.ID? = nil,
        losingEntrantID: Entrant.ID? = nil,
        gostergeFinds: [Entrant.ID: Int] = [:]
    ) {
        self.id = id
        self.deltas = deltas
        self.rejoins = rejoins
        self.cifteCallers = cifteCallers
        self.okeyAtanID = okeyAtanID
        self.losingEntrantID = losingEntrantID
        self.gostergeFinds = gostergeFinds
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
    /// "won the Round" is read differently per Win Condition — see `wonRound`.
    func multipliers(in match: Match) -> [Entrant.ID: Int] {
        let okeyAtmakMultiplier = okeyAtanID == nil ? 1 : 2
        var result: [Entrant.ID: Int] = [:]
        for entrant in match.entrants {
            let doubledByCifte = cifteCallers.contains { caller in
                wonRound(caller, in: match) ? caller != entrant.id : caller == entrant.id
            }
            result[entrant.id] = (doubledByCifte ? 2 : 1) * okeyAtmakMultiplier
        }
        return result
    }

    /// Whether `id` won this Round, in the sense Çifte's asymmetry needs it.
    /// Which fact answers that is the Win Condition's to say, not something to
    /// infer from whichever of the Round's fields happen to be populated.
    private func wonRound(_ id: Entrant.ID, in match: Match) -> Bool {
        switch match.variant.winCondition {
        case .elimination:
            // Okey 21 records the team that lost; the other one won.
            return id != losingEntrantID
        case .survival, .fixedRounds:
            // The keypad Variants record winning as an entered 0. Nothing
            // entered is not a win — that Entrant takes no score this Round
            // either, so no multiplier of theirs is ever applied.
            guard let delta = deltas[id] else { return false }
            return delta == 0
        }
    }
}
