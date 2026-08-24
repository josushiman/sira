# 05 — Okey's starting score is chosen at Setup

**What to build:** An Okey table that wants a shorter or longer countdown can set it. The chips read `21 · Custom` with 21 preselected, and Custom reveals a numeric field. Choose 31 and both teams start at 31 and count down to 0.

21 stays a chip rather than becoming a bare prefilled field, so the standard game stays something the player *chooses* rather than a default they failed to change.

Changing the length changes nothing else about the game. The losing team still takes **−2** each Round, each Gösterge find still deducts **1**, and **0** remains the finish line — "first team to reach 0 loses" still describes what happens. A start of 7 is a very short Match, not a differently-shaped one. Range 2–99.

Home reads `2 teams · from 21`, and Play's header carries the same phrase. The Gap tile is unaffected by the starting score.

**Blocked by:** 02, 04.

**Status:** done

- [x] Okey's Setup offers `21 · Custom` with 21 preselected
- [x] A starting score of 2–99 starts a Match; anything outside disables Start with a visible reason and leaves the entered value untouched
- [x] Both teams begin at the chosen score and the Match ends when a team reaches 0
- [x] The losing team takes −2 per Round and each Gösterge find deducts 1, unchanged at any starting score
- [x] Çifte and Okey atmak behave exactly as they do today, including their stacking
- [x] Okey still seats exactly 2 teams
- [x] Setup's rule blurb reads back the chosen starting score
- [x] Home's card and Play's header show `from 21` in the metadata line
- [x] `EliminationEngineTests` covers a custom starting score counting down to 0, with −2 and Gösterge unscaled by it
- [x] `PlayStatsTests` covers the Gap tile being unaffected by the starting score
- [x] Affected snapshot suites re-recorded per ADR 0004, in this ticket
