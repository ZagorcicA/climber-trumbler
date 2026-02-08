# Climber Trumbler

Contribution

A 2D physics-based ragdoll climbing game built in Godot 4.3.

Control a floppy ragdoll character with 4 independent limbs to climb a bouldering wall. Manage your stamina strategically - hanging by your arms drains energy fast, while using your legs is more efficient!

## Requirements

- **Godot 4.3+** (download from [godotengine.org](https://godotengine.org/download))
- **Claude Code** (recommended for development)

## Quick Start

1. Clone the repository
2. Open the project in Godot (`project.godot`)
3. Press F5 to run or F6 to run the current scene

## Controls

| Key   | Action                                                         |
| ----- | -------------------------------------------------------------- |
| 1-4   | Select limb (1=Left Arm, 2=Right Arm, 3=Left Leg, 4=Right Leg) |
| Mouse | Move selected limb                                             |
| Space | Latch limb to nearest hold                                     |
| X     | Detach limb                                                    |
| R     | Restart level                                                  |

## Development Setup with Claude Code

This project is designed to work with Claude Code for AI-assisted development. The key is piping Godot's output to a log file so Claude can see what's happening.

### macOS / Linux

```bash
cd /path/to/climber-trumbler
godot --path . --editor 2>&1 | tee logs/godot_output.log
```

### Windows (PowerShell)

```powershell
cd C:\path\to\climber-trumbler
godot --path . --editor 2>&1 | Tee-Object -FilePath logs/godot_output.log
```

### Windows (Git Bash)

Same as macOS/Linux:

```bash
cd /c/path/to/climber-trumbler
godot --path . --editor 2>&1 | tee logs/godot_output.log
```

### How it works

- All Godot output (prints, errors, warnings) writes to `logs/godot_output.log`
- Claude Code can read this file to see what's happening in real-time
- Before each test, clear the log: `> logs/godot_output.log` (or `Clear-Content logs/godot_output.log` in PowerShell)
- Press F6 to run the scene, then Claude analyzes the fresh output

## Game Mechanics

### Stamina System

Your position affects stamina drain/regen:

| Position      | Effect                   |
| ------------- | ------------------------ |
| 2 arms only   | 2.5x drain (exhausting!) |
| 1 limb        | 3x drain (desperate)     |
| 1 arm + 1 leg | 1.5x drain               |
| 2 legs only   | 0.7x drain (efficient)   |
| 3+ limbs      | Regenerate (resting)     |
| Free falling  | Fast regen               |

When stamina hits 0, all limbs detach and you fall!

## Project Structure

```
climber-trumbler/
├── scenes/
│   ├── player/        # Player.tscn, Limb.tscn
│   ├── environment/   # Hold.tscn
│   ├── levels/        # LevelEasy.tscn, LevelMedium.tscn, LevelHard.tscn
│   └── ui/            # StaminaBar.tscn, StartScreen.tscn
├── scripts/
│   ├── player/        # player.gd, limb.gd, head.gd
│   ├── environment/   # hold.gd, level.gd
│   ├── managers/      # input_manager.gd, stamina_manager.gd (autoloads)
│   └── ui/            # UI controllers
├── docs/              # Technical documentation (ARCHITECTURE.md, etc.)
├── logs/              # Runtime output (gitignored except .gitkeep)
└── CLAUDE_CODE_INSTRUCTIONS.md  # Development workflow guide
```

## Documentation

See the `docs/` folder for detailed technical docs:

- `ARCHITECTURE.md` - System design and data flow
- `PHYSICS_TUNING_GUIDE.md` - All physics parameters
- `CURRENT_ISSUES.md` - Known issues and debug info
- `NEXT_STEPS.md` - Roadmap

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development workflow and guidelines.

## License

[Add your license here]
