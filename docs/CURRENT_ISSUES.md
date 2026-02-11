# Climber Trumbler - Current Issues

Active problems that need resolution before continuing development.

---

## Resolved Issues

### Player Flying When Dragging Mouse — FIXED
- **Previously:** MOVE_FORCE (6000) on arm mass 0.4 produced 15,000 px/s^2 acceleration, far exceeding gravity (980), causing player to fly
- **Fix:** Split into MOVE_FORCE_HORIZONTAL (5000, X-axis only when unattached) and MOVE_FORCE_ATTACHED (3000, full direction when another limb is latched)
- **Files:** `scripts/player/limb.gd`, `scripts/managers/physics_constants.gd`

### Head Tracking System — FIXED
- **Previously:** Head remained in ragdoll state, not responding to tracking commands
- **Fix:** Working correctly now — head tracks cursor when limb selected, returns upright when idle
- **Files:** `scripts/player/head.gd`, `scripts/player/player.gd`

### Physics Constants Scattered — FIXED
- **Previously:** Constants spread across 5 files with scene/doc inconsistencies
- **Fix:** All physics values centralized in PhysicsConstants autoload singleton
- **Files:** `scripts/managers/physics_constants.gd` (SSOT), all scripts updated to reference it

---

## 🟡 Minor / Non-Blocking

### 1. hold.gd Drain Multiplier Refactored
- The `DIFFICULTY_DRAIN_MULTIPLIER` dict was removed and replaced with a match statement in `get_drain_multiplier()`
- Debug print statements have been removed
- Refactored due to autoload timing constraints (const dicts cannot reference autoload values at parse time)

### 2. Silent Stamina Latch Rejection
- When player can't latch due to low stamina, only a `print()` fires
- No UI feedback (flash, sound, shake) — player may not understand why latch failed
- **Suggestion:** Connect to stamina_warning signal or add visual feedback

### 3. Stamina Warning Signal Unused
- `StaminaManager` emits `stamina_warning` at 30% but nothing visibly reacts to it
- Could trigger a bar flash, sound, or screen edge effect

### 4. Player Input System Needs Rework
- Current: keyboard numbers 1-4 for limb selection
- Discussed as a must-do in refactoring TODO
- Needs team decision on new input scheme before implementation

---

## 🟢 No Critical Issues

All core systems (physics, limb control, holds, head tracking, stamina) are working as expected.

---

**Last Updated:** February 9, 2026
