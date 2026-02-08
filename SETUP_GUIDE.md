# Climber Trumbler - Setup Guide

One-time setup for new team members or after a fresh clone.

---

## Quick Setup (One Command)

After cloning or pulling for the first time, run:

```bash
chmod +x setup.sh
./setup.sh
```

That's it. This installs the git hook, clears the Godot UID cache, and sets up the logs folder.

---

## What the Setup Does

### 1. Installs Git Hooks

Copies `hooks/pre-commit` to `.git/hooks/`. This hook automatically strips Godot UIDs from `.tscn` and `.tres` files before every commit.

**Why?** Godot generates machine-specific UIDs inside scene files. Without this hook, pulling someone else's code produces warnings like:

```
WARNING: ext_resource, invalid UID: uid://abc123 - using text path instead
```

The hook prevents these UIDs from ever reaching GitHub.

### 2. Clears Godot UID Cache

Deletes `.godot/uid_cache.bin` so Godot regenerates fresh UIDs for your machine on next launch.

### 3. Creates Logs Directory

Ensures `logs/` exists for Godot output piping.

---

## Running Godot with Claude Code

Open **two terminals** in the project folder:

**Terminal 1 - Godot (with log piping):**

macOS / Linux / Git Bash:
```bash
godot --path . --editor 2>&1 | tee logs/godot_output.log
```

Windows PowerShell:
```powershell
godot --path . --editor 2>&1 | Tee-Object -FilePath logs/godot_output.log
```

**Terminal 2 - Claude Code:**
```bash
claude
```

Claude Code reads `logs/godot_output.log` to see Godot's output in real-time. Before each test, clear the log:

macOS / Linux: `> logs/godot_output.log`
PowerShell: `Clear-Content logs/godot_output.log`

---

## Troubleshooting

### "invalid UID" warnings after pulling

Someone committed without the git hook. Fix:

```bash
rm -f .godot/uid_cache.bin
```

Then close and reopen Godot.

### Git hook not running

Check that it's installed and executable:

```bash
ls -la .git/hooks/pre-commit
```

If missing, run `./setup.sh` again.

### Godot output not appearing in log

Make sure you started Godot with the pipe command from Terminal 1, not by double-clicking.
