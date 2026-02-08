# Refactoring TODO

Tasks for restructuring the codebase now that 3 people are working on it.

---

## Priority: HIGH

### 1. Rename `KurciZaDrzanje/` to `Holds/` ✓ DONE
- Removed old hold structure

### 2. Consolidate 3 Hold scenes into 1 ✓ DONE
- HoldEasy, HoldMedium, HoldHard consolidated into single Hold.tscn
- `hold.gd` has DIFFICULTY_COLORS dict for programmatic color setting
- Difficulty set per instance in each level

### 3. Move `scenes/environment/Levels/` to `scenes/levels/` ✓ DONE
- Levels are now at top-level scenes/levels/ folder
- Case-sensitive filesystem issue resolved

### 4. Fix case mismatch in `start_screen.gd` ✓ DONE
- Paths now correctly reference `res://scenes/levels/`

### 5. Change player input system
- Current: keyboard numbers 1-4 for limb selection
- Needs rework — discuss new input scheme with team
- Update `InputManager`, `player.gd`, and controls UI

---

## Priority: MEDIUM

### 6. Rename `claude.md/` to `docs/` ✓ DONE
- Folder renamed to docs/
- All technical documentation in place
- References updated in README.md, CONTRIBUTING.md, CLAUDE_CODE_INSTRUCTIONS.md

### 7. Add `*.uid` to `.gitignore` ✓ DONE
- .gd.uid files removed from git tracking
- .gitignore updated

### 8. Clean up unused files ✓ DONE
- Deleted `prototype.tscn`
- Removed `resources/PhysicsMaterials/` empty folder

---

## Priority: LOW

### 9. Update all documentation to reflect new structure ✓ DONE
- ARCHITECTURE.md — file paths and diagrams updated
- PROJECT_HANDOFF.md — project structure section updated
- README.md — project structure section updated
- NEXT_STEPS.md — file references updated
- CONTRIBUTING.md — verified and updated

---

## Notes
- Do NOT execute any of these yet — discuss with team first
- Each refactoring item should be its own commit
- Test the game after each rename to catch broken references
- Coordinate with Antonio and Lujo so nobody's branch conflicts
