# 02 — Display strings out of the Domain layer

**What to build:** Domain types stop describing an English UI and go back to describing the game. `PlayStats` says *which* statistic is interesting rather than what to call it; `MatchSummary` hands over a leader and a total rather than a finished English sentence; `MatchFilter` stops using display text as its identity; `Variant` stops carrying screen copy.

Nothing changes on screen. English output is byte-identical, so this reviews as a pure refactor. It lands before the String Catalog exists so that keys are never migrated twice — doing it afterwards means re-keying every string these types feed.

**Blocked by:** None — can start immediately. This is a prefactor and involves no Turkish, so it does not wait on the glossary.

**Status:** ready-for-agent

- [ ] `PlayStats` no longer exposes pre-rendered English. Its secondary statistic becomes a semantic case carrying its own number — room-left, rounds-left, or gap — and its lead state distinguishes an in-progress leader from a final result, rather than choosing between the literal strings "Leader" and "Result". The view layer maps these to text.
- [ ] `MatchSummary` no longer concatenates its leader sentence. It exposes the leader and the total as separate values so the view can render them through a format string with positional arguments, letting a language with different word order reorder them. Its no-Entrants case becomes a semantic state rather than the literal string "No Entrants".
- [ ] `MatchFilter`'s `String` raw value becomes a stable, non-display identifier. The view layer supplies the Active / All / Archived labels. Its `includes(_:)` filtering behaviour is unchanged.
- [ ] `Variant` drops `label` and `ruleText`. The view layer derives both from the Variant's identity. `Variant` keeps everything that describes the ruleset — win condition, limit, starting score, round count, entrant mode, max entrants, Çifte support, entry style, never-laid-down value.
- [ ] Every screen that consumed these strings renders identically to before, character for character, in English.
- [ ] `PlayStatsTests`, `MatchSummaryTests`, `MatchFilterTests` and `VariantTests` are reshaped in place to assert semantic values rather than English strings — a room-left case carrying its number, rather than the label "Room left" beside the value "59". No new test file is created; this is the same seam with stronger assertions.
- [ ] Existing snapshots are unchanged and still pass, confirming the refactor is invisible.
- [ ] No engine logic is touched. `SurvivalEngine`, `EliminationEngine`, `FixedRoundsEngine` and their tests are untouched.
