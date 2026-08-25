# Git Workflow

Agent-authored changes get a reviewable diff, in a **branch** so the
root stays on `main`:

Branch prefixes: `feature/`, `fix/`, `chore/`.

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
