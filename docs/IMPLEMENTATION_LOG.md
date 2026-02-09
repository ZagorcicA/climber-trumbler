# Boulder QTE - Implementation Log

Chronological record of development decisions, problems encountered, and solutions applied.

---

## 📅 Session 1: Project Setup & Phase 1

### **Initial Setup**
- Created Godot 4.5 project
- Read design document: Boulder QTE climbing game concept
- Discussed approach: focus on gameplay mechanics first, good code structure (DRY, SSOT)
- User is new to Godot

### **Decision: Use GDScript**
- Alternatives considered: C#
- Chosen: GDScript for better documentation, easier for beginners, tighter Godot integration
- User confirmed preference for GDScript

### **Decision: Gameplay Mechanics Choices**
Asked user clarifying questions about implementation approach:

1. **Limb Control:** Mouse position (drag-to-target) ✓
   - More intuitive than keyboard physics forces
   - Players point where they want limb to go

2. **Latch System:** Proximity auto-snap ✓
   - Simpler and more forgiving
   - Limb snaps to nearest hold when close enough + button press

3. **Stamina Model:** Global pool (shared) ✓
   - Simpler for prototype
   - One stamina bar for all limbs

4. **Language:** GDScript ✓
   - Confirmed

### **Phase 1 Implementation: Core Physics Foundation**

**1.1 Input Map Setup**
- Added input actions to project.godot:
  - select_limb_1-4 (keys 1-4)
  - latch_limb (Space)
  - detach_limb (X)
  - restart_level (R)

**1.2 Directory Structure**
Created organized folder hierarchy:
```
scenes/ (player, environment, ui)
scripts/ (player, environment, managers, ui)
resources/ (PhysicsMaterials)
```
- Follows good organization principles
- Clear separation of concerns

**1.3 Player & Limb Scenes**

**Problem:** Initial .tscn files had formatting errors
- Sub-resources were at end of file (incorrect)
- Godot requires sub-resources before nodes
- **Solution:** Moved all [sub_resource] blocks to top of file after [ext_resource]

**Decision:** Let user add limbs manually in editor (Option B)
- Avoided hand-coding complex .tscn with proper UIDs
- User learned Godot editor workflow
- Positioned limbs anatomically (shoulders, hips)

**1.4 Ragdoll Physics Configuration**

**Initial Configuration:**
- Masses: Torso 10kg, Head 3kg, Limbs 2kg each
- Damping: Linear 1.0-1.5, Angular 2.0-2.5
- Joint softness: 0.1
- Total mass: ~19kg

**Result:** Player felt very heavy, couldn't move effectively.

**1.5 Collision Layers Setup**
Configured physics layers for proper interactions:
- Layer 1: player_body (all body parts)
- Layer 2: environment (static objects)
- Layer 3: holds (climbing holds)
- Masks set correctly for collision detection

**1.6 Visual Feedback**
- Added colored ColorRect nodes for all body parts
- Blue torso, tan head, brown limbs
- Simple, clear visual style

---

## 📅 Session 2: Phase 2 - Limb Control & Physics Tuning

### **2.1 Level Creation**

**Decision:** Create proper Level1.tscn instead of putting floor in Player.tscn
- Follows good code principles (separation of concerns)
- Player is reusable component
- Level contains environment + player instance

Created Level1.tscn with:
- Floor (StaticBody2D on layer 2)
- Player instance at spawn position
- Camera with 0.8 zoom
- Set as main scene in project.godot

**2.2 InputManager Singleton**

**Decision:** Create centralized input manager (SSOT pattern)
- Registered as autoload in project.godot
- Single place that reads Input
- All other scripts query InputManager
- Benefits:
  - Consistent state across systems
  - Easy to add input remapping later
  - Single point for debugging input

Created input_manager.gd with:
- Mouse position tracking
- Per-frame input flags (latch_just_pressed, etc.)
- get_mouse_world_position() accounting for camera

**2.3 Player Controller Updates**

Updated player.gd to use InputManager:
- Queries InputManager.limb_selection_pressed
- Calls latch/detach based on InputManager flags
- No direct Input polling

**2.4 Limb Movement Implementation**

Limb.gd already had movement code from Phase 1:
- Uses _physics_process() for frame-rate independence
- Applies forces toward get_global_mouse_position()
- Has MOVE_FORCE, MAX_VELOCITY, DAMPING constants

**Problem:** Limb didn't follow mouse cursor when selected

**Initial values:**
- MOVE_FORCE: 5000
- MAX_VELOCITY: 200
- DAMPING: 0.95

**Debugging:**
- Confirmed limb selection working (yellow highlight appeared)
- Code was executing (_physics_process called)
- Forces being applied

**Root cause:** Forces too weak compared to mass + gravity + damping

**Solution:** Increased forces dramatically
- MOVE_FORCE: 5000 → 15000 (3x increase)
- MAX_VELOCITY: 200 → 800 (4x increase)
- DAMPING: 0.95 → 0.99 (less resistance)
- Also reduced RigidBody2D damping:
  - Linear: 1.5 → 0.5
  - Angular: 2.5 → 1.0

**Result:** Limb now visibly follows mouse! ✓

---

## 📅 Session 3: Phase 3 - Hold System

### **3.1 Hold Scene Creation**

Created Hold.tscn with:
- StaticBody2D (layer 4, mask 0)
- DetectionArea (Area2D, layer 4, mask 1)
- Visual red ColorRect
- Green AttachedIndicator (initially hidden)

**3.2 Hold Script**

Created hold.gd with:
- attached_limbs array tracking
- attach_limb() / detach_limb() functions
- Visual feedback when attached

**3.3 Limb Detection System**

Limb.gd already had GrabArea and signal connections:
- _on_hold_detected() adds to nearby_holds array
- _on_hold_lost() removes from array
- get_nearest_hold() finds closest

**Problem:** Limb wouldn't latch when pressing Space near hold

**Debugging:**
- Confirmed Space key registered
- Player.gd called limb.latch_to_hold()
- nearby_holds array was empty!

**Root cause:** GrabArea had no collision layer/mask configured
- Area2D with no mask can't detect anything
- Silent failure - no error, just doesn't work

**Solution:** Added to Limb.tscn GrabArea:
- collision_layer = 1 (player body layer)
- collision_mask = 4 (holds layer)

Now GrabArea (layer 1) can detect DetectionArea (layer 4)

**Result:** Hold detection working! ✓
- Console prints: "Hold detected! Nearby holds count: 1"
- Pressing Space successfully latches
- Hold shows green glow
- Limb stops following mouse

**3.4 Latch/Detach Implementation**

Latch system creates dynamic PinJoint2D:
- Added as child of Player node
- Connects limb to hold at hold position
- Softness 0.05 (fairly rigid for stable grip)

Detach system:
- Removes PinJoint2D
- Notifies hold
- Limb can move freely again

**3.5 Hold Collision Warning**

User noted warning: "Hold has no shape"
- StaticBody2D without CollisionShape2D
- Doesn't affect gameplay (DetectionArea handles interaction)
- But technically incomplete

**Decision:** User added CollisionShape2D manually
- Makes holds physically solid
- More realistic (limbs can collide with hold)
- Better for future interactions

---

## 📅 Session 4: Physics Tuning

**User Request:** "Player feels too heavy, can't lift body by moving limbs"

Goal: Light, floppy ragdoll that swings around dramatically.

### **4.1 Mass Reduction**

**Changes:**
- Torso: 10kg → 3kg (70% lighter!)
- Head: 3kg → 1kg
- Limbs: 2kg → 0.8kg each
- Total: 19kg → 6.2kg

**Result:** Much easier to move body with limbs

### **4.2 Damping Reduction**

**Changes:**
- Torso/Head linear: 1.0 → 0.3
- Torso angular: 2.0 → 0.5
- Limbs linear: 0.5 → 0.2
- Limbs angular: 1.0 → 0.3
- Movement DAMPING: 0.98 → 0.99

**Result:** More responsive, less "swimming through honey"

### **4.3 Joint Softness Increase**

**Changes:**
- All joints: 0.1 → 0.3-0.4

**Reasoning:**
- Softer joints allow limbs to "wind up" before pulling body
- Creates momentum and swing
- More satisfying ragdoll feel

**Result:** Body swings more dynamically

### **4.4 Force Increase**

**Changes:**
- MOVE_FORCE: 5000 → 15000 (to match lighter masses)
- MAX_VELOCITY: 400 → 800

**Result:** Can effectively swing body to generate upward momentum

**Final Feel:** Player can now use limb movement to swing body around, generating momentum for climbing. Feels light, floppy, and dynamic.

**User Response:** User satisfied, wanted to experiment with values personally.

**Provided:** Comprehensive tuning guide explaining all parameters.

---

## 📅 Session 5: Phase 4 - Head Tracking (FIXED)

### **5.1 Head Tracking Implementation**

**Goal:** Add character/personality, help player see what they're doing.

**Design:**
- Two modes: Tracking (look at cursor) and Idle (upright)
- Switch based on limb selection state
- Use physics forces for smooth movement

**Status:** ✓ COMPLETE
- head.gd properly implements tracking and upright modes
- Head responds to cursor position when limb selected
- Head returns to upright when idle
- Physics-based rotation feels smooth and natural

---

## 📅 Session 6: Project Refactoring (COMPLETE)

### **6.1 Hold Consolidation**

**Changes:**
- Consolidated HoldEasy, HoldMedium, HoldHard → single Hold.tscn
- Added DIFFICULTY_COLORS dict to hold.gd for programmatic color setting
- Difficulty set per instance in each level scene

**Result:** Cleaner codebase, easier hold management

### **6.2 Scene Reorganization**

**Changes:**
- Moved scenes/environment/Levels/ → scenes/levels/
- Renamed level scenes to reflect difficulty (LevelEasy, LevelMedium, LevelHard)
- Updated all path references

**Result:** Better project organization, top-level levels folder

### **6.3 Documentation Folder Rename**

**Changes:**
- Renamed claude.md/ → docs/
- Updated all references in README.md, CONTRIBUTING.md
- All technical documentation consolidated in docs/

**Result:** Clearer project structure

### **6.4 Cleanup**

**Changes:**
- Added *.uid to .gitignore
- Deleted prototype.tscn
- Removed empty resources/PhysicsMaterials/ folder

**Result:** Cleaner git history

---

## 📅 Session 7: PhysicsConstants Centralization

### **7.1 Problem: Scattered Constants**

Physics constants were spread across 5 script files with values that differed from documentation:
- Torso mass: 8.0 in scene vs 3.0 in docs
- Gravity scale: 0.3 in scene (causing floating!) vs 1.0 in docs
- Limb mass: 3.0 in scene vs 0.8 in docs

### **7.2 Solution: PhysicsConstants Autoload**

Created `scripts/managers/physics_constants.gd` as a centralized SSOT:
- Registered as first autoload in project.godot (loads before InputManager and StaminaManager)
- All physics values organized by category
- Based on realistic 75kg experienced climber with moderate grip strength
- Mass scale factor 0.1x preserves human proportions while keeping gameplay viable

### **7.3 Mass Distribution (75kg Climber)**

| Part | Real kg | Game Mass | % of Body |
|------|---------|-----------|-----------|
| Head | 5.0 | 0.5 | 6.7% |
| Torso | 37.5 | 3.8 | 50% |
| Each Arm | 4.0 | 0.4 | 5.3% |
| Each Leg | 12.4 | 1.2 | 16.5% |
| **Total** | **75.0** | **7.5** | **100%** |

### **7.4 Key Changes**

- Fixed gravity_scale from 0.3 to 1.0 (no floating!)
- Fixed torso mass from 8.0 to 3.8, head from 2.0 to 0.5
- Arms (0.4) now lighter than legs (1.2) — realistic differentiation
- Migrated 21 constants from 5 scripts into one file
- Added `_apply_physics_constants()` in player.gd for runtime enforcement
- hold.gd: replaced const dict with match statement (autoload timing)
- Updated all 6 documentation files

### **7.5 Grip Strength**

Grip strength (45 kg-force) is encoded through the hold difficulty drain multipliers:
- Easy holds: 1.0x drain (jug holds)
- Medium holds: 1.5x drain
- Hard holds: 2.5x drain (crimps/slopers)
Combined with position multipliers (arms-only 2.5x, legs-efficient 0.7x), this creates the grip challenge.

---

## 📅 Key Decisions Summary

### **Architecture Decisions**
| Decision | Rationale | Impact |
|----------|-----------|--------|
| GDScript over C# | Beginner-friendly, better docs | Faster development |
| Component-based scenes | Reusability, modularity | Clean architecture |
| InputManager singleton | SSOT for input | Consistent state |
| Manual limb placement | Learning experience, precision | Better control |

### **Gameplay Decisions**
| Decision | Rationale | Impact |
|----------|-----------|--------|
| Mouse control | Intuitive, accessible | Easy to learn |
| Proximity auto-snap | Forgiving, prototype-friendly | Less frustration |
| Global stamina | Simpler for MVP | Faster implementation |
| Light masses | Fun, dynamic movement | Better gameplay |

### **Technical Decisions**
| Decision | Rationale | Impact |
|----------|-----------|--------|
| Soft joints (0.4) | Ragdoll feel | Satisfying physics |
| High forces (15000) | Overcome mass + gravity | Responsive |
| Low damping (0.2-0.3) | Dynamic movement | More challenging |
| Layer-based collisions | Proper physics separation | Clean interactions |

---

## 🐛 Problems Encountered & Solutions

### **Problem 1: .tscn Files Wouldn't Load**
- **Cause:** Sub-resources declared after nodes (wrong order)
- **Solution:** Move all [sub_resource] blocks to file top
- **Learning:** Godot file format is order-sensitive

### **Problem 2: Limbs Didn't Follow Mouse**
- **Cause:** Forces too weak (500) vs mass + damping
- **Solution:** Increased force 30x to 15000
- **Learning:** Physics forces must overcome all resistances

### **Problem 3: Hold Detection Failed**
- **Cause:** GrabArea had no collision layer/mask
- **Solution:** Set layer=1, mask=4
- **Learning:** Silent failures common with unconfig'd collision

### **Problem 4: Player Too Heavy**
- **Cause:** Realistic masses (10kg torso) too heavy for fun gameplay
- **Solution:** Reduced masses 70% (torso 3kg)
- **Learning:** Realism ≠ fun; tune for gameplay first

### **Problem 5: Head Tracking Now Working** ✓ RESOLVED
- **Previous Issues:** Head rotation not responding
- **Resolution:** Fixed in refactoring (Session 6)
- **Status:** Head properly tracks cursor and returns to upright
- **Learning:** Careful debugging and physics tuning resolved the issue

---

## Session 8: Physics Realism Rework (Phase 5.6)

### **8.1 Problem: Player Flying**

Mouse dragging with MOVE_FORCE (6000) on arm mass 0.4 produced 15,000 px/s^2 acceleration — far exceeding gravity (980 px/s^2). This caused the player to fly when moving the mouse upward.

### **8.2 Solution: Split Movement Modes**

Created two distinct movement modes based on latch state:

**When no limbs latched (grounded):**
- Force applied on X-axis only (MOVE_FORCE_HORIZONTAL = 5000.0)
- Y component zeroed — gravity handles all vertical movement
- Prevents flying entirely

**When any limb latched (climbing):**
- Full directional force at reduced magnitude (MOVE_FORCE_ATTACHED = 3000.0)
- Latched limb acts as physical anchor via PinJoint2D
- Allows reaching toward holds above

### **8.3 Lean/Swing Mechanic**

Added distance-proportional lean when hanging from holds:
- LEAN_FORCE (2000) and LEAN_TORQUE (6000) applied to torso toward mouse
- Scales linearly with cursor distance up to LEAN_MAX_DISTANCE (300px)
- LEAN_DAMPING (0.92) prevents wild oscillation
- Only activates when latched AND off ground

### **8.4 Limb Rotation Tracking**

Added rotation system so limb tips point toward mouse cursor:
- Selected limbs: angular_velocity set toward mouse at LIMB_LOOK_SPEED (50.0)
- Unselected limbs: return to upright at LIMB_UPRIGHT_CORRECTION (5.0)
- Clamped to LIMB_MAX_LOOK_ANGLE (120 degrees)
- Uses `direction.angle() - PI/2` offset (limb tip points DOWN at rotation 0)

### **8.5 Position/Rotation Mode Toggle**

Added Q key to toggle between two control modes:
- **Position mode** (default): mouse moves limb + lean applies
- **Rotation mode**: mouse only rotates selected limb, no movement force, no lean
- State tracked in InputManager.is_rotation_mode

### **8.6 LevelEasy Zig-Zag Redesign**

Replaced 5 randomly-placed holds with 10 holds in clear alternating left-right pattern:
- Spans from y=480 (near floor) to y=-140 (top)
- Alternates between x≈420-450 (left) and x≈650-700 (right)
- Camera adjusted to position=(576,200), zoom=(0.6,0.6) to show full route

### **8.7 New Constants Added to PhysicsConstants**

9 new constants in physics_constants.gd:
- MOVE_FORCE_HORIZONTAL, MOVE_FORCE_ATTACHED
- LIMB_LOOK_SPEED, LIMB_MAX_LOOK_ANGLE, LIMB_UPRIGHT_CORRECTION
- LEAN_FORCE, LEAN_TORQUE, LEAN_DAMPING, LEAN_MAX_DISTANCE

---

## Milestones Achieved

- Phase 1: Ragdoll physics with joints working
- Phase 2: Mouse-based limb control working
- Phase 3: Hold system with latch/detach working
- Phase 4: Head tracking fully working
- Phase 4.5: Project refactoring (holds, scenes, docs)
- Phase 5: Stamina system implemented
- Phase 5.5: PhysicsConstants centralization (SSOT for all physics values)
- Phase 5.6: Physics realism rework (horizontal-only, lean, limb rotation, mode toggle)

**Overall Progress:** ~92% of core prototype complete (need win/lose conditions for MVP)

---

## 💡 Key Learnings

1. **Start Simple:** Physics foundation first, then add features
2. **Debug Early:** Print statements caught many issues
3. **Tune Iteratively:** Small changes, test frequently
4. **Document Decisions:** Why matters as much as what
5. **Physics is Tricky:** Interactions between systems can be non-obvious
6. **User Involvement:** Having user test immediately caught issues

---

## 📝 Notes for Continuation

- ✓ Head tracking is now working
- ✓ Project refactored and organized
- ✓ Stamina system implemented (StaminaManager + StaminaBar UI)
- ✓ PhysicsConstants centralized as autoload singleton (SSOT)
- Physics feel is good - user was happy
- Architecture is solid - easy to extend
- All documentation updated for current state

**Next Priority:** Win/lose conditions and polish
- Win condition trigger at top of level
- Lose condition (stamina = 0)
- Game restart on loss
- Sound effects and particle effects

### **Problem 6: Player Flying When Dragging Mouse** ✓ RESOLVED
- **Cause:** MOVE_FORCE (6000) / arm mass (0.4) = 15,000 px/s^2 >> gravity (980 px/s^2)
- **Solution:** Split into horizontal-only force (unattached) and reduced directional force (attached)
- **Learning:** Force magnitude must be contextualized by mass ratio and gravity

---

End of implementation log. Project ready for handoff.
