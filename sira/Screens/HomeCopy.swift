import Foundation

/// The two lines on Home that describe the catalogue rather than any one Match:
/// the hero line under the title, and the subtitle on each Game card.
///
/// Counted off `Game.allCases` and `Variant.all(for:)` rather than written out,
/// because written out is how both went wrong: the hero line claimed three
/// Variants while there were four, and the cards advertised "101 / 151" and
/// "21 / 101" — four Variants, two of which no longer exist and one of which
/// was renamed for quoting a number it no longer guarantees. Copy that names
/// the catalogue goes stale on the next change to it; copy that counts it
/// cannot.
///
/// Here rather than in `HomeView`'s body so the counting is driven by tests
/// directly, the way `HomeCard` is, instead of only through a snapshot.
enum HomeCopy {
    /// The line under Home's hero title.
    static var heroLine: String {
        let games = Game.allCases.count
        let variants = Game.allCases.reduce(0) { $0 + Variant.all(for: $1).count }
        return "\(spelledOut(games).capitalizedFirst) \(games == 1 ? "game" : "games"), "
            + "\(spelledOut(variants)) \(variants == 1 ? "variant" : "variants"), "
            + "one running tally that nobody can argue with."
    }

    /// A Game card's subtitle: how many Variants tapping it leads to. A count
    /// rather than their labels — "Gonga" under a card titled Gonga says
    /// nothing, and a Game's labels are what Setup and the Picker are for.
    static func gameSubtitle(for game: Game) -> String {
        let count = Variant.all(for: game).count
        return "\(count) \(count == 1 ? "variant" : "variants")"
    }

    /// Small counts as words, which is how the hero line reads them. Digits
    /// for anything past the range a two-game catalogue can reach — a fallback
    /// that should never render, and reads as a plain number if it ever does.
    private static func spelledOut(_ count: Int) -> String {
        let words = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
        return words.indices.contains(count) ? words[count] : "\(count)"
    }
}

private extension String {
    var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
