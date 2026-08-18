# Git workflow

Lightweight trunk-based flow. No `develop` branch, no long-lived release branches.

## Conventions

- `main` is always deployable/stable.
- Every change gets a short-lived branch off `main`, prefixed by type: `feature/<slug>`, `fix/<slug>`, `chore/<slug>`.
- Open a PR into `main` for every change, even solo work — it gives a review checkpoint and a record of why.
- Merge PRs with **squash merge** so `main` stays one commit per change.
- Delete the branch after merge.
- After merging, run `git pull` on your local `main` checkout before rebuilding in Xcode — a stale local `main` is the most common reason a merged change doesn't show up in the simulator.
- Tag releases directly on `main` (`v0.1.0`, `v0.2.0`, ...). No separate release branches.

## Hotfixes

Only needed when a shipped release needs an urgent fix while `main` has since moved on.

- Branch from the release tag: `hotfix/<slug>`.
- Fix, tag a patch release (e.g. `v0.1.1`), merge the fix back into `main`.

## When an agent is asked to make a change

- Create the branch (`feature/`, `fix/`, or `chore/` as appropriate) before editing.
- Open the PR into `main` rather than merging directly, unless told otherwise.
- PR titles, descriptions, and commit messages must not mention "Claude Code," "Claude," "Anthropic," or include a "Generated with Claude Code" / "Co-Authored-By: Claude" footer.
