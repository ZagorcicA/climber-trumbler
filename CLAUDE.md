# Climber Trumbler

> This file is automatically read by Claude Code at the start of every session.
> It provides project context so Claude doesn't need to explore the codebase each time, saving tokens.
> For detailed guidelines see CLAUDE_CODE_INSTRUCTIONS.md.

2D physics-based ragdoll climbing game. Godot 4.3, GDScript.

## Status

Phases 1-5 COMPLETE (physics, limb control, holds, head tracking, stamina).
Next: Phase 6 — Win/Lose conditions. See `docs/NEXT_STEPS.md`.

## Project Structure

```
scenes/player/       → Player.tscn, Limb.tscn
scenes/environment/  → Hold.tscn (single scene, difficulty set per instance)
scenes/levels/       → LevelEasy.tscn, LevelMedium.tscn, LevelHard.tscn
scenes/ui/           → StartScreen.tscn, StaminaBar.tscn
scripts/             → mirrors scenes/ layout
scripts/managers/    → InputManager, StaminaManager (autoload singletons)
docs/                → architecture, physics guide, roadmap, issues
```

## Rules

- Read `logs/godot_output.log` after EVERY code change — never assume it works
- Clear logs before each test: `> logs/godot_output.log`
- Remove ALL debug print() statements after a feature is verified working
- Small scoped changes, test between each one
- Ask before making MEDIUM/HIGH risk changes (see CLAUDE_CODE_INSTRUCTIONS.md)
- Do NOT read every file to "understand the project" — this file + the relevant script is enough

## Key Patterns

- Holds use `@export var hold_difficulty` enum — color set programmatically in `_ready()`
- Stamina uses position-based multipliers (arms-only = high drain, 3+ limbs = regen)
- Hold difficulty multiplies drain rate (EASY=1.0, MEDIUM=1.5, HARD=2.5)
- All input goes through InputManager singleton (SSOT)
- Legs/torso detect floor via collision signals for grounded state

## Don't

- Don't add UIDs to .tscn files (pre-commit hook strips them)
- Don't leave debug prints in finished code
- Don't make multiple changes without testing between each
- Don't refactor or rename files without PM approval (coordinate via git)
