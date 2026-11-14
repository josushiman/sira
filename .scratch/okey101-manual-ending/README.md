# Okey 101 manual ending

Implementation is in progress: tickets 01–02 are verified complete; tickets 03–05 remain ready-for-agent. Authoritative status and completion evidence live in each ticket. The [feature spec](spec.md) remains the parent contract; this handoff does not change it.

| Ticket | Deliverable | Blocked by |
| --- | --- | --- |
| [01 — Preserve existing Match results through migration](issues/01-preserve-results-through-migration.md) | V2 compatibility and retained saved outcomes | None |
| [02 — Start and score target-free Okey 101 Matches](issues/02-start-and-score-target-free-matches.md) | Picker → Setup → open-ended scoring and target-free metadata | 01 |
| [03 — End, archive and review an Okey 101 Match](issues/03-end-archive-and-review-a-match.md) | Both Play tabs → confirmation → archived, read-only result | 02 |
| [04 — Resume from Play or Home](issues/04-resume-from-play-or-home.md) | Explicit Resume → live scoring/corrections → re-end | 03 |
| [05 — Keep long Scoresheets readable and responsive](issues/05-keep-long-scoresheets-usable.md) | Usable, correct histories beyond 100 Rounds | 02 |

Tickets 03 and 05 are unblocked; their published order selects 03 next. Ticket 04 follows 03. Follow the repository's worktree and PR workflow when implementation is requested.

Each ticket carries behavior-oriented acceptance criteria and relevant approved screenshots. [Open the saved interactive flow](mockups/flow.html) or use the [mockup guide](mockups/README.md). Assets are stored with the tickets, so handoffs do not rely on another agent's access to the original chat's visualization directory.
