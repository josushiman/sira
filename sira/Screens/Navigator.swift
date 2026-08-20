import SwiftUI

/// What Home has pushed. Every screen in the app sits under Home, reached
/// through one of these two: a Game (→ Variant picker → Setup → Play) or a
/// Match (→ Play). Holding both here rather than in `HomeView`'s own `@State`
/// is what makes returning to Home possible from anywhere below it — clearing
/// them pops the stack however deep it got, which `dismiss()` can't do, since
/// it only ever steps back one screen.
///
/// Injected at the root alongside `MatchStore`, so pushed screens can read it.
@Observable
final class Navigator {
    var pickingVariantsFor: Game?
    var openMatchID: Match.ID?

    /// Drops the route to `id` if that is the Match currently open, landing
    /// the player back on Home. Two things can make a route name a Match that
    /// cannot be presented — it was deleted, or its Variant id resolves to
    /// nothing this build can score — and the app can never present either.
    /// The reason doesn't change the remedy, so both come here.
    ///
    /// Only that route is cleared, not everything pushed: `goHome()` would
    /// also throw away a Variant choice being made above Home, which some
    /// other Match becoming unpresentable has no business undoing.
    func closeMatch(_ id: Match.ID) {
        guard openMatchID == id else { return }
        openMatchID = nil
    }

    /// Leaves whatever is open and lands on Home.
    func goHome() {
        pickingVariantsFor = nil
        openMatchID = nil
    }
}
