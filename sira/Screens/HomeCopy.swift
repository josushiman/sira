/// The supporting line on Home's hero and the subtitle on each Game card.
///
/// Here rather than in `HomeView`'s body so the copy can be tested directly,
/// the way `HomeCard` is, instead of only through a snapshot.
enum HomeCopy {
    /// The line under Home's hero title.
    static let heroLine = "Track every round in one place — no pen and paper needed."

    /// A Game card's subtitle: how many Variants tapping it leads to. A count
    /// rather than their labels — "Gonga" under a card titled Gonga says
    /// nothing, and a Game's labels are what Setup and the Picker are for.
    static func gameSubtitle(for game: Game) -> String {
        let count = Variant.all(for: game).count
        return "\(count) \(count == 1 ? "variant" : "variants")"
    }
}
