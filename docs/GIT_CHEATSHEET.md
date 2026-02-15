# Git Cheat Sheet — Climber Trumbler

Quick reference for common git operations. Assumes remote is `origin` and branches: `main`, `Zaga`, `lujo`, `Antonio`.

---

## Check Status

```bash
# What branch am I on?
git branch --show-current

# Any uncommitted changes?
git status

# See all branches (local + remote)
git branch -a
```

## Fetch & Compare

```bash
# Fetch latest from everyone (doesn't change your files)
git fetch --all

# What's new on main that I don't have?
git log HEAD..origin/main --oneline

# What's new on lujo's branch since main?
git log origin/main..origin/lujo --oneline

# What's new on Antonio's branch since main?
git log origin/main..origin/Antonio --oneline

# Visual graph of recent history (all branches)
git log --oneline --all -20 --graph
```

## Sync Your Branch

```bash
# Pull latest into current branch
git pull

# Update Zaga with latest main
git checkout Zaga
git merge origin/main

# Push your branch
git push origin Zaga
```

## Making Changes

```bash
# Stage specific files
git add file1.gd file2.tscn

# Stage everything
git add -A

# Commit
git commit -m "short description of what changed"

# Push
git push origin Zaga
```

## Undo / Fix

```bash
# Unstage a file (keeps your changes)
git restore --staged filename

# Discard local changes to a file (DESTRUCTIVE)
git restore filename

# Undo last commit but keep changes
git reset --soft HEAD~1

# See what you changed before committing
git diff
git diff --staged
```

## Stash (save work temporarily)

```bash
# Stash current changes
git stash

# List stashes
git stash list

# Bring back stashed changes
git stash pop
```

## Inspect

```bash
# Who changed what in a file
git log --oneline scripts/player/Player.gd

# Full diff between branches
git diff origin/main..origin/Zaga

# See a specific commit
git show <commit-hash>
```
