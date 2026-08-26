# 07 — The entitlement check waits on the price

**Type:** task

**Status:** ready-for-agent

**What's wrong:** `UnlockStore.prepare()` awaits `operations.displayPrice()` and only then calls `refreshEntitlements()`. The first is `Product.products(for:)` — a network round trip; the second reads StoreKit's local entitlement cache and can usually answer at once.

So on a device where `hasSeenUnlock` is `false` — a reinstall, or a new phone — a player who has already paid is Locked for the whole duration of that products request. A slow network or a timing-out storefront means they are looking at the paywall, with the wall up, for as long as it takes. Nothing about the entitlement needed the price.

**Found by:** `/code-review high` on `feature/paywall-01-started`, 2026-08-26.

**What to do**

- [ ] The price and the entitlements are fetched concurrently — `async let`, or two child tasks — so that neither waits on the other
- [ ] The entitlement answer is applied as soon as it arrives, whatever the price is doing
- [ ] The fail-open rule is untouched: a price that never arrives still leaves a previously-unlocked device unlocked, and an entitlement answer that never arrives is still silence rather than a refusal
- [ ] Covered by a test where the price fetch is slow and the entitlement answer is immediate, asserting the device is unlocked without waiting on the price

**Note:** this is a latency bug on the one screen that asks for money, not a correctness one. Everything ends up in the right state eventually; the complaint is about how long a paying player is shown a wall they have already bought their way past.
