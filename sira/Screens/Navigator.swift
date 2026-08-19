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

    /// Leaves whatever is open and lands on Home.
    func goHome() {
        pickingVariantsFor = nil
        openMatchID = nil
    }
}
