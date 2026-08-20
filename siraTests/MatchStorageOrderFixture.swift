@testable import sira

extension Match {
    /// A copy of this Match, holding copies of the same Entrants and Rounds,
    /// arranged so that storage order is the *opposite* of seated and played
    /// order — the arrangement that breaks anything still reading order by
    /// array position.
    ///
    /// Every Entrant and Round is copied whole, id and sequence included: only
    /// where it sits in the array changes, which is exactly the thing that is
    /// supposed to carry no meaning.
    ///
    /// Copies rather than the originals because Entrants and Rounds are owned
    /// by their Match: handing the same objects to a second Match would move
    /// them out of this one, and every caller here goes on to compare the two
    /// Matches against each other.
    func withEntrantsAndRoundsStoredOutOfOrder() -> Match {
        Match(
            id: id,
            game: game,
            variantId: variantId,
            roundCount: roundCount,
            mode: mode,
            storedEntrants: entrants.reversed().map { entrant in
                Entrant(id: entrant.id, name: entrant.name).withSequence(entrant.sequence)
            },
            storedRounds: rounds.reversed().map { round in
                Round(
                    id: round.id,
                    deltas: round.deltas,
                    rejoins: round.rejoins,
                    cifteCallers: round.cifteCallers,
                    okeyAtanID: round.okeyAtanID,
                    losingEntrantID: round.losingEntrantID,
                    gostergeFinderID: round.gostergeFinderID
                ).withSequence(round.sequence)
            },
            archived: archived,
            createdAt: createdAt
        )
    }
}
