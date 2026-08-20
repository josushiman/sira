@testable import sira

extension Match {
    /// The same Match, holding the same Rounds, arranged so that storage order
    /// is the *opposite* of played order — the arrangement that breaks anything
    /// still reading Round order by array position.
    ///
    /// Every Round is carried over whole, sequences included: only where they
    /// sit in the array changes, which is exactly the thing that is supposed to
    /// carry no meaning.
    func withRoundsStoredOutOfOrder() -> Match {
        Match(
            id: id,
            game: game,
            variantId: variantId,
            roundCount: roundCount,
            mode: mode,
            entrants: entrants,
            storedRounds: rounds.reversed(),
            archived: archived,
            createdAt: createdAt
        )
    }
}
