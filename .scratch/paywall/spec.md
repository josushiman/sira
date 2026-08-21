Status: ready-for-agent

# The paywall — three free games, then one payment

## Problem Statement

Sıra has never asked anyone for anything. It has also never been shipped: there is no Developer Program membership behind it, no listing, and no way for the work to pay for the account it needs to exist on the App Store.

The intent is not to build a business. It is to cover the $99 a year the app costs to keep on the store, and to ship a real purchase flow rather than an imagined one. Nothing about the app scales with users — every Match is on the player's own device, there is no server, no account and no per-user cost — so the money is a fixed floor to clear, not a margin to maximise. Roughly two dozen buyers a year clears it.

That framing decides the shape of everything below. A paywall built to maximise conversion would be the wrong artefact here, and a punitive one would be actively self-defeating: only one phone at a table keeps score, so the app has one install per group of players to win, and a gate that annoys the scorekeeper costs the whole table.

The failure this spec exists to prevent is specific. Four people are around a table, the phone is out, the tally is half-written, and Sıra refuses to record the next Round. That is not a lost sale. That is someone reaching for a pen and never opening the app again.

## Solution

The first three Matches a player scores are free. After that, a one-off purchase — £2.99 at the UK tier, shown in each player's own currency — removes the limit for good.

The limit is drawn around *starting* a Match, never around continuing one. A Match with a Round on it is a Match in progress, and Sıra will keep scoring it forever regardless of what the meter says, whether it was started before or after the limit was reached. Nothing the player has already written down is ever held hostage, hidden, or made unreadable — not by the meter, and not by a purchase that is later refunded.

Making that guarantee absolute takes one change beyond the paywall itself: Home lists only Matches that have actually been scored. A Match set up and abandoned before its first Round never reaches Home and is discarded, so there is no way to stockpile un-scored Matches and no second place the limit has to be enforced. Scoring a Round is never blocked, by anything. The limit is asked about once, at Home, before the player has invested a thing.

The limit is visible before it is reached. Three small dots beside Home's "Your games" heading fill as the free Matches are used, so the wall is something the player watched approaching rather than something that ambushed them. Once the purchase is made the dots disappear entirely, along with every other trace of the paywall: a player who has paid should be unable to tell the app ever had one.

At the wall, tapping Gonga or Okey raises a half-height sheet over a dimmed Home — the app's existing bottom-sheet idiom, the same surface the Rejoin offer and the delete confirmation already use. It states what has happened, what £2.99 buys, and offers three things: buy, restore, and dismiss. Dismissing costs one tap and never leaves Home.

The purchase is a StoreKit 2 non-consumable with Family Sharing enabled, verified on the device with no server anywhere. Once a device has seen a verified purchase it stays unlocked forever, offline included. The app never treats StoreKit's silence as a refusal.

## User Stories

1. As a player, I want to score three complete Matches without paying anything, so that I can find out whether Sıra replaces my paper sheet before I decide about it.
2. As a player, I want the three free Matches to be full Matches with no features missing, so that what I am evaluating is the real app.
3. As a player, I want every Variant — Gonga 101, Gonga 151, Okey 21, Okey 101 — available in the free Matches, so that I can try the one my table actually plays.
4. As a player, I want team play available in the free Matches, so that an Okey 21 table is not excluded from the trial.
5. As a player, I want Çifte, Okey atmak, Gösterge, Rejoin, Undo, the Scoresheet and Standings all available in the free Matches, so that nothing I would rely on is hidden behind the purchase.
6. As a player, I want to see how many free Matches I have left before I run out, so that the limit is something I saw coming.
7. As a first-time player, I want the free-Match indicator to be understandable the first time I see it, so that it is information rather than decoration.
8. As a player, I want the free-Match indicator to be small and quiet, so that the app looks like a score tracker rather than a trial.
9. As a player, I want a Match to count against my free three only once a Round has been scored on it, so that a mis-tap at Setup costs me nothing.
10. As a player, I want to abandon a Match I set up by mistake without it costing me anything, so that exploring Setup is free.
11. As a player, I want Home to list only games I have actually scored, so that my history is a record of games rather than of intentions.
12. As a player, I want a Match I set up and abandoned before scoring it to disappear on its own, so that I never have to tidy up after a mis-tap.
13. As a player, I want scoring a Round never to be refused for any reason, so that the app is unconditionally reliable once a game is under way.
14. As a player, I want a Match to stay on Home after I undo its only Round, so that correcting a mistake does not make the game vanish.
15. As a player, I want a Match I have started scoring to stay scorable forever, so that reaching the limit can never strand a game in progress.
16. As a player, I want to keep adding Rounds to an in-progress Match after my free three are used up, so that the evening finishes.
17. As a player, I want Undo to keep working on an in-progress Match after the limit is reached, so that a mistake is still correctable.
18. As a player, I want to accept or decline a Rejoin on an in-progress Match after the limit is reached, so that Survival Matches resolve properly.
19. As a player, I want to read the Scoresheet and Standings of every Match I have ever scored, whether or not I have paid, so that my history is mine.
20. As a player, I want to archive and delete Matches whether or not I have paid, so that tidying my history is not a paid feature.
21. As a player, I want deleting a Match not to give me a free Match back, so that the app is not asking me to destroy my own history to save money.
22. As a player, I want undoing a Round not to give me a free Match back, so that Undo stays a scoring tool rather than a way to game the meter.
23. As a player, I want to be offered the purchase at the moment I try to start a fourth Match, so that the ask arrives when it is relevant.
24. As a player, I want the offer to appear over Home rather than replacing it, so that I can see where I am and what I was doing.
25. As a player, I want to dismiss the offer in one tap and stay exactly where I was, so that declining is cheap.
26. As a player, I want to be able to raise the offer again after dismissing it, so that changing my mind is easy.
27. As a player, I want the offer to tell me plainly that it is one payment and not a subscription, so that I know what I am agreeing to.
28. As a player, I want the offer to make no claims about features it does not actually unlock, so that I am not misled into buying.
29. As a player, I want to see the price in my own currency, so that the number means something to me.
30. As a player outside the UK, I want the layout to hold when my currency's price string is longer, so that the button is not broken for me.
31. As a player, I want the purchase to go through Apple's own payment sheet, so that Sıra never sees my card details.
32. As a player, I want the app to tell me clearly if a purchase did not complete, so that I am not left wondering whether I was charged.
33. As a player, I want to know that a failed purchase took no money, so that I can retry without worrying.
34. As a player, I want to be able to cancel the payment sheet and land back where I was, so that backing out is safe.
35. As a player, I want the app to stay usable while a purchase is in flight, so that a slow network does not feel like a crash.
36. As a player, I want the limit to lift the instant the purchase completes, so that I can start the Match I was trying to start.
37. As a paying player, I want every sign of the paywall to disappear after I buy, so that the app stops selling to me.
38. As a paying player, I want the app to keep working with no network at all, so that a table in a basement or on a plane is still scored.
39. As a paying player, I want the app never to re-lock because it could not reach Apple, so that a bad connection cannot cost me the app I paid for.
40. As a paying player, I want my purchase to work on my other iPhone and iPad, so that one payment covers me.
41. As a player in a Family Sharing group, I want a family member's purchase to unlock the app for me, so that a household pays once.
42. As a player, I want a Restore option on the offer sheet, so that I can recover a purchase made on another device.
43. As a player, I want Restore to tell me plainly when there is no purchase to find, so that I am not left staring at a screen that did nothing.
44. As a player, I want Restore to be a control I can actually see and hit, so that recovering my purchase is not a hunt.
45. As a player who reinstalls the app, I want my purchase to come back without my having to do anything, so that reinstalling is not a punishment.
46. As a player whose purchase is refunded, I want to keep every Match I have already scored, so that a refund costs me the limit and not my history.
47. As a player removed from a Family Sharing group, I want the app to return to the free tier without losing any of my data, so that losing access is not losing records.
48. As a player, I want the App Store listing to state the three-free-Matches limit before I download, so that "free" is not a surprise.
49. As a player using the app in light mode, I want the offer sheet and the indicator to be as legible as they are in dark mode, so that my system setting does not degrade the app.
50. As a player using large text, I want the offer sheet to remain readable and operable, so that the purchase is not gated on my eyesight.
51. As a player, I want a save failure while my free-Match count changes to be surfaced the way every other save failure is, so that the app never quietly disagrees with itself about what I have used.

## Implementation Decisions

### The three seams

Three seams, one of them new.

**`MatchStore`, extended.** The free-Match meter is durable state that changes on exactly one event, so it lives where every other durable mutation already lives. `MatchStore` documents itself as the one place a Match is created, changed or removed, and the one place durability can be reasoned about; a meter with its own store and its own save path would make that false. The increment rides the same save as the Round that caused it, so the two can never diverge, and a save that fails surfaces through the existing `SaveFailure` path unchanged.

**`UnlockStore`, new.** Everything about the purchase: the product, buying it, restoring it, and the current entitlement. StoreKit cannot be exercised in tests, so its operations are injected — the same technique `MatchStore` already uses for `saveContext`, and for the same stated reason. Production wires StoreKit 2; tests inject fakes.

**The views.** Snapshot tests per ADR 0004, following `HomeViewSnapshotTests`.

Above these, the UI asks exactly one question and gets one of three answers — unlocked, free with some number remaining, or locked. `HomeView` and the offer sheet read only that. Neither touches StoreKit, and neither counts Matches.

### Started, and what it decides

A Match becomes **Started** the first time a Round is scored on it. Started is permanent: undoing that Round does not un-Start it, and nothing else reverses it. It is a flag on the Match rather than something inferred from the Round count, which is what makes it idempotent — undoing the only Round and scoring another does not Start the Match a second time.

Started is named for scoring, not for the paywall, and this matters. Two separate things read it, and only one of them is about money:

- **Home lists Started Matches only.** A Match that has never been scored is not a game, it is an intention, and Home has no business listing it as history.
- **A Match consumes one of the three free Matches when it Starts.** The meter counts Started Matches.

If the flag were named for the meter, changing or removing the paywall later would drag Home's list along with it. The paywall *uses* Started; it does not define it.

The global count is a separate monotonic integer, incremented as a Match Starts. It is separate precisely because a Match can be deleted and the count must not go with it — deleting history to earn free Matches is not a bargain the app offers. Nothing anywhere decrements it.

### Home lists Started Matches

Home's card list is filtered to Started Matches. The route into Play is not: it already resolves through the unfiltered query, for the reason `HomeView` already documents — Home's filter is a view of Home's list rather than a statement about what can be scored, which is why archiving the Match being played does not close it. An un-Started Match is the same shape of thing, so Setup can hand Play a Match that Home does not yet list.

Two consequences follow, both of them improvements independent of the paywall. A mis-tapped Setup no longer leaves an empty Match sitting on Home to be deleted by hand — it simply never appears. And Home stops showing rows with no scores on them.

An un-Started Match that is left behind — backed out of, or lost to iOS reclaiming the app — is unreachable, because Home is the only way back to a Match. These are deleted at launch. There is nothing to preserve: a Match with no Rounds has no tally, only a Variant choice and some Entrant names.

### Where the limit is checked

In one place: **starting a Match from Home.** With no free Matches left and no purchase, tapping Gonga or Okey raises the offer instead of opening the Variant picker.

There is no second check, and there does not need to be one. Because Home lists only Started Matches, a player can never accumulate un-Started Matches to score later — there is no way to navigate back to one. The only un-Started Match that can exist is the one being played right now, and reaching it required passing the check at Home. Scoring a Round is therefore never blocked, by anything, ever.

The check does not happen at Setup, and does not happen at Start. Letting a player choose a Variant, name four Entrants and then refusing them is the version of this feature that reads as bait, and it is deliberately not built.

### The purchase

A StoreKit 2 non-consumable, one product, Family Sharing enabled. No third-party purchase SDK: there are no subscriptions, no renewals, no cross-platform entitlements and no server, which is the entire problem such an SDK exists to solve. Adding a network dependency to an app that is otherwise wholly offline would cost the app a property worth more than the convenience.

Verification is StoreKit 2's own on-device check of Apple's signature. There is no receipt endpoint and nothing to run.

The price string is always the one StoreKit returns for the player's storefront. `£2.99` never appears in the app's own code or copy.

Family Sharing is on because Sıra is played by households and the revenue it appears to cost is largely imaginary — the alternative to a shared purchase is not five more sales, it is one phone doing the scoring and nobody else installing the app at all. Its one real consequence is that entitlements can be revoked when someone leaves a family group, which the next section handles.

### Silence is not a refusal

The rule that governs every entitlement check:

- StoreKit returns **nothing** — offline, a cache that has never synced on this device, or the known family-sharing regressions — and the app **stays unlocked** if it has ever seen a verified purchase.
- StoreKit returns a transaction that is **explicitly revoked or refunded** and the app **re-locks**, returning to the meter.

The asymmetry is deliberate and the cost of getting it backwards is not symmetrical. Wrongly staying unlocked costs at most one £2.99 that someone has already paid on another device. Wrongly locking hits a paying customer mid-evening, which is the exact failure this whole design is built around avoiding.

Once a verified transaction has been seen, a flag is written locally alongside the meter. It is a cache of a truth Apple owns, not a source of truth, and the code that declares it should say so — the next reader will be tempted to treat it as authoritative.

Re-locking after a revocation changes what the player can start. It never touches a Match, a Round, an Entrant, or the readability of any of them.

### A reinstall resets the meter, on purpose

The meter lives in the app's SwiftData store and goes when the app goes. The entitlement does not: StoreKit restores a non-consumable automatically for the same Apple ID, so a reinstalling player who has paid is simply unlocked again, usually without touching anything.

A reinstalling player who has *not* paid gets three fresh Matches. This is a choice, not an oversight. Persisting a trial counter in the Keychain so it survives deletion is the kind of thing players notice and resent, and anyone willing to reinstall the app to avoid £2.99 was never going to pay it.

### The offer sheet

The app's existing bottom-sheet idiom — `DecisionSheet` and `SheetButton`, the components the Rejoin offer and the delete confirmation already compose. Presented over a dimmed Home, which stays visible behind it.

It carries: what has happened, three accurate benefit lines, the localised price, a primary buy action, a dismiss, and Restore. Restore is a real control with a legible weight and a full-size hit target — it is the app's only Restore affordance, and the App Store requires it to be findable. Restore is never called at launch, because it prompts for an Apple ID password.

Its states are: default, purchase in flight (with the app's own controls disabled — Apple draws the payment sheet itself), purchase failed, and Restore found nothing. The last two are inline messages on the sheet, not dialogs; the sheet stays open so the player can simply try again.

### The meter on Home

Three dots beside the "Your games" heading, filling as Matches are consumed, gone entirely once unlocked. They need a treatment that reads as "free games left" on first sight without becoming chrome — bare dots do not explain themselves, and a panel large enough to explain itself is too large. This is a design problem, resolved in the Claude Design project rather than invented in code.

They are not called pips or dots in code: `pip` is already the playing-card pip colour and `dots` is already the Entrant badge palette. The free-Match meter is its own thing with its own name.

### Themes

Both, from tokens, never from hex. The trap is specific: `accent` is gold in Felt and dark green in Paper, with `onAccent` flipping to match, so a design that leans on the gold does not survive being recoloured into Paper. Every text-on-background pair on the sheet clears WCAG AA in both.

### Vocabulary

`CONTEXT.md` gains four entries, defined against the existing ones:

- **Started** — a Match that has had at least one Round scored on it. Permanent: Undo does not reverse it. Home lists Started Matches; an un-Started Match is not history yet, and is discarded rather than kept. Defined against **Archived**, which hides a Started Match, and **Delete**, which removes one. _Avoid_: "created", which no longer distinguishes anything Home acts on; "in progress", which is about whether a Match has finished.
- **Free Match** — one of the three Matches that can be Started before the Unlock is required. Consumed when a Match Starts; never returned. _Avoid_: "trial", "credit".
- **Unlock** — the one-off purchase removing the Free Match limit. Tied to an Apple ID, shared through Family Sharing, and permanent unless Apple revokes it.
- **Locked** — the state in which the Free Matches are used up and no Unlock is held. Blocks *starting* a Match only; every existing Match stays fully scorable and readable. _Avoid_: using "locked" for an Archived Match, or for an Entrant who is Out.

User-facing copy says "games", never "Matches" — the glossary already records that Home calls them "Your games".

### ADRs to record

- **StoreKit 2 directly, no purchase SDK** — with the offline-only property as the stated consequence.
- **The Unlock fails open** — silence is not a refusal; explicit revocation is. With the asymmetry of costs as the reasoning.

## Testing Decisions

A good test here asserts what a player would notice: how many Matches they can start, whether the one in front of them still scores, what the sheet says. It does not assert that a particular property was written, or that a method was called. The existing suite is the model — `MatchStorePersistenceTests` proves a Match survives by opening a second store over the same file, not by inspecting a context.

**`MatchStore` — Started and the meter.** The first Round scored on a Match Starts it and consumes one Free Match; a second Round on the same Match consumes nothing; undoing the only Round leaves it Started and consumes nothing further when the next Round is scored; deleting a Started Match leaves the count where it was; archiving changes nothing. The count survives a relaunch, proved the way persistence already proves things — a second store over the same file. A fresh store starts at three, which is the reinstall case. A save that fails while the meter increments surfaces through `SaveFailure` and the change stands in memory, following `test_aDeletionThatCannotBeSavedIsSurfacedAndStillStands`.

**Home's list.** An un-Started Match does not appear on Home; a Started one does; a Started Match whose only Round has been undone stays on Home, which is the case that would break if the filter tested the Round count instead of the flag. Un-Started Matches left in the store are gone after a relaunch. Prior art is `MatchFilterTests`, which already covers Home's list being a view rather than the whole store.

**The route into Play.** Setup can open a Match that Home does not list — the check that proves hiding un-Started Matches did not break the flow the app is actually used through. `NavigatorTests` is the model.

**`UnlockStore` — the purchase.** Driven entirely through injected fakes, since none of it can touch the App Store. A successful purchase unlocks; a cancellation leaves the player exactly as they were; a failure surfaces a message and leaves them locked; an explicitly revoked transaction re-locks; **StoreKit returning nothing leaves a previously-unlocked player unlocked** — the single most important test in the spec, and the one that pins down the fail-open argument; a restore that finds nothing reports that rather than failing silently; a purchase arriving through the updates stream, as a Family Sharing purchase does, unlocks without the player having bought anything in this session.

**The derived value.** Unlocked regardless of the meter; free with the right remainder for zero, one and two Matches consumed; locked at three. This is the only thing the views read, so it is worth asserting directly.

**Views — snapshots, both themes, per ADR 0004.** Home with the meter at each state and with the meter absent because the player has paid; the sheet in its default, in-flight, failed and nothing-to-restore states. Prior art is `HomeViewSnapshotTests` and `RejoinSheetSnapshotTests`, the latter being the closer model since the sheet composes the same `DecisionSheet`.

**Copy.** The sheet's wording is asserted, as `DeleteMatchSheet.explanation(for:)` already is — specifically that no benefit line claims to unlock a Variant, team play or any other feature, and that the price shown is the one StoreKit supplied rather than a literal.

**Not tested.** Apple's payment sheet, real sandbox purchases, and real Family Sharing revocation. These are checked by hand against Xcode's `.storekit` configuration and a sandbox tester before release, and the checklist belongs on the release ticket rather than in the suite.

## Out of Scope

- Any Settings screen. Restore lives on the offer sheet, which satisfies the requirement without adding a screen holding one item.
- Subscriptions, tiers, consumables, or any second product.
- iCloud or CloudKit sync of the meter or the entitlement. Storage stays local, as the persistence spec settled.
- Turkish localisation and Turkish-storefront pricing. Turkey is a deliberate later launch behind localisation; nothing here should make per-storefront pricing harder, and nothing here should attempt it.
- Analytics, conversion tracking, experiments, or any measurement of the paywall.
- Promotional offers, introductory pricing, promo codes, refund handling in-app, and App Store promoted purchases.
- Raising or lowering the price after launch, which is an App Store Connect operation and not a code change.
- The App Store listing copy, screenshots and metadata. Required before submission, tracked on the release ticket.

## Further Notes

**Why three and not ten.** Ten was the starting proposal and it is calibrated to nothing. A table playing on Sundays reaches ten in three months, by which point they have long since stopped thinking about the app as new and the ask never arrives while intent is high. A tournament weekend burns ten in two days. Three is enough to prove a scorekeeper — a scorekeeper proves itself in one evening — and it arrives while the player still remembers deciding to try it.

**Why £2.99 and not £4.99.** Not a cost calculation; cost does not constrain this. At the UK tier and the Small Business Program's 15% rate, £2.99 returns roughly £2.10 after VAT and commission, clearing the $99 a year at around forty buyers, and £4.99 clears it at around twenty-three. Both are achievable. £4.99 is the price of an app with reviews and a reputation, and this one will launch with neither. The price can be raised later once there are ratings; dropping it is the move that annoys the people who already paid.

**A known, accepted rough edge.** A player who has already paid, installing on a new device, is normally unlocked automatically because StoreKit resolves the entitlement for their Apple ID at launch. If that does not happen — a different Apple ID, a sync that has not run — they will not see a Restore control until they have used their three free Matches and reached the sheet. Adding a Settings screen to fix this is not worth a screen holding one item; if a second thing ever needs settling, Restore moves there too.

**What hiding un-Started Matches costs.** Three things, all accepted deliberately.

A Match can no longer be set up in advance and returned to later — back out to Home before scoring the first Round and it is gone. Setup is quick and nothing about the app suggests preparing a table ahead of time, but it is a behaviour a player could notice.

An un-Started Match lost to iOS reclaiming the app takes its Entrant names with it. No tally is at risk, because none exists yet, so this does not weaken the promise the persistence spec makes — that promise is about Rounds.

And the persistence spec's user story 8, *"I want the Home list to show exactly the Matches I created"*, is no longer true as written; "created" now means Started. That spec is shipped and its story list is a record of what was built, so it is not rewritten — this spec supersedes it on that one point, and the glossary's new **Started** entry is where the distinction is recorded for good.

**Two things to check on a device, not in the simulator.** Whether a purchase started from a sheet presented over Home survives the payment sheet's presentation, and whether a Family Sharing purchase arriving through the updates stream lifts the limit while Home is on screen. Both are presentation-timing questions of the kind that has already bitten this project once, when a sheet raised from a context menu turned out to need a real device to trust.
