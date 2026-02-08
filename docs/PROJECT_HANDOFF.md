# Boulder QTE - Project Handoff Document

**Date:** 2025-11-12
**Engine:** Godot 4.5
**Language:** GDScript
**Status:** Prototype Phase - Core Systems Implemented

---

## 🎮 Game Concept

**Boulder QTE** is a 2D physics-based climbing game where the player controls a ragdoll character with individual limb control. The player must strategically position and latch limbs onto climbing holds to reach the top of a wall while managing stamina.

**Core Pillars:**
- Tactile ragdoll physics with satisfying movement
- Precision limb control with mouse-based targeting
- Puzzle-like climbing requiring hold sequencing
- Resource management through stamina system (not yet implemented)

**Gameplay Loop:**
1. Select a limb (keys 1-4)
2. Move limb toward mouse cursor (physics-based)
3. Latch limb to nearby hold (Space)
4. Use other limbs to climb upward
5. Detach limbs (X) to reposition
6. Reach the top to win

---

## ✅ What's Been Implemented

### **Phase 1: Core Physics Foundation** ✓ COMPLETE
- Player ragdoll with torso, head, 4 limbs
- PinJoint2D connections for realistic physics
- Collision layers properly configured
- Physics materials and damping tuned for "floppy" feel
- Visual feedback (colored body parts, selection highlights)

### **Phase 2: Limb Control System** ✓ COMPLETE
- InputManager singleton (SSOT for all input)
- Limb selection with keys 1-4
- Mouse-following physics forces (15000 force)
- Visual highlighting for selected limb
- Smooth, responsive limb movement

### **Phase 3: Hold System & Latching** ✓ COMPLETE
- Hold scenes with proximity detection
- Latch system using PinJoint2D
- Detach functionality
- Visual feedback (green glow when attached)
- Multiple holds placed in test level

### **Phase 4: Head Tracking** ✓ COMPLETE
- Head controller script created and working
- Tracks cursor when limb selected
- Stays upright when idle

---

## 📁 Project Structure

```
climber--trumbler/
├── scenes/
│   ├── player/
│   │   ├── Player.tscn          # Main player with torso, head, 4 limbs
│   │   └── Limb.tscn            # Reusable limb component
│   ├── environment/
│   │   └── Hold.tscn            # Climbing hold (difficulty set per instance)
│   ├── levels/
│   │   ├── LevelEasy.tscn       # Easy level with floor + holds
│   │   ├── LevelMedium.tscn     # Medium difficulty level
│   │   └── LevelHard.tscn       # Hard difficulty level
│   └── ui/
│       ├── StaminaBar.tscn      # Stamina indicator UI
│       └── StartScreen.tscn     # Main menu
│
├── scripts/
│   ├── player/
│   │   ├── player.gd            # Player controller, limb coordination
│   │   ├── limb.gd              # Individual limb physics & control
│   │   └── head.gd              # Head tracking
│   ├── environment/
│   │   ├── hold.gd              # Hold attachment logic with difficulty colors
│   │   └── level.gd             # Level management, restart
│   ├── managers/
│   │   ├── input_manager.gd     # Singleton for input (SSOT)
│   │   └── stamina_manager.gd   # Singleton for stamina state
│   └── ui/                      # UI controllers
│
├── docs/                        # Technical documentation
├── design_document.txt          # Original game design doc
├── project.godot                # Godot project config
└── (Other documentation files)  # README.md, CONTRIBUTING.md, etc.
```

---

## 🎯 Design Principles Followed

### **Single Source of Truth (SSOT)**
- InputManager is the only place input state is read
- All scripts query InputManager rather than calling Input directly
- Prevents duplicate input handling and state desync

### **Don't Repeat Yourself (DRY)**
- Limb.tscn is instanced 4 times (not duplicated)
- Shared physics parameters in scene files
- Reusable components throughout

### **Separation of Concerns**
- Player.gd: Coordination and high-level control
- Limb.gd: Individual limb physics and behavior
- Hold.gd: Hold-specific logic
- InputManager: Pure input state management

### **Component-Based Design**
- Modular scenes that compose together
- Clear parent-child relationships
- Easy to add/modify individual parts

---

## ⚙️ Current Physics Configuration

### **Body Masses** (Tuned for light, floppy feel)
- Torso: 3.0 kg
- Head: 2.0 kg (user may have changed to 5.0)
- Each Limb: 0.8 kg
- **Total: ~6.2 kg**

### **Damping** (Low for responsiveness)
- Torso/Head: linear 0.3, angular 0.5 (Head angular: 0.1)
- Limbs: linear 0.2, angular 0.3

### **Joint Softness** (Higher = more stretchy/floppy)
- Neck: 0.3
- Arms/Legs: 0.4

### **Limb Movement**
- MOVE_FORCE: 15000.0 (very high to swing body)
- MAX_VELOCITY: 800.0
- DAMPING: 0.99

### **Collision Layers**
- Layer 1: player_body (all body parts)
- Layer 2: environment (floor, walls)
- Layer 3: holds (climbing holds)

---

## 🎨 Visual Style

- Minimalist colored shapes
- Torso: Blue (#0.4, 0.6, 0.8)
- Head: Tan (#0.9, 0.7, 0.6)
- Limbs: Brown (#0.7, 0.5, 0.4 / #0.6, 0.4, 0.3)
- Holds: Red (#0.8, 0.3, 0.2)
- Floor: Dark brown (#0.3, 0.25, 0.2)
- Selection highlight: Yellow semi-transparent
- Attached hold indicator: Green semi-transparent

---

## 🎮 Controls

| Action | Input |
|--------|-------|
| Select Limb 1 (Left Arm) | 1 |
| Select Limb 2 (Right Arm) | 2 |
| Select Limb 3 (Left Leg) | 3 |
| Select Limb 4 (Right Leg) | 4 |
| Latch to Hold | Space |
| Detach from Hold | X |
| Restart Level | R |
| Move Limb | Mouse cursor |

---

## 🚧 Known Issues

None critical at this time. Head tracking is working. Stamina and win/lose systems need implementation.

---

## 🔜 Not Yet Implemented

### **Core Gameplay Missing:**
- Stamina system (drain when holding, regenerate when free)
- StaminaBar UI
- Win condition trigger at top of level
- Lose condition (stamina = 0)
- Game restart on loss

### **Polish Missing:**
- Sound effects (latch, detach, fall, win)
- Particle effects
- More varied level design
- Multiple levels
- Menu system

---

## 💡 Key Insights & Decisions

### **Why Mouse Control?**
Chosen over keyboard forces for more intuitive, accessible gameplay. Players can precisely target where they want limbs to go.

### **Why Such High Forces?**
Force of 15000 needed to overcome:
- Body mass pulling down due to gravity
- Joint constraints
- Damping resistance
Lower forces made the game feel too heavy and unresponsive.

### **Why Low Masses?**
Original masses (Torso: 10kg) made it impossible to swing the body by moving a limb. Reduced to 3kg torso / 0.8kg limbs for dynamic ragdoll feel.

### **Why Soft Joints?**
Softness 0.4 allows limbs to "stretch" before pulling the body, creating satisfying momentum and swing. Too stiff (0.1) felt robotic.

---

## 🔄 Prompt for New Claude Code Instance

**Copy this to the new Claude Code:**

```
I'm continuing development on "Boulder QTE", a 2D physics-based ragdoll climbing game in Godot 4.5.

PROJECT STATUS:
- Phases 1-3 complete: Ragdoll physics, limb control, hold system all working
- Phase 4 in progress: Head tracking system not responding (critical issue)
- Using GDScript, following SSOT and DRY principles
- Project is well-structured with component-based design

CURRENT FOCUS:
The head tracking system is implemented but not working. The head should:
1. Track the mouse cursor when a limb is selected and moving
2. Return to upright position when idle
The code is being called (confirmed via debug prints), but the head doesn't rotate at all.

Please review:
- scripts/player/head.gd
- scenes/player/Player.tscn (Head node configuration)
- CURRENT_ISSUES.md for detailed debug output

I've tried:
- Increasing torque forces (50x multiplier)
- Directly setting angular_velocity instead of apply_torque()
- Adjusting angle calculations
- Reducing angular damping

The physics parameters have been carefully tuned for a light, floppy ragdoll feel. See PHYSICS_TUNING_GUIDE.md for all tunable values.

NEXT GOAL: Fix head tracking, then implement stamina system and win/lose conditions.

All documentation is in the project root directory.
```

---

## 📞 Continuation Checklist

When resuming on new device:
- [ ] Read PROJECT_HANDOFF.md (this file)
- [ ] Review ARCHITECTURE.md for system details
- [ ] Check CURRENT_ISSUES.md for active problems
- [ ] Read PHYSICS_TUNING_GUIDE.md before changing physics
- [ ] Review IMPLEMENTATION_LOG.md for context on decisions
- [ ] Test the game (F5) to see current state
- [ ] Focus on fixing head tracking first
- [ ] Use NEXT_STEPS.md for roadmap

---

**Good luck! The foundation is solid. The head tracking is the only blocker before moving to stamina/win systems.**
