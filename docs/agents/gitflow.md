# Git Workflow

Trunk-based, Xcode-friendly. Two rules carry the whole scheme:

1. **The repo root stays on `main`, permanently.** It is the human's checkout — your
   Xcode window, your schemes, your breakpoints, your DerivedData. Nothing switches it.
2. **Every agent-authored change happens in a `git worktree` on its own short-lived
   branch**, then lands on `main` via PR + squash merge.

Human edits commit straight to `main` in the root. Agent edits never touch it.

Branch prefixes: `feature/`, `fix/`, `chore/`.

## One worktree per unit of work

Branch off `main`, not off another branch:

```bash
git worktree add .claude/worktrees/<slug> -b fix/<slug> origin/main
```

Agents running in parallel each get their own worktree, so they never fight over the
same working directory, the same index, or the same build products. When the work is
merged, the worktree goes away:

```bash
git worktree remove .claude/worktrees/<slug>
git worktree prune
```

`.claude/worktrees/` is gitignored. Claude Code's `EnterWorktree` tool creates and
cleans these up automatically; the commands above are for doing it by hand.

## Reviewing agent work without opening the worktree

Do **not** open a worktree in Xcode to review a diff. It gets its own DerivedData, it
re-resolves SPM from scratch, and a second window competes with the root one for
scheme state. The flow is built so you never have to:

```bash
gh pr diff <n>          # read the change
gh pr merge <n> --squash --delete-branch
git pull                # in the root — the change is now in your normal Xcode window
```

Review the diff, merge, pull. The code arrives in the checkout you already had open.

If you genuinely need to *run* an agent's branch before merging, don't switch the root
branch — read it detached and come back:

```bash
git fetch && git switch --detach origin/<branch>
git switch main
```

## When a feature needs more than one branch

The default is one worktree per ticket, straight off `main` — even for a large feature,
as long as the tickets land one at a time.

Only when several agents must work on the *same* feature concurrently, stack a level:
a long-lived `feature/<x>` integration branch, one worktree per agent on
`feature/<x>-<sub>`, each merging up into `feature/<x>`, which then PRs to `main` as a
single squash. This costs an extra merge hop and an integration branch that goes stale
if the feature drags. Reach for it when parallelism forces you to, not by default.

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

Removing the worktree does not delete its branch, and deleting the branch does not
remove the worktree. Do both.
