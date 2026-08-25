import Foundation
import SwiftData

/// Whether this device has ever seen a verified Unlock.
///
/// **A cache of a truth Apple owns, not a source of truth.** The entitlement
/// belongs to an Apple Account and Apple can revoke it; this row only
/// remembers what StoreKit last said, so that a launch with no network — or a
/// StoreKit cache that has never synced on this device — does not read as a
/// refusal. Nothing in the app may treat it as permission it granted itself:
/// it is written only from a verified transaction, and cleared only by an
/// explicitly revoked one (`docs/adr/0011`).
///
/// Stored beside the tally the meter is read from, in the same database and
/// through the same store, so that the two halves of `GameAccess` are durable
/// in one place and one way. Not the Keychain: this is a cache, and a cache
/// that outlives the app it caches for is how a reinstall goes wrong rather
/// than right.
///
/// There is one row, created on first use. `MatchStore` is the only thing that
/// reads or writes it, for the same reason it is the only thing that reads the
/// tally — SwiftData has no notion of a singleton, so the discipline is the
/// store's.
@Model
final class UnlockCache {
    /// What StoreKit last told this device. Written through
    /// `MatchStore.recordUnlock(seen:)`, never directly.
    var hasSeenVerifiedUnlock: Bool

    init(hasSeenVerifiedUnlock: Bool = false) {
        self.hasSeenVerifiedUnlock = hasSeenVerifiedUnlock
    }
}
