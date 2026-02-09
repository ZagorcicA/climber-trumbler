# Boulder QTE - Physics Tuning Guide

Complete reference for all physics parameters and how to tune the ragdoll feel.

---

## 🎯 Quick Reference

| Want to... | Parameter | Location | Direction |
|------------|-----------|----------|-----------|
| Lighter player | Mass | `scripts/managers/physics_constants.gd` | ⬇️ Lower |
| More power | MOVE_FORCE | `scripts/managers/physics_constants.gd` | ⬆️ Higher |
| More floppy | Joint softness | `scripts/managers/physics_constants.gd` | ⬆️ Higher |
| More control | Damping | `scripts/managers/physics_constants.gd` | ⬆️ Higher |
| Less spinning | Angular damp | `scripts/managers/physics_constants.gd` | ⬆️ Higher |
| Faster limbs | MAX_VELOCITY | `scripts/managers/physics_constants.gd` | ⬆️ Higher |
| Floatier | Gravity scale | `scripts/managers/physics_constants.gd` | ⬇️ Lower |

---

## 📊 All Tunable Parameters

### **1. MASS (How Heavy Each Part Is)**

**Current Values:**
```
Torso: 3.8 kg
Head: 0.5 kg
Arms: 0.4 kg each
Legs: 1.2 kg each
Total Body: 7.5 kg
```

> Based on 75kg experienced climber at 0.1x game scale

> Arms and legs have different masses (enforced at runtime by player.gd _apply_physics_constants())

**Where to Edit:**
- `scripts/managers/physics_constants.gd` — MASS_HEAD, MASS_TORSO, MASS_ARM, MASS_LEG

**What It Affects:**
- ⬆️ Higher mass = Harder to move, more momentum, feels "heavy"
- ⬇️ Lower mass = Easier to swing around, feels "floaty"
- **Mass ratio matters:** If torso is 10x heavier than limbs, limbs won't move body much
- Total mass affects how fast you fall due to gravity

**Recommended Ranges:**
- Torso: 2.0 - 5.0
- Head: 1.0 - 3.0
- Limbs: 0.5 - 1.5

**Tips:**
- Keep torso heaviest (it's the anchor/core)
- Heavier head = more stable, less "bobblehead"
- Lighter limbs = easier to swing body around

---

### **2. LINEAR DAMPING (Resistance to Movement)**

**Current Values:**
```
Torso: 0.3
Head: 0.3
Limbs: 0.2
```

**Where to Edit:**
- `scripts/managers/physics_constants.gd` — LINEAR_DAMP_TORSO, LINEAR_DAMP_HEAD, LINEAR_DAMP_LIMB

**What It Affects:**
- Slows down straight-line movement (like air resistance or friction)
- ⬆️ Higher = Slower, more controlled, "moving through water"
- ⬇️ Lower = Faster, more chaotic, "slippery ice"
- 0 = No damping (very bouncy/wild)
- 2.0+ = Heavy damping (slow, sluggish)

**Recommended Ranges:**
- 0.1 - 1.0 for dynamic feel
- 1.0 - 2.0 for controlled feel

**Tips:**
- Use slightly higher damping on torso for stability
- Lower damping on limbs for responsiveness
- If player bounces too much, increase this

---

### **3. ANGULAR DAMPING (Resistance to Rotation)**

**Current Values:**
```
Torso: 0.5
Head: 0.1 (reduced for head tracking responsiveness)
Limbs: 0.3
```

**Where to Edit:**
- `scripts/managers/physics_constants.gd`

**What It Affects:**
- Slows down rotation/spinning
- ⬆️ Higher = Less spinning, more stable
- ⬇️ Lower = Spins more freely
- Very high (2.0+) = Almost no rotation

**Recommended Ranges:**
- 0.1 - 0.5 for free rotation
- 0.5 - 2.0 for controlled rotation

**Tips:**
- If player spins wildly, increase this
- Head has low value (0.1) to allow head tracking to work
- Higher torso angular damp = more stable posture

---

### **4. JOINT SOFTNESS (How Stretchy Connections Are)**

**Current Values:**
```
Neck Joint: 0.3
Arm Joints: 0.4
Leg Joints: 0.4
Latch Joints (dynamic): 0.05
```

**Where to Edit:**
- `scripts/managers/physics_constants.gd` — JOINT_SOFTNESS_NECK, JOINT_SOFTNESS_ARM, JOINT_SOFTNESS_LEG

**What It Affects:**
- 0 = Rigid connection (stiff, like a robot)
- 0.5 = Soft connection (stretchy, like rubber bands)
- 1.0 = Very soft (extremely floppy, might visually "tear")

**Visual Comparison:**
```
Stiff joint (0.1):     Soft joint (0.4):
    O                      O
    |  ← rigid             |\  ← stretchy
    |                      | \
   /|\                    /|  \
```

**Recommended Ranges:**
- 0.1 - 0.2 for stiff/robotic feel
- 0.3 - 0.5 for ragdoll/floppy feel
- 0.6+ very experimental (might break apart visually)

**Tips:**
- Softer = More ragdoll-y, limbs can stretch before pulling body
- Too soft = Limbs might "detach" visually or wobble too much
- Latch joints should be stiffer (0.05) for stable grip on holds
- Neck can be slightly stiffer than limbs for less bobblehead effect

---

### **5. LIMB MOVEMENT FORCE (Mouse Control Strength)**

**Current Value:**
```gdscript
// In scripts/managers/physics_constants.gd
const MOVE_FORCE = 15000.0
```

**Where to Edit:**
- `scripts/managers/physics_constants.gd` — MOVE_FORCE

**What It Affects:**
- How hard the limb pushes toward the mouse cursor
- ⬆️ Higher = Can swing body easily, very responsive
- ⬇️ Lower = Limb moves slowly, can't lift body much
- Must be high enough to overcome gravity + mass + joint constraints

**Recommended Ranges:**
- 5000 - 10000: Weak, limb barely affects body
- 10000 - 20000: Medium, can swing body if lighter
- 20000 - 40000: Strong, can easily lift and swing body
- 40000+: Very strong, might feel too twitchy

**Tips:**
- If limbs can't swing the body: Increase this
- If limbs feel too wild/uncontrollable: Decrease this or increase MAX_VELOCITY
- Heavier bodies need higher force
- Current value (15000) is tuned for current masses

---

### **6. MAX LIMB VELOCITY (Speed Limit)**

**Current Value:**
```gdscript
// In scripts/managers/physics_constants.gd
const MAX_VELOCITY = 800.0
```

**Where to Edit:**
- `scripts/managers/physics_constants.gd` — MAX_VELOCITY

**What It Affects:**
- Maximum speed limb can reach (pixels/second)
- Caps velocity to prevent wild uncontrolled movement
- ⬆️ Higher = Limb can move faster (more wild/dynamic)
- ⬇️ Lower = Limb movement capped (more controlled)

**Recommended Ranges:**
- 200 - 400: Slow, very controlled
- 400 - 600: Medium, balanced
- 600 - 1000: Fast, dynamic
- 1000+: Very fast, might feel chaotic

**Tips:**
- If limb moves too slowly: Increase this
- If limb overshoots cursor: Decrease this
- Works with MOVE_FORCE: high force + low max = snappy but controlled

---

### **7. LIMB MOVEMENT DAMPING (Speed Retention)**

**Current Value:**
```gdscript
// In scripts/managers/physics_constants.gd
const MOVE_DAMPING = 0.99
```

**Where to Edit:**
- `scripts/managers/physics_constants.gd` — MOVE_DAMPING

**What It Affects:**
- How much velocity is kept each frame (multiplier)
- 0.99 = Keep 99% of speed each frame (minimal slowdown)
- 0.90 = Keep 90% of speed (significant slowdown)
- ⬆️ Higher (closer to 1.0) = Maintains speed, feels responsive
- ⬇️ Lower (closer to 0.9) = Loses speed quickly, feels heavy

**Recommended Ranges:**
- 0.95 - 0.99: Responsive, dynamic
- 0.90 - 0.95: Controlled, damped
- Below 0.90: Very sluggish

**Tips:**
- If limb feels sluggish despite high force: Increase this (try 0.995)
- If limb overshoots and oscillates: Decrease this (try 0.95)
- Higher values = more "ice skating" feel
- Lower values = more "swimming through water" feel

---

### **8. GRAVITY SCALE**

**Current Values:**
```
ALL bodies: 1.0 (enforced by PhysicsConstants — no floating!)
```

> PhysicsConstants.GRAVITY_SCALE = 1.0 is applied to all bodies in player.gd _apply_physics_constants()

**Where to Edit:**
- `scripts/managers/physics_constants.gd`

**What It Affects:**
- Multiplier for gravity force
- 1.0 = Normal gravity (9.8 m/s² in Godot)
- 0.5 = Half gravity (floatier, moon-like)
- 2.0 = Double gravity (heavier fall)
- 0.0 = No gravity (zero-g)

**Recommended Ranges:**
- 0.8 - 1.2: Tweaked normal gravity
- 0.5 - 0.8: Floaty/moon gravity
- 1.2 - 2.0: Heavy gravity

**Tips:**
- Usually keep at 1.0 for all parts
- Can reduce slightly (0.8) for overall "moon gravity" feel
- Don't change individually unless you want weird effects
- Lower gravity = easier to climb, less urgent

---

### **9. HEAD TRACKING PARAMETERS**

**Current Values:**
```gdscript
// In scripts/managers/physics_constants.gd
const HEAD_LOOK_SPEED = 50.0
const HEAD_UPRIGHT_FORCE = 3000.0
const HEAD_MAX_LOOK_ANGLE = 80.0
```

**Where to Edit:**
- `scripts/managers/physics_constants.gd` — HEAD_LOOK_SPEED, HEAD_UPRIGHT_FORCE, HEAD_MAX_LOOK_ANGLE

**What They Affect:**
- **HEAD_LOOK_SPEED**: How fast head turns to cursor (degrees/sec multiplier)
- **HEAD_UPRIGHT_FORCE**: How strongly head returns to upright when idle
- **HEAD_MAX_LOOK_ANGLE**: Maximum rotation degrees (prevents "breaking neck")

---

## 🎮 Common Tuning Scenarios

### **Scenario: "Player is too heavy, can't lift body"**

**Problem:** Moving limbs doesn't affect body position much.

**Solutions:**
1. ⬇️ Reduce torso mass (try 2.0)
2. ⬆️ Increase MOVE_FORCE (try 20000)
3. ⬆️ Increase joint softness (try 0.5)
4. ⬇️ Reduce all masses proportionally

**Test:** Select a limb and move mouse in circles. Body should swing noticeably.

---

### **Scenario: "Player is too wild/chaotic/bouncy"**

**Problem:** Player flails around uncontrollably, hard to make precise movements.

**Solutions:**
1. ⬆️ Increase linear damping (try 0.5-1.0)
2. ⬇️ Decrease MAX_VELOCITY (try 500)
3. ⬇️ Decrease joint softness (try 0.2)
4. ⬆️ Increase angular damping (try 1.0)

**Test:** Player should settle down quickly when you stop moving mouse.

---

### **Scenario: "Player spins too much"**

**Problem:** Body rotates excessively when moving limbs.

**Solutions:**
1. ⬆️ Increase angular damping on torso (try 1.0-2.0)
2. Keep linear damping low for movement but angular high
3. Slightly increase torso mass for stability

**Test:** Body should maintain orientation better while limbs move.

---

### **Scenario: "Limbs feel disconnected/stretchy"**

**Problem:** Limbs visually separate too far from body.

**Solutions:**
1. ⬇️ Decrease joint softness (try 0.1-0.2)
2. ⬆️ Increase limb mass slightly (try 1.0-1.5)
3. Check that joints are positioned correctly

**Test:** Limbs should stay visually connected even under stress.

---

### **Scenario: "Can't generate momentum to climb"**

**Problem:** Hard to swing body upward to reach next hold.

**Solutions:**
1. ⬆️ Increase MOVE_FORCE dramatically (try 25000-40000)
2. ⬇️ Decrease all body masses
3. ⬆️ Increase joint softness (more swing)
4. ⬇️ Reduce damping values
5. ⬇️ Reduce gravity slightly (try 0.8)

**Test:** Should be able to "throw" body upward by rapid limb movement.

---

### **Scenario: "Movement feels sluggish/laggy"**

**Problem:** Limbs respond slowly to mouse movement.

**Solutions:**
1. ⬆️ Increase MOVE_FORCE
2. ⬆️ Increase DAMPING (closer to 1.0, like 0.995)
3. ⬇️ Reduce linear damping on limbs
4. ⬆️ Increase MAX_VELOCITY

**Test:** Limb should quickly follow cursor movements.

---

### **Scenario: "Limbs overshoot cursor"**

**Problem:** Limbs swing past where you point, oscillate.

**Solutions:**
1. ⬇️ Decrease MAX_VELOCITY (try 400-600)
2. ⬇️ Decrease DAMPING in limb.gd (try 0.95)
3. ⬆️ Increase limb linear damping (try 0.5)
4. Add larger dead zone (currently 10.0 pixels, try 20.0)

**Test:** Limb should smoothly approach cursor and stop.

---

## 🔬 Physics Relationships

### **Force vs Mass**
```
acceleration = force / mass

Example:
MOVE_FORCE = 15000
Limb mass = 0.8
acceleration = 15000 / 0.8 = 18750 pixels/s²

If you double mass to 1.6:
acceleration = 15000 / 1.6 = 9375 pixels/s² (half as responsive!)

Solution: Also double force to maintain same feel.
```

### **Damping over Time**
```
Each frame, velocity is multiplied by damping:

DAMPING = 0.99
Frame 1: velocity = 100
Frame 2: velocity = 100 * 0.99 = 99
Frame 3: velocity = 99 * 0.99 = 98.01
...
After 100 frames: velocity ≈ 36.6 (lost 63.4%)

DAMPING = 0.95
After 100 frames: velocity ≈ 0.6 (lost 99.4%!)

Higher damping = velocity persists longer
```

### **Joint Softness Effect**
```
Stiff joint (0.1):
- Limb moves → Body moves immediately
- Tight connection
- Less swing/momentum

Soft joint (0.4):
- Limb moves → stretches → builds tension → Body moves
- Elastic connection
- More swing/momentum
- Creates "wind-up" effect
```

---

## 🔧 Experimentation Workflow

### **Quick Tweaks (Godot Editor)**
1. Open `scenes/player/Player.tscn`
2. Click body parts or joints in scene tree
3. Change values in Inspector
4. Press F6 (run scene) to test immediately
5. No need to close/reopen Godot!
6. Iterate quickly

### **Script Changes (Requires Reload)**
1. Edit `scripts/managers/physics_constants.gd`
2. Save file
3. In Godot: Scene → Reload Saved Scene (Ctrl+R)
4. Or close and reopen scene
5. Test changes

### **Recommended Order:**
1. **Mass** - Get the weight feeling right first
2. **Joint softness** - Get the floppiness/stiffness right
3. **MOVE_FORCE** - Get the power/responsiveness right
4. **Damping** - Fine-tune the control feel
5. **MAX_VELOCITY** - Cap speed if needed
6. **DAMPING constant** - Final tweaks for smoothness

---

## 📈 Current Tuning Philosophy

**Goal:** Light, floppy ragdoll that can swing its body around dramatically for momentum-based climbing.

**Basis:** Based on 75kg experienced climber with moderate grip strength.

**Achieved By:**
- Mass scale 0.1x preserves proportions while keeping gameplay viable
- Body total: 7.5 game-kg (was 6.2)
- Soft joints (0.3-0.4 vs original 0.1)
- High movement force (15000 vs original 500)
- Low damping (0.2-0.3 linear, 0.3-0.5 angular)
- High velocity cap (800 vs original 200)

**Feel:** Like "QWOP" or "Getting Over It" - intentionally unwieldy but controllable with practice. Player must learn to generate momentum through limb movement.

---

## 🎯 Target Feelings

**Good Signs:**
- Can swing body by moving a free limb
- Latching to hold stops wild movement
- Can "throw" body upward to reach distant hold
- Movement has momentum and weight
- Feels challenging but fair

**Bad Signs:**
- Limb movement doesn't affect body (too heavy)
- Can't control direction (too chaotic)
- Limbs feel disconnected (joints too soft)
- Everything feels sluggish (too much damping)
- Too easy/floaty (masses too low, gravity too weak)

---

## 💾 Backup Before Tuning

**Recommended:** Save current values before major changes!

Current Working Values (as of last session):
```gdscript
// Masses (75kg climber at 0.1x scale)
Torso: 3.8
Head: 0.5
Arms: 0.4 each
Legs: 1.2 each
Total: 7.5

// Damping
Torso/Head linear: 0.3
Torso angular: 0.5
Head angular: 0.1
Limbs linear: 0.2
Limbs angular: 0.3

// Joints
Neck: 0.3
Arms/Legs: 0.4

// Movement (PhysicsConstants)
MOVE_FORCE: 15000.0
MAX_VELOCITY: 800.0
MOVE_DAMPING: 0.99

// All constants in: scripts/managers/physics_constants.gd
```

---

Happy tuning! Start with small changes and test frequently.
