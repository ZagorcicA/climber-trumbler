# Boulder QTE - Technical Architecture

Complete technical breakdown of systems, data flow, and implementation details.

---

## 🏗️ System Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Level1 (Scene)                        │
│  ┌────────────┐  ┌──────────────┐  ┌─────────────────┐ │
│  │   Floor    │  │  Player      │  │  Holds (x4+)    │ │
│  │(StaticBody)│  │  (Container) │  │  (StaticBody)   │ │
│  └────────────┘  └──────┬───────┘  └─────────────────┘ │
│                         │                                │
└─────────────────────────┼────────────────────────────────┘
                          │
           ┌──────────────┼──────────────┐
           │              │              │
  ┌────────▼─────────┐ ┌─▼────────┐ ┌───▼─────────────┐
  │ PhysicsConstants │ │  Input   │ │  Physics        │
  │  (Singleton)     │ │  Manager │ │  Engine         │
  │                  │ │(Singleton│ │                  │
  │ - Body masses    │ │          │ │ - Gravity        │
  │ - Damping vals   │ │- Mouse   │ │ - Collisions     │
  │ - Forces/joints  │ │- Keys    │ │ - Joints         │
  │ - SSOT physics   │ │- SSOT    │ │                  │
  └──────────────────┘ └──────────┘ └──────────────────┘
```

---

## 📦 Core Systems

### **1. Player System**

**Components:**
- Player.tscn (Node2D container)
  - Torso (RigidBody2D) - main body
  - Head (RigidBody2D) - with head.gd script
  - LeftArm, RightArm, LeftLeg, RightLeg (Limb instances)
  - NeckJoint, LeftArmJoint, RightArmJoint, LeftLegJoint, RightLegJoint (PinJoint2D)

**Script: player.gd**
```
Responsibilities:
- Manage limbs array [left_arm, right_arm, left_leg, right_leg]
- Handle limb selection (keys 1-4)
- Coordinate latch/detach actions
- Update head tracking state
- Query InputManager for all input

Key Functions:
- select_limb(index) - Sets active limb, updates visuals
- get_selected_limb() - Returns currently selected limb or null
- _handle_limb_selection() - Processes number key input
- _handle_limb_actions() - Processes Space/X for latch/detach
- _update_head_tracking() - Tells head to track cursor or stabilize
```

**Data Flow:**
```
User Input → InputManager → Player._process()
                                    ↓
                          _handle_limb_selection()
                                    ↓
                            select_limb(index)
                                    ↓
                          Limb.set_selected(true)
                                    ↓
                          Visual highlight shown
```

---

### **2. Limb System**

**Components:**
- Limb.tscn (RigidBody2D)
  - UpperSegment (CollisionShape2D) - upper part collision
  - LowerSegment (CollisionShape2D) - lower part collision
  - UpperVisual, LowerVisual (ColorRect) - visual representation
  - GrabArea (Area2D) - detects nearby holds
    - GrabZone (CollisionShape2D) - circle radius 15
  - SelectionHighlight (ColorRect) - yellow highlight when selected

**Script: limb.gd**
```
Responsibilities:
- Apply physics forces to follow mouse cursor
- Detect nearby holds via GrabArea signals
- Manage latch/detach to holds
- Visual feedback for selection state

Key Variables:
- is_selected: bool - Currently selected by player
- is_latched: bool - Attached to a hold
- target_position: Vector2 - Mouse position to move toward
- latch_joint: PinJoint2D - Dynamic joint when latched
- nearby_holds: Array - Holds currently in detection range
- current_hold - Reference to attached hold

Key Functions:
- set_selected(bool) - Updates selection state and visual
- get_nearest_hold() - Returns closest hold in nearby_holds
- latch_to_hold(hold) - Creates PinJoint2D to attach
- detach_from_hold() - Destroys joint and releases
- _move_toward_target() - Applies forces toward mouse
- _on_hold_detected(area) - Adds hold to nearby_holds
- _on_hold_lost(area) - Removes hold from nearby_holds
```

**Physics Movement Algorithm:**
```gdscript
func _physics_process(delta):
    if is_selected and not is_latched:
        target_position = get_global_mouse_position()
        _move_toward_target()

func _move_toward_target():
    direction = (target_position - global_position).normalized()
    distance = global_position.distance_to(target_position)

    if distance > 10.0:  # Dead zone
        force = direction * MOVE_FORCE  # 15000.0
        apply_central_force(force)

    # Velocity capping
    if linear_velocity.length() > MAX_VELOCITY:  # 800.0
        linear_velocity = linear_velocity.normalized() * MAX_VELOCITY

    # Damping
    linear_velocity *= DAMPING  # 0.99
```

**Latch Mechanism:**
```
Player presses Space
    ↓
Player.gd: InputManager.latch_just_pressed = true
    ↓
Player.gd: selected.latch_to_hold(nearest_hold)
    ↓
Limb.gd: latch_to_hold(hold)
    ↓
Creates PinJoint2D dynamically
    - Position: hold.global_position
    - node_a: self (limb)
    - node_b: hold
    - softness: 0.05 (fairly rigid)
    ↓
Limb.is_latched = true
Hold.attach_limb(self) called
    ↓
Hold shows green indicator
Limb stops following mouse
```

---

### **3. Hold System**

**Components:**
- Hold.tscn (StaticBody2D)
  - HoldVisual (ColorRect) - red 30x30 square
  - DetectionArea (Area2D) - circle radius 20
    - DetectionShape (CollisionShape2D)
  - AttachedIndicator (ColorRect) - green glow when limb attached
  - (Optional) CollisionShape2D - makes hold solid

**Script: hold.gd**
```
Responsibilities:
- Track which limbs are attached
- Show/hide visual indicator
- Provide attach position

Key Variables:
- attached_limbs: Array - List of limbs latched to this hold

Key Functions:
- attach_limb(limb) - Add limb to array, update visual
- detach_limb(limb) - Remove limb from array, update visual
- get_attach_position() - Returns global_position
- _update_visual_state() - Shows indicator if limbs > 0
```

**Collision Configuration:**
- StaticBody2D: layer 4, mask 0 (doesn't move, doesn't collide)
- DetectionArea: layer 4, mask 1 (detects player bodies)
- Limb GrabArea: layer 1, mask 4 (detects holds)

---

### **4. InputManager System**

**Type:** Autoload Singleton (always loaded, globally accessible)

**Script: input_manager.gd**
```
Responsibilities:
- SINGLE SOURCE OF TRUTH for all input state
- Process input every frame
- Provide mouse world position accounting for camera

Key Variables:
- mouse_position: Vector2 - Screen space mouse pos
- latch_just_pressed: bool - Space pressed this frame
- detach_just_pressed: bool - X pressed this frame
- limb_selection_pressed: int - 0-3 for limbs, -1 if none

Key Functions:
- _process(delta) - Reads Input, updates state variables
- get_mouse_world_position() - Converts to world coords via camera

Access Pattern:
- Any script: InputManager.latch_just_pressed
- Any script: InputManager.get_mouse_world_position()
```

**Why Singleton?**
- Prevents multiple scripts polling Input independently
- Consistent state across all systems in same frame
- Easy to add input remapping in future
- Single point to add input logging/debugging

---

### **PhysicsConstants System**

**Type:** Autoload Singleton (always loaded, globally accessible, loads first)

**Script: physics_constants.gd**
```
Responsibilities:
- SINGLE SOURCE OF TRUTH for all physics values
- Centralizes body masses, positions, damping, joints, movement forces, stamina config
- Based on realistic 75kg experienced climber (0.1x mass scale for gameplay)
- Enforces gravity_scale = 1.0 on all bodies (no floating)

Constant Categories:
- World & Gravity (GRAVITY, PIXELS_PER_METER, GRAVITY_SCALE)
- Climber Profile (CLIMBER_MASS_KG, MASS_SCALE, GRIP_STRENGTH)
- Body Masses (MASS_HEAD, MASS_TORSO, MASS_ARM, MASS_LEG)
- Body Positions (POS_HEAD, POS_LEFT_ARM, etc.)
- Body Sizes (SIZE_TORSO, SIZE_HEAD_RADIUS, etc.)
- Damping (LINEAR_DAMP_*, ANGULAR_DAMP_*)
- Joint Properties (JOINT_SOFTNESS_*, JOINT_POS_*)
- Movement Forces (MOVE_FORCE, MAX_VELOCITY, MOVE_DAMPING)
- Standing Support (STAND_SUPPORT_FORCE, STAND_UPRIGHT_TORQUE)
- Head Tracking (HEAD_LOOK_SPEED, HEAD_MAX_LOOK_ANGLE)
- Stamina (MAX_STAMINA, BASE_DRAIN_RATE, position multipliers)
- Hold Difficulty (HOLD_DRAIN_EASY/MEDIUM/HARD)

Access Pattern:
- Any script: PhysicsConstants.CONSTANT_NAME
```

---

### **5. Hold Color System**

**Script: hold.gd (attached to Hold.tscn)**
```
Responsibilities:
- Track which limbs are attached
- Set visual color based on difficulty
- Show/hide visual indicator

Color Configuration (from DIFFICULTY_COLORS dict):
- EASY: Green/yellow
- MEDIUM: Orange
- HARD: Red

The hold color is set programmatically in _ready() based on the hold_difficulty export variable.
```

---

### **6. Level System**

**Script: level.gd (attached to LevelEasy, LevelMedium, LevelHard)**
```
Responsibilities:
- Manage level-specific logic
- Handle restart input
- (Future) Check win/lose conditions

Key Functions:
- restart_level() - Reloads current scene
- check_win_condition() - (Not implemented)
```

---

## 🔄 Data Flow Diagrams

### **Limb Selection Flow**
```
Frame N:
User presses "2" key
    ↓
InputManager._process()
    - Detects Input.is_action_just_pressed("select_limb_2")
    - Sets limb_selection_pressed = 1
    ↓
Player._process()
    - Calls _handle_limb_selection()
    - Reads InputManager.limb_selection_pressed
    - Calls select_limb(1)  # Right arm
    ↓
Player.select_limb(1)
    - Deselects previous: limbs[old_index].set_selected(false)
    - Selects new: limbs[1].set_selected(true)
    ↓
RightArm.set_selected(true)
    - Sets is_selected = true
    - Makes SelectionHighlight.visible = true
    ↓
Player._update_head_tracking()
    - Checks if selected limb is not latched
    - Calls head.track_position(mouse_pos)

Next Frame:
RightArm._physics_process()
    - is_selected = true, is_latched = false
    - Gets mouse position
    - Applies forces toward mouse
    - Limb moves!
```

### **Latch to Hold Flow**
```
Limb moving near hold...

Frame N:
Hold.DetectionArea overlaps Limb.GrabArea
    ↓
Signal: area_entered(Limb.GrabArea)
    ↓
Hold.DetectionArea emits signal
    ↓
Limb._on_hold_detected(area)
    - Checks area.is_in_group("holds")
    - Adds hold to nearby_holds array
    - Prints: "Hold detected!"

Frame N+5:
User presses Space
    ↓
InputManager._process()
    - Sets latch_just_pressed = true
    ↓
Player._handle_limb_actions()
    - Gets selected limb
    - Reads InputManager.latch_just_pressed
    - Gets nearest_hold = limb.get_nearest_hold()
    - Calls limb.latch_to_hold(nearest_hold)
    ↓
Limb.latch_to_hold(hold)
    - Creates new PinJoint2D
    - Adds to parent (Player node)
    - Sets joint.node_a = limb path
    - Sets joint.node_b = hold path
    - Sets joint.global_position = hold position
    - Sets is_latched = true
    - Calls hold.attach_limb(self)
    ↓
Hold.attach_limb(limb)
    - Adds limb to attached_limbs
    - Calls _update_visual_state()
    - AttachedIndicator.visible = true (green glow)
    ↓
Next physics frame:
    - Physics engine processes PinJoint2D
    - Limb is constrained to hold position
    - Limb no longer follows mouse (is_latched = true)
```

---

## 📁 File Organization

**Scenes are organized by type:**
```
scenes/
├── player/         # Player and limb components
│   ├── Player.tscn
│   └── Limb.tscn
├── environment/    # Environment elements (holds, floor)
│   └── Hold.tscn
├── levels/         # Complete level scenes
│   ├── LevelEasy.tscn
│   ├── LevelMedium.tscn
│   └── LevelHard.tscn
└── ui/             # User interface scenes
    ├── StaminaBar.tscn
    └── StartScreen.tscn
```

**Scripts are organized by module:**
```
scripts/
├── player/         # Player controller, limb physics, head tracking
│   ├── player.gd
│   ├── limb.gd
│   └── head.gd
├── environment/    # Hold logic, level management
│   ├── hold.gd
│   └── level.gd
├── managers/       # Autoload singletons
│   ├── physics_constants.gd
│   ├── input_manager.gd
│   └── stamina_manager.gd
└── ui/             # UI controllers
```

---

## 🎯 Scene Hierarchy

### **Player.tscn**
```
Player (Node2D) [player.gd]
├── Torso (RigidBody2D)
│   ├── TorsoShape (CollisionShape2D) - Rectangle 60x100
│   └── TorsoVisual (ColorRect) - Blue
├── Head (RigidBody2D) [head.gd]
│   ├── HeadShape (CollisionShape2D) - Circle r=20
│   └── HeadVisual (ColorRect) - Tan
├── NeckJoint (PinJoint2D)
│   - Connects: Torso ↔ Head
│   - Position: (0, -50)
├── LeftArm (Limb instance)
│   - Position: (-38, -10)
├── LeftArmJoint (PinJoint2D)
│   - Connects: Torso ↔ LeftArm
│   - Position: (-30, -50)
├── RightArm (Limb instance)
│   - Position: (38, -10)
├── RightArmJoint (PinJoint2D)
│   - Connects: Torso ↔ RightArm
│   - Position: (30, -50)
├── LeftLeg (Limb instance)
│   - Position: (-22, 90)
├── LeftLegJoint (PinJoint2D)
│   - Connects: Torso ↔ LeftLeg
│   - Position: (-22, 50)
├── RightLeg (Limb instance)
│   - Position: (22, 90)
└── RightLegJoint (PinJoint2D)
    - Connects: Torso ↔ RightLeg
    - Position: (22, 50)
```

### **Limb.tscn**
```
Limb (RigidBody2D) [limb.gd]
├── UpperSegment (CollisionShape2D) - Rectangle 16x40 @ (0, -20)
├── UpperVisual (ColorRect) - Brown
├── LowerSegment (CollisionShape2D) - Rectangle 16x40 @ (0, 20)
├── LowerVisual (ColorRect) - Dark brown
├── GrabArea (Area2D) @ (0, 40)
│   └── GrabZone (CollisionShape2D) - Circle r=15
└── SelectionHighlight (ColorRect) - Yellow, initially hidden
```

### **Hold.tscn**
```
Hold (StaticBody2D) [hold.gd]
├── HoldVisual (ColorRect) - Red 30x30
├── DetectionArea (Area2D)
│   └── DetectionShape (CollisionShape2D) - Circle r=20
├── AttachedIndicator (ColorRect) - Green, initially hidden
└── (Optional) CollisionShape2D - Makes hold solid
```

### **LevelEasy/LevelMedium/LevelHard.tscn**
```
LevelEasy (Node2D) [level.gd]
├── Floor (StaticBody2D) @ (576, 600)
│   ├── FloorShape (CollisionShape2D) - Rectangle 2000x100
│   └── FloorVisual (ColorRect) - Brown
├── Player (Player instance) @ (576, 200)
├── Hold1 (Hold instance) @ (user-positioned)
├── Hold2 (Hold instance) @ (user-positioned)
├── Hold3 (Hold instance) @ (user-positioned)
├── Hold4 (Hold instance) @ (user-positioned)
└── Camera2D @ (576, 324)
    - Zoom: (0.8, 0.8)
```

---

## 🔧 Physics Configuration Details

### **RigidBody2D Properties**

All values centralized in PhysicsConstants singleton.
Arms and legs have different masses (set at runtime by player.gd).

**Torso:**
- Mass: 3.8
- Linear Damp: 0.3
- Angular Damp: 0.5
- Collision Layer: 1
- Collision Mask: 7 (layers 1+2+3)
- Gravity Scale: 1.0

**Head:**
- Mass: 0.5
- Linear Damp: 0.3
- Angular Damp: 0.1
- Collision Layer: 1
- Collision Mask: 7
- Gravity Scale: 1.0
- Script: head.gd

**Arms (each):**
- Mass: 0.4
- Linear Damp: 0.2
- Angular Damp: 0.3
- Collision Layer: 1
- Collision Mask: 7
- Gravity Scale: 1.0
- Script: limb.gd

**Legs (each):**
- Mass: 1.2
- Linear Damp: 0.2
- Angular Damp: 0.3
- Collision Layer: 1
- Collision Mask: 7
- Gravity Scale: 1.0
- Script: limb.gd

### **PinJoint2D Properties**

All joints use similar configuration:
- Softness: 0.3-0.4 (stretchy for ragdoll feel)
- node_a: Parent body (usually Torso)
- node_b: Child body (Head or Limb)
- Position: At anatomical joint location

**Latch joints (dynamically created):**
- Softness: 0.05 (more rigid for stable grip)
- node_a: Limb
- node_b: Hold
- Position: At hold's attach position

---

## 🎨 Visual Feedback Systems

### **Selection Indicator**
- Yellow semi-transparent ColorRect
- Wraps around limb (slightly larger)
- z_index: -1 (behind limb)
- Toggled by limb.set_selected()

### **Hold Attachment Indicator**
- Green semi-transparent ColorRect
- Wraps around hold (slightly larger)
- z_index: -1
- Shown when attached_limbs.size() > 0

### **Debug Prints**
All debug print statements have been removed from production code.

---

## 🔐 Design Patterns Used

### **Singleton Pattern**
- PhysicsConstants and InputManager are autoloaded
- Globally accessible as `PhysicsConstants.CONSTANT_NAME` and `InputManager.property`
- Single instance for entire game lifetime
- PhysicsConstants loads first as the single source of truth for all physics values

### **Component Pattern**
- Limb.tscn is a self-contained component
- Reusable across multiple instances
- Encapsulates all limb-specific logic

### **Observer Pattern (via Signals)**
- GrabArea uses area_entered/area_exited signals
- Limb observes these signals to track nearby holds
- Godot's signal system provides loose coupling

### **State Pattern**
- Limb has states: idle, selected, latched
- Behavior changes based on current state
- is_selected and is_latched flags control flow

---

## 📝 Code Style & Conventions

- **Indentation:** Tabs (Godot default)
- **Naming:**
  - Variables: snake_case
  - Functions: snake_case
  - Constants: UPPER_SNAKE_CASE
  - Files: snake_case.gd
  - Scenes: PascalCase.tscn
- **Comments:**
  - File headers explain script purpose
  - Function docstrings for public functions
  - Inline comments for complex logic
- **Organization:**
  - @onready variables at top
  - Regular variables after
  - Constants after variables
  - _ready() first
  - _process()/_physics_process() second
  - Public functions third
  - Private functions last (prefixed with _)

---

## 🚀 Performance Considerations

### **Current State**
- Very lightweight (simple 2D shapes)
- No complex rendering
- Physics calculation is main cost

### **Optimization Opportunities**
- Disable physics on off-screen objects (future)
- Pool hold instances if many levels (future)
- Limit debug prints in production

### **Known Bottlenecks**
- None currently - runs smoothly

---

This architecture supports the design goals while remaining flexible for future expansion.
