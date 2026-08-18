# 07 — Rejoin bottom-sheet restyle

**What to build:** A player whose Entrant just went Out sees the Rejoin offer as a rounded-top bottom sheet with a drag handle and slide-up feel, matching the prototype, instead of the current plain `.medium`-detent sheet.

**Blocked by:** 01 — Design-system foundation + Home reskin.

**Status:** ready-for-agent

- [ ] The Rejoin prompt continues to use `.sheet(item:)`, restyled with rounded top corners, a drag handle, and a transition matching the prototype's slide-up feel.
- [ ] Sheet copy and button styling ("Rejoin at N" / "They're out") match the prototype.
- [ ] Accepting or declining Rejoin produces the same result as today — no change to `SurvivalEngine` rejoin-target logic.
- [ ] Snapshot tests exist for the Rejoin sheet in both Paper and Felt.
