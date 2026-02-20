extends Node

# PhysicsConstants Singleton (SSOT for all physics values)
# Centralizes all physics constants for a 75kg experienced climber.
#
# Real-world basis: 75kg climber, moderate grip strength (~45 kg-force)
# Game scale: 100 pixels = 1 meter, mass scale factor 0.1x
# gravity_scale = 0.3 on torso for floaty climbing feel

# ============================================================
# WORLD & GRAVITY
# ============================================================
const GRAVITY: float = 980.0              # pixels/s² (Godot default, 9.8 m/s² at 100px/m)
const PIXELS_PER_METER: float = 100.0
const GRAVITY_SCALE: float = 0.55         # Torso gravity scale — heavier sloppy feel

# ============================================================
# CLIMBER PROFILE
# ============================================================
const CLIMBER_MASS_KG: float = 75.0       # Real-world mass
const MASS_SCALE: float = 0.1             # Game mass = real mass * this
const GRIP_STRENGTH: float = 45.0         # kg-force, experienced moderate grip

# ============================================================
# BODY PART MASSES (game-scale, proportional to 75kg human)
# ============================================================
const MASS_HEAD: float = 1.8
const MASS_TORSO: float = 9.5
const MASS_ARM: float = 1.1
const MASS_LEG: float = 3.85
# Total: 1.8 + 9.5 + (1.1 * 2) + (3.85 * 2) = 21.2

# ============================================================
# BODY PART POSITIONS (relative to torso center, pixels)
# ============================================================
const POS_HEAD: Vector2 = Vector2(0, -60)
const POS_LEFT_ARM: Vector2 = Vector2(-38, -10)
const POS_RIGHT_ARM: Vector2 = Vector2(38, -10)
const POS_LEFT_LEG: Vector2 = Vector2(-22, 90)
const POS_RIGHT_LEG: Vector2 = Vector2(22, 90)

# ============================================================
# BODY PART SIZES (pixels)
# ============================================================
const SIZE_TORSO: Vector2 = Vector2(60, 100)
const SIZE_HEAD_RADIUS: float = 20.0
const SIZE_LIMB_SEGMENT: Vector2 = Vector2(16, 40)
const SIZE_GRAB_RADIUS: float = 15.0

# ============================================================
# DAMPING VALUES
# ============================================================
# Linear damping (resistance to movement)
const LINEAR_DAMP_TORSO: float = 1.0
const LINEAR_DAMP_HEAD: float = 0.3
const LINEAR_DAMP_LIMB: float = 1.0

# Angular damping (resistance to rotation)
const ANGULAR_DAMP_TORSO: float = 0.5
const ANGULAR_DAMP_HEAD: float = 0.1      # Low for head tracking responsiveness
const ANGULAR_DAMP_LIMB: float = 0.3

# ============================================================
# JOINT PROPERTIES (PinJoint2D softness)
# ============================================================
const JOINT_SOFTNESS_NECK: float = 0.3
const JOINT_SOFTNESS_ARM: float = 0.4
const JOINT_SOFTNESS_LEG: float = 0.4
const JOINT_SOFTNESS_LATCH: float = 0.05   # Rigid grip on holds

# Joint positions (relative to torso center)
const JOINT_POS_NECK: Vector2 = Vector2(0, -50)
const JOINT_POS_LEFT_ARM: Vector2 = Vector2(-30, -50)
const JOINT_POS_RIGHT_ARM: Vector2 = Vector2(30, -50)
const JOINT_POS_LEFT_LEG: Vector2 = Vector2(-22, 50)
const JOINT_POS_RIGHT_LEG: Vector2 = Vector2(22, 50)

# ============================================================
# MOVEMENT FORCES
# ============================================================
const MOVE_FORCE: float = 15000.0         # Force limb applies toward mouse
const MOVE_FORCE_EXHAUSTED: float = 5000.0 # Force at 0 stamina (sluggish response)
const MAX_VELOCITY: float = 800.0          # Limb speed cap (pixels/s)
const MAX_VELOCITY_EXHAUSTED: float = 350.0 # Speed cap at 0 stamina
const MOVE_DAMPING: float = 0.99           # Velocity retention per frame
const MOVE_DEAD_ZONE: float = 10.0         # Pixels before force applies

# ============================================================
# STANDING SUPPORT
# ============================================================
const STAND_SUPPORT_FORCE: float = 2500.0
const STAND_UPRIGHT_TORQUE: float = 5000.0
const STAND_DAMPING: float = 0.85

# ============================================================
# HEAD TRACKING
# ============================================================
const HEAD_LOOK_SPEED: float = 50.0
const HEAD_UPRIGHT_FORCE: float = 3000.0   # Reserved for future use
const HEAD_MAX_LOOK_ANGLE: float = 80.0    # Degrees
const HEAD_UPRIGHT_CORRECTION: float = 10.0

# ============================================================
# STAMINA CONFIGURATION
# ============================================================
const MAX_STAMINA: float = 100.0
const BASE_DRAIN_RATE: float = 15.0        # Per second when latched
const BASE_REGEN_RATE: float = 10.0        # Per second when not latched
const MIN_LATCH_STAMINA: float = 5.0       # Can't latch below this
const STAMINA_WARNING_THRESHOLD: float = 30.0

# ============================================================
# STAMINA POSITION MULTIPLIERS
# ============================================================
const MULT_FREE_FALLING: float = 2.0       # 0 limbs — fast regen
const MULT_DESPERATE: float = 3.0          # 1 limb — very high drain
const MULT_ARMS_ONLY: float = 2.5          # 2 arms only — high drain
const MULT_MODERATE: float = 1.5           # 1 arm + 1 leg
const MULT_STABLE: float = 1.0             # 2+ mixed limbs
const MULT_EFFICIENT: float = 0.7          # 2 legs only
const MULT_RESTING: float = 1.5            # 3+ limbs — regen
const MULT_GROUNDED: float = 1.2           # Floor-supported regen

# ============================================================
# HOLD DIFFICULTY DRAIN MULTIPLIERS
# ============================================================
const HOLD_DRAIN_EASY: float = 0.25        # Jug holds, low grip demand
const HOLD_DRAIN_MEDIUM: float = 1.5       # Moderate grip demand
const HOLD_DRAIN_HARD: float = 2.5         # Crimps/slopers, high grip demand

# ============================================================
# TOUCH INPUT
# ============================================================
const TOUCH_SELECT_RADIUS: float = 70.0    # px — tap detection radius (generous for fat fingers)

# ============================================================
# CENTER OF MASS PHYSICS
# ============================================================
const COM_TORQUE_STRENGTH: float = 5500.0    # Barn-door torque when hanging off-center
const COM_TORQUE_DAMPING: float = 0.94       # Angular velocity retention (higher = more swing)
const COM_MAX_OFFSET: float = 130.0          # Pixels — offset where torque saturates
const COM_TORQUE_RAMP: float = 1.0           # Exponent (1.0=linear — reactive to small offsets)

# STAMINA → CoM COUPLING
const COM_STAMINA_SAG_MAX: float = 80.0              # Max downward CoM offset (px) at 0 stamina
const COM_TORQUE_STRENGTH_EXHAUSTED: float = 8500.0  # Torque at 0 stamina (stronger pendulum)
const COM_TORQUE_DAMPING_EXHAUSTED: float = 0.97     # Damping at 0 stamina (barely dampened)

# STAMINA COLORS (shared by stamina bar + CoM display)
const COM_COLOR_FRESH: Color = Color(0.2, 0.9, 0.4, 0.85)     # Green — full stamina
const COM_COLOR_TIRED: Color = Color(1.0, 0.7, 0.2, 0.85)     # Orange — mid stamina
const COM_COLOR_CRITICAL: Color = Color(0.9, 0.1, 0.1, 0.85)  # Red — low stamina

# ============================================================
# CENTER OF MASS VISUALIZATION
# ============================================================
const COM_LINE_WIDTH: float = 2.0
const COM_LINE_COLOR: Color = Color(0.0, 0.9, 0.9, 0.35)
const COM_JOINT_RADIUS: float = 4.0
const COM_JOINT_COLOR: Color = Color(0.0, 1.0, 1.0, 0.6)
const COM_DOT_RADIUS: float = 8.0
const COM_DOT_COLOR: Color = Color(1.0, 0.2, 0.4, 0.85)
const COM_RING_COLOR: Color = Color(1.0, 0.2, 0.4, 0.3)
const COM_RING_MIN_RADIUS: float = 12.0
const COM_RING_MAX_RADIUS: float = 16.0
const COM_CROSSHAIR_COLOR: Color = Color(1.0, 1.0, 1.0, 0.3)
const COM_CROSSHAIR_SIZE: float = 12.0
const COM_TRAIL_LENGTH: int = 10
const COM_TRAIL_SAMPLE_INTERVAL: int = 3

