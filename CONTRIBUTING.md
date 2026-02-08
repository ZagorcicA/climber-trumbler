# Contributing to Climber Trumbler

This project uses Claude Code for AI-assisted development. This guide explains the workflow.

## Setup

### 1. Install Prerequisites

- **Godot 4.3+** from [godotengine.org](https://godotengine.org/download)
- **Claude Code** (Anthropic's CLI tool)

### 2. Run Project Setup (IMPORTANT - Do This First!)

After cloning, run the setup script to install git hooks and clear UID caches:

```bash
chmod +x setup.sh
./setup.sh
```

This installs a pre-commit hook that strips machine-specific Godot UIDs from scene files. Without this, your commits will cause warnings for other team members. See `SETUP_GUIDE.md` for details.

### 3. Run Godot with Log Piping

This is the key step - it lets Claude see Godot's output.

**macOS / Linux:**
```bash
godot --path . --editor 2>&1 | tee logs/godot_output.log
```

**Windows (PowerShell):**
```powershell
godot --path . --editor 2>&1 | Tee-Object -FilePath logs/godot_output.log
```

**Windows (Git Bash):**
```bash
godot --path . --editor 2>&1 | tee logs/godot_output.log
```

### 4. Start Claude Code

In a separate terminal, in the project directory:
```bash
claude
```

Claude can now read `logs/godot_output.log` to see what's happening in Godot.

## Development Workflow

### The Test Cycle

1. **Make code changes** in Godot editor
2. **Add debug prints** with clear prefixes (see below)
3. **Clear logs:** `> logs/godot_output.log` (or ask Claude to remind you)
4. **Press F6** to run the scene
5. **Claude reads** `logs/godot_output.log` and analyzes
6. **Iterate** based on findings

### Debug Print Standards

Always use clear prefixes:
```gdscript
print("[INIT] Component initialized")
print("[DEBUG] Variable x = ", x)
print("[STATE] Changed from ", old, " to ", new)
print("[PHYSICS] Force applied: ", force)
print("[ERROR] Something went wrong: ", error)
```

### Before Making Changes

For non-trivial changes, Claude should:
1. Read the log file to understand current state
2. Form a hypothesis about the issue
3. Propose a solution with risk level (LOW/MEDIUM/HIGH)
4. Get your approval before proceeding

See `CLAUDE_CODE_INSTRUCTIONS.md` for the full investigation template.

## Code Style

### GDScript Guidelines

- Use snake_case for variables and functions
- Use PascalCase for classes and nodes
- Add type hints where helpful
- Keep functions focused and small
- Use signals for decoupled communication

### File Organization

```
scenes/
├── player/      # Player.tscn, Limb.tscn
├── environment/ # Hold.tscn
├── levels/      # Level scenes (LevelEasy, LevelMedium, LevelHard)
└── ui/          # UI scenes (StaminaBar, StartScreen)

scripts/
├── player/      # Player, limb, head controllers
├── environment/ # Hold, level management
├── managers/    # Autoload singletons (InputManager, StaminaManager)
└── ui/          # UI controllers
```

### Physics Code

- Use `_physics_process()` for physics-related updates
- Apply forces with `apply_central_force()`, not by setting velocity directly
- Keep physics constants at the top of scripts
- Document any magic numbers

## Pull Request Guidelines

1. **Test your changes** - Run the game, check the logs
2. **Clear debug prints** - Remove spammy prints before PR
3. **Describe what changed** - Explain the why, not just the what
4. **Keep PRs focused** - One feature or fix per PR

## Project Architecture

### Autoload Singletons (Single Source of Truth)

- **InputManager** - All input state
- **StaminaManager** - All stamina state

### Key Scripts

| Script | Purpose |
|--------|---------|
| `player/player.gd` | Main player controller |
| `player/limb.gd` | Individual limb physics |
| `player/head.gd` | Head tracking |
| `environment/hold.gd` | Climbing holds |
| `managers/stamina_manager.gd` | Stamina system |

### Signals

- `stamina_changed(value, difficulty)` - Stamina updates
- `stamina_depleted()` - Game over condition
- `stamina_warning()` - Low stamina alert

## Getting Help

- Check `docs/CURRENT_ISSUES.md` for known problems
- Check `docs/ARCHITECTURE.md` for system design
- Ask Claude to investigate if you're stuck

## Philosophy

We debug systematically:
1. **Observe** - Read logs, understand current behavior
2. **Hypothesize** - Form theory about the issue
3. **Test** - Make minimal change to test
4. **Analyze** - Did it work?
5. **Iterate** - Refine or try next approach

Small, careful steps with clear evidence beat wild experimentation.
