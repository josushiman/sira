import XCTest
@testable import sira

final class MatchStoreTests: XCTestCase {
    func test_addAppendsTheMatch() {
        let store = MatchStore()
        let match = Match(game: .gonga, variant: .gonga101, mode: .players, entrants: [Entrant(name: "Alice")])

        store.add(match)

        XCTAssertEqual(store.matches, [match])
    }

    func test_bindingSetWritesBackIntoTheStoresMatches() {
        let a = Entrant(name: "Alice")
        var match = Match(game: .gonga, variant: .gonga101, mode: .players, entrants: [a])
        let store = MatchStore(matches: [match])

        let binding = store.binding(for: match.id)
        let round = Round(deltas: [a.id: 10])
        match.rounds.append(round)
        binding.wrappedValue = match

        XCTAssertEqual(store.matches.first?.rounds, [round])
    }
}
