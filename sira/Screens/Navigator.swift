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
    /// the player back on Home. Deletion is the one thing that can make a
    /// route name a Match that no longer exists, and the app can never present
    /// one that doesn't.
    ///
    /// Only that route is cleared, not everything pushed: `goHome()` would
    /// also throw away a Variant choice being made above Home, which the
    /// deletion of some other Match has no business undoing.
    func closeDeletedMatch(_ id: Match.ID) {
        guard openMatchID == id else { return }
        openMatchID = nil
    }

    /// Leaves whatever is open and lands on Home.
    func goHome() {
        pickingVariantsFor = nil
        openMatchID = nil
    }
}
