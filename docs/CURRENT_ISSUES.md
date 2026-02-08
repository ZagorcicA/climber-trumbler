# Boulder QTE - Current Issues

Active problems that need resolution before continuing development.

---

## 🚨 CRITICAL: Head Tracking System Not Working

**Priority:** HIGH
**Status:** Unresolved
**Blocks:** Phase 4 completion
**Files Affected:**
- `scripts/player/head.gd`
- `scenes/player/Player.tscn` (Head node)

---

### 📋 Problem Description

The head tracking system is fully implemented and being called correctly, but the head does not rotate at all. It remains in its physics-driven "ragdoll" state (hanging down) regardless of tracking commands.

**Expected Behavior:**
1. When limb is selected and not latched → Head should rotate to look at cursor
2. When no limb selected or limb is latched → Head should rotate to upright (0°)

**Actual Behavior:**
- Head remains in ragdoll state
- Hangs downward due to gravity
- Does not respond to tracking or upright commands
- No visible rotation occurs

---

### 🔍 Debug Information

#### **Console Output (Example):**
```
Head physics - is_tracking: true rotation: -2.37697315216064
Applying tracking torque: -110.181073314797 angle_diff: -0.00440724293259
Head physics - is_tracking: true rotation: -2.36082625389099
Applying tracking torque: -513.85353005613 angle_diff: -0.02055414120225
Head physics - is_tracking: true rotation: -2.3525869846344
Applying tracking torque: -1018.13564694608 angle_diff: -0.04072542587784
```

**Analysis:**
- `is_tracking` correctly switches between true/false ✓
- Script functions are being called every frame ✓
- Rotation value is updating slightly (from -2.37 to -2.35) ✓
- `angle_diff` is very small (-0.004 to -0.04 radians) ⚠️
- Torque values are in hundreds, not thousands ⚠️
- Head stuck around -2.37 radians ≈ -136° (hanging down-left)

**Key Observation:** The head appears "stuck" at around -136° and makes only tiny movements, despite code attempting to rotate it.

---

### 🧪 What's Been Tried

#### **Attempt 1: Increased Torque Forces**
```gdscript
// Initial values
LOOK_SPEED = 8.0
UPRIGHT_FORCE = 500.0
Torque multiplier = 100

// Changed to
LOOK_SPEED = 50.0  (6x increase)
UPRIGHT_FORCE = 3000.0  (6x increase)
Torque multiplier = 500  (5x increase)
```
**Result:** No change ✗

#### **Attempt 2: Reduced Head Angular Damping**
```
Head angular_damp: 0.5 → 0.1
```
**Reasoning:** Reduce resistance to rotation
**Result:** No change ✗

#### **Attempt 3: Direct Velocity Control**
Changed from torque-based to direct velocity:
```gdscript
// Old approach:
apply_torque(angle_diff * LOOK_SPEED * 500)

// New approach:
angular_velocity = angle_diff * LOOK_SPEED
```
**Reasoning:** Bypass torque system entirely
**Result:** No change ✗

#### **Attempt 4: Changed Angle Calculation**
```gdscript
// Tried both:
target_rotation = direction.angle() - PI/2
target_rotation = direction.angle() + PI/2
```
**Reasoning:** Maybe coordinate system interpretation wrong
**Result:** No change ✗

---

### 💡 Current Theories

#### **Theory 1: Neck Joint Override**
The NeckJoint (PinJoint2D connecting Head to Torso) might be:
- Applying counter-forces that override angular velocity
- Too stiff (softness 0.3) to allow free rotation
- Constantly pulling head back to "hanging" position

**Test:** Temporarily disable/remove NeckJoint and see if head rotates

#### **Theory 2: Angle Calculation Error**
The target_rotation calculation might be fundamentally wrong:
- Godot's 2D coordinate system: +X right, +Y down, 0° = right
- "Up" should be -PI/2 (270° or -90°), not 0°
- Current upright target might be pointing right instead of up

**Test:** Print target_rotation value and verify it's actually -PI/2 when upright

#### **Theory 3: Physics Constraint Interference**
Something in the physics system might be preventing rotation:
- Head colliding with torso (collision blocking rotation)
- Some other constraint or joint we forgot about
- RigidBody2D.lock_rotation might be enabled (unlikely but check)

**Test:** Check Head node for any locked rotation settings

#### **Theory 4: Execution Order Issue**
angular_velocity might be set, but then immediately overridden:
- Physics engine resets it each frame based on joints
- Some other script modifying head
- Joint forces applied after our velocity setting

**Test:** Set angular_velocity in _integrate_forces() instead of _physics_process()

#### **Theory 5: Wrong Rotation Reference**
Maybe we should be controlling rotation differently:
- Use global_rotation instead of rotation
- Apply forces in different space (global vs local)
- Use look_at() function instead of angular velocity

**Test:** Try global_rotation or look_at() approach

---

### 📊 Current Code State

**head.gd (relevant sections):**

```gdscript
var is_tracking: bool = false
var target_rotation: float = 0.0

const LOOK_SPEED = 50.0
const UPRIGHT_FORCE = 3000.0
const MAX_LOOK_ANGLE = 80.0

func _physics_process(delta):
    print("Head physics - is_tracking: ", is_tracking, " rotation: ", rotation)
    if is_tracking:
        _track_cursor(delta)
    else:
        _stabilize_upright(delta)

func track_position(world_position: Vector2):
    is_tracking = true
    var direction = world_position - global_position
    target_rotation = direction.angle() + PI/2  # Currently using +PI/2

func _track_cursor(delta):
    var angle_diff = wrapf(target_rotation - rotation, -PI, PI)
    var desired_angular_vel = angle_diff * LOOK_SPEED
    angular_velocity = desired_angular_vel
    print("Tracking - angle_diff: ", angle_diff, " setting angular_vel to: ", desired_angular_vel)

func _stabilize_upright(delta):
    var upright_angle = 0.0  # Target: 0 degrees
    var angle_diff = wrapf(upright_angle - rotation, -PI, PI)
    var desired_angular_vel = angle_diff * 10.0
    angular_velocity = desired_angular_vel
    print("Upright - Current rotation: ", rotation, " angle_diff: ", angle_diff)
```

**Player.tscn Head configuration:**
```
[node name="Head" type="RigidBody2D"]
position = Vector2(0, -60)
collision_mask = 7
mass = 2.0  (user may have changed to 5.0)
linear_damp = 0.3
angular_damp = 0.1
script = ExtResource("3_head")
```

**Neck Joint configuration:**
```
[node name="NeckJoint" type="PinJoint2D"]
position = Vector2(0, -50)
node_a = NodePath("../Torso")
node_b = NodePath("../Head")
softness = 0.3
```

---

### 🔧 Recommended Debug Steps

**Step 1: Verify Angle Calculation**
Add print to see actual target_rotation value:
```gdscript
func track_position(world_position: Vector2):
    is_tracking = true
    var direction = world_position - global_position
    target_rotation = direction.angle() + PI/2
    print("Target angle: ", target_rotation, " (", rad_to_deg(target_rotation), " degrees)")
```

**Step 2: Test Without Neck Joint**
Temporarily disable neck joint to isolate head:
```gdscript
func _ready():
    var neck_joint = get_parent().get_node("NeckJoint")
    if neck_joint:
        neck_joint.queue_free()  # Remove joint temporarily
```

**Step 3: Try Direct Rotation**
Bypass physics completely as a test:
```gdscript
func _process(delta):  # Not _physics_process
    if is_tracking:
        rotation = lerp_angle(rotation, target_rotation, delta * 5.0)
    else:
        rotation = lerp_angle(rotation, 0.0, delta * 5.0)
```

**Step 4: Check Coordinate System**
Verify Godot's 2D rotation conventions:
- 0° = pointing right (+X)
- 90° = pointing down (+Y)
- -90° or 270° = pointing up (-Y)

Maybe upright should be -PI/2, not 0?

**Step 5: Use _integrate_forces()**
Try applying rotation in physics callback:
```gdscript
func _integrate_forces(state):
    if is_tracking:
        var angle_diff = wrapf(target_rotation - rotation, -PI, PI)
        state.angular_velocity = angle_diff * LOOK_SPEED
```

**Step 6: Check for Conflicts**
Verify head has no other scripts or constraints:
- No RotationConstraint2D or similar
- No other scripts modifying rotation
- lock_rotation is false

---

### 📝 Code Locations

**Files to investigate:**
- `scripts/player/head.gd` - Main head tracking logic
- `scripts/player/player.gd:66-77` - Calls track_position() and stop_tracking()
- `scenes/player/Player.tscn:34-41` - Head RigidBody2D configuration
- `scenes/player/Player.tscn:54-58` - NeckJoint configuration

**Key functions:**
- `head.gd:track_position()` - Sets tracking mode and target angle
- `head.gd:_track_cursor()` - Applies tracking rotation
- `head.gd:_stabilize_upright()` - Applies upright rotation
- `player.gd:_update_head_tracking()` - Decides when to track

---

### 🎯 Success Criteria

Head tracking will be considered working when:
1. ✓ Head visibly rotates to look at cursor when limb selected
2. ✓ Head returns to upright (pointing up) when idle
3. ✓ Movement is smooth, not jerky
4. ✓ No extreme oscillation or spinning
5. ✓ Works consistently across different player positions

---

### 🔗 Related Files

See also:
- `ARCHITECTURE.md` - Head system architecture section
- `IMPLEMENTATION_LOG.md` - Full history of head tracking attempts
- `PHYSICS_TUNING_GUIDE.md` - Physics parameter reference

---

### 💬 Additional Notes

**User's Goal:**
"I want the head to look toward where the player is placing their limb, so the character appears focused on what they're doing. When idle, head should be upright, not flopping around."

**Why It Matters:**
- Adds personality to the character
- Improves game feel
- Helps player understand character's "attention"
- Makes character feel alive, not just a ragdoll

**Not Critical for Core Gameplay:**
- Game is playable without head tracking
- All other systems working
- Could potentially skip this feature
- But adds significant polish and character

---

### 🚀 When This is Fixed

After head tracking works:
1. Remove debug print statements
2. Fine-tune LOOK_SPEED and UPRIGHT_FORCE for best feel
3. Test with different player orientations
4. Document final solution in IMPLEMENTATION_LOG.md
5. Move to Phase 5: Stamina System

---

**Last Updated:** End of current development session
**Next Action:** Debug angle calculation and neck joint interaction

---

## 🟢 Non-Critical Issues

*(None currently - all other systems working as expected)*

---

End of current issues document.
