import Foundation

/// How many of the three Free Matches are left — see **Free Match** in
/// `CONTEXT.md`.
///
/// A value read off the stored tally rather than a second place the tally
/// lives: `started` is the count of Matches that have ever Started on this
/// device, and everything else here is arithmetic on it. That keeps the
/// allowance a property of this type rather than a number each caller
/// remembers, and keeps the wall — ticket 03 — reading the same `isExhausted`
/// the meter draws.
///
/// `startedMatches` is deliberately not clamped on the way in. It is the tally
/// as stored, and a tally past the allowance is an ordinary state for a player
/// who has Unlocked and kept playing; clamping happens in `used`, which is the
/// only place a number past three would draw wrongly.
struct FreeMatches: Equatable {
    /// How many Matches may be Started before the Unlock is required.
    static let allowance = 3

    /// Matches that have ever Started on this device, Unlocked ones included.
    ///
    /// Spelled out rather than left as a bare `started`, which would read as
    /// something these Free Matches are: **Started** is a predicate on a Match
    /// (`CONTEXT.md`), and this is a count of the Matches it is true of.
    let startedMatches: Int

    /// How many of the allowance have been consumed, as the meter fills it:
    /// never more than there are marks to fill.
    var used: Int { min(max(startedMatches, 0), Self.allowance) }

    /// How many Free Matches are left. Never negative — a player past the
    /// allowance has none left rather than fewer than none.
    var remaining: Int { Self.allowance - used }

    /// Whether the Free Matches are used up. What ticket 03's wall asks;
    /// nothing here decides what to do about it.
    var isExhausted: Bool { remaining == 0 }
}
