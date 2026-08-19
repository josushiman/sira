# 09 — Add the Gonga 151 variant

**What to build:** Gonga is meant to offer two Survival variants — Gonga 101 and Gonga 151 — but `Variant.all(for:)` only returns `.gonga101` today (ticket 01 hardcoded 101 and 151 was never picked back up). Add a `Variant.gonga151` alongside the existing `Variant.gonga101` and list both on the Gonga Variant picker.

**Blocked by:** None.

**Status:** needs-triage

- [ ] Confirm Gonga 151's rules with the user before implementing: same Survival mechanics as 101 (accumulate points, Out on crossing the limit, last one standing wins) but with a limit of 151 — or does anything else about the ruleset differ at 151 (Çifte, Rejoin target, round-scoring)?
- [ ] Add `Variant.gonga151` in `sira/Domain/Variant.swift` with `limit: 151` and rule text matching the confirmed rules
- [ ] `Variant.all(for: .gonga)` returns both `.gonga101` and `.gonga151`, in that order, so the Variant picker lists both
- [ ] Snapshot tests for the Gonga Variant picker cover both variants shown together (existing single-variant snapshots will need updating)

## Comments

Reported by the user while triaging a batch of UI bugs (2026-08-19): "GONGA is meant to have two variants: GONGA 101 and GONGA 151. It's only got one variant." Filed for later work rather than implemented now, since the exact 151 ruleset needs confirming first.
