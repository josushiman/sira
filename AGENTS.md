## Agent skills

### Issue tracker

Issues live as local markdown files under `.scratch/<feature-slug>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Git workflow

Trunk-based, Xcode-friendly: the repo root stays on `main` permanently. Human edits commit straight to `main`; agent work goes in a `git worktree` on a short-lived `feature/`/`fix/`/`chore/` branch, then PR + squash merge. Tag releases on `main`. See `docs/agents/gitflow.md`.

### Domain docs

Single-context layout — `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
