import Foundation

// Debug-only, so that "first launch is empty" is a property of the shipped
// binary rather than a habit. These live in the app target because `#Preview`
// can only reach what the app target holds; `#if DEBUG` is what stops that
// necessity from also putting two strangers' Matches in a release build.
#if DEBUG

/// Fixtures for previews and view tests.
///
/// These Matches were once what the app itself opened with; now that Matches
/// are stored on the device, a first launch shows an empty Home and everything
/// on it is the player's own. Alice and Bob live here instead, where a preview
/// or a snapshot can draw a populated Home without a player ever meeting them.
///
/// They keep their fixed 2026 dates: Home titles each card with its Match's
/// date and orders the list by it, so a fixture built at "now" would make every
/// snapshot differ from the day it was recorded.
extension MatchStore {
    /// A store holding the two fixture Matches, one of them Archived.
    static func seeded() -> MatchStore {
        let store = MatchStore()

        // Each Match builds its own Alice. An Entrant belongs to exactly one
        // Match (`docs/adr/0007`), so handing the same one to both would move
        // her out of the first rather than have her play in two.
        let alice = Entrant(name: "Alice")
        let bob = Entrant(name: "Bob")

        store.add(Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [alice, bob],
            rounds: [Round(deltas: [alice.id: 20, bob.id: 15])],
            createdAt: .fixture(year: 2026, month: 3, day: 14, hour: 21)
        ))

        let aliceAgain = Entrant(name: "Alice")
        let carol = Entrant(name: "Carol")

        store.add(Match(
            game: .gonga,
            variant: .gongaStandard,
            number: 101,
            mode: .players,
            entrants: [aliceAgain, carol],
            rounds: [Round(deltas: [aliceAgain.id: 110, carol.id: 40])],
            archived: true,
            createdAt: .fixture(year: 2026, month: 2, day: 2, hour: 19, minute: 45)
        ))

        return store
    }
}

extension Date {
    /// A fixed calendar date and time, for preview and test Matches that must
    /// look the same on every run. Built in the current time zone so the
    /// rendered clock time is the one asked for wherever the tests run.
    static func fixture(year: Int, month: Int, day: Int, hour: Int = 12, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = .current
        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }
}

#endif
