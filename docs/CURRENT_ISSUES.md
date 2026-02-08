# Climber Trumbler - Current Issues

Active problems that need resolution before continuing development.

---

## ✅ Resolved Issues

### Head Tracking System — FIXED
- **Previously:** Head remained in ragdoll state, not responding to tracking commands
- **Fix:** Working correctly now — head tracks cursor when limb selected, returns upright when idle
- **Files:** `scripts/player/head.gd`, `scripts/player/player.gd`

---

## 🟡 Minor / Non-Blocking

### 1. Debug Print Statements in hold.gd
- `hold.gd` line 58 prints drain multiplier every frame
- Should be removed or gated behind a debug flag before release

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

**Last Updated:** February 8, 2026
