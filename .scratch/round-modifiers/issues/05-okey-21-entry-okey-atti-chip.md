# 05 — Okey 21 Round entry: the Okey attı chip

**What to build:** `OkeyStandardRoundEntryView` gains an `Okey attı` chip alongside its existing Çifte toggle. Both are Round-level here, not per-Entrant.

**Blocked by:** 03 — Okey atmak across all three Engines

**Status:** ready-for-agent

Either modifier alone produces −4, so the two chips are indistinguishable in the score. Both are still shown, because they are different events and the history should record which one happened.

- [ ] An `Okey attı` chip sits next to the Çifte toggle, matching its styling
- [ ] The chip records the **winning** team as the Okey atan — the joker finish is a win, and the screen already knows who won
- [ ] The Çifte toggle stays a plain Round-level switch here; Okey 21 does not need to record who called
- [ ] Both chips can be on at once, producing −8
- [ ] The screen's copy makes the consequence legible rather than leaving the player to infer −4 or −8
- [ ] The screen's state stays in the view — **no `RoundEntryState`-style struct is extracted**; its logic is a loser pick, a 0–1 clamp and two flags, already covered by the snapshot and Engine seams
- [ ] `OkeyStandardRoundEntryViewSnapshotTests` gain cases in both themes covering the new chip on and both chips on
