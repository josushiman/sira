# 01 — The Match owns the number it is played at

**What to build:** Nothing a player can see. This is the prefactor that makes every ticket after it small: it moves the number a Match is scored against out of the Variant constants and onto the Match, and routes every read of that number through one accessor.

Two things happen together. First, the four places that each invent their own fallback today stop doing so — `SurvivalEngine` resolving the limit as `?? .max` (which means an Entrant can never go Out), `PlayView` resolving it as `?? 0` for its bars and Room left rows, and `PlayStats` resolving the limit as `?? 0` for Closest to out and the Round count as `?? 0` for Rounds left. All of them ask the Match instead.

Second, `Match` gains three named optionals — a limit, a starting score and a Round count — mirroring the Variant fields they supply, joining the Round count that already exists for exactly this purpose. Setup always populates the one its Variant's Win Condition calls for, taking the value from the Variant constant, so a stored number and a constant agree everywhere and no behaviour moves. This is the expand half of expand–contract: both sources exist, the accessor prefers the stored one, and ticket 06 removes the constants once nothing reads them.

Three named optionals rather than one generic number, because a generic field would be meaningless-but-present on the two Variants it does not describe, and `Match.variant` already resolves a Setup choice this way.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] `Match` carries a limit, a starting score and a Round count, at most one of them non-`nil` for any Match, determined by its Variant's Win Condition
- [x] One accessor on `Match` resolves the number, preferring the stored value and falling back to the Variant constant while both exist
- [x] `SurvivalEngine` reads the accessor — the `?? .max` fallback is gone
- [x] `PlayView` reads the accessor for both its limit and its bar scale — both `?? 0` fallbacks are gone
- [x] `PlayStats` reads the accessor for Room left, Closest to out and Rounds left — both `?? 0` fallbacks are gone
- [x] Setup records the number for every Match it starts, including Variants that did not previously store one
- [x] `MatchTests` covers resolution for each of the three kinds, and that a Match with neither a stored number nor a constant resolves `nil`
- [x] No snapshot is re-recorded — nothing rendered has changed. A snapshot that moves means this ticket changed behaviour it should not have
- [x] Full suite green with no test expectation changed
