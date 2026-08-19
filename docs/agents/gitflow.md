# Git Workflow

Solo-developer, trunk-based flow tuned so that **Xcode never has to notice git**.

## The one invariant

**The repo root (`/Users/timurmustafa/Programming/sira`) stays on `main` at all times.**

That folder is what Xcode has open. Never run `git checkout`, `git switch`, or `git stash`
there to move off `main`. Branch switching under a live Xcode window is what causes stale
indexes, phantom errors, and surprise full rebuilds — not merging.

Everything below exists to keep that invariant true.

## Two lanes

### Lane 1 — hands-on edits by the human: commit straight to `main`

No branch, no PR. Edit in Xcode, ⌘R to verify, then:

```bash
git add -A && git commit && git push
```

One person reviewing their own PR is ceremony, and the branch round-trip is exactly the
thing that confuses Xcode.

### Lane 2 — agent work: worktree + PR + squash merge

Agent-authored changes get a reviewable diff, in a **separate working directory** so the
root stays on `main`:

```bash
git worktree add ../sira-wt/<slug> -b feature/<slug>
```

Work happens in `../sira-wt/<slug>`. To build or run it, open
`../sira-wt/<slug>/sira.xcodeproj` as a *second* Xcode window — leave the main window alone.

Branch prefixes: `feature/`, `fix/`, `chore/`.

Land it, then clean up in one go:

```bash
gh pr merge --squash --delete-branch
git -C /Users/timurmustafa/Programming/sira pull
git worktree remove ../sira-wt/<slug>
```

The `pull` is not optional — without it the root Xcode window is building a `main` that no
longer matches the remote.

**Cost, accepted deliberately:** each worktree path has its own DerivedData, so its first
build is a full build. Branch-switching in a single folder invalidates DerivedData anyway
*and* leaves Xcode's index stale, so the worktree is strictly better.

## Releases

Tag on `main`, never on a branch:

```bash
git tag v0.3.0 && git push --tags
```

Archive and TestFlight builds come only from a tagged `main`.

## Branch hygiene

Merged branches are clutter that agents and `git branch` output both trip over. After a
merge, delete local and remote:

```bash
git branch -d <branch>
git push origin --delete <branch>   # or rely on `gh pr merge --delete-branch`
git fetch --prune
```
