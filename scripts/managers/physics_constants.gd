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

# SPLIT LIMB MASSES (upper + lower = original total)
const MASS_UPPER_ARM: float = 0.6       # Shoulder to elbow
const MASS_FOREARM: float = 0.5          # Elbow to hand (0.6+0.5=1.1=MASS_ARM)
const MASS_THIGH: float = 2.2            # Hip to knee
const MASS_SHIN: float = 1.65            # Knee to foot (2.2+1.65=3.85=MASS_LEG)

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
const JOINT_SOFTNESS_ELBOW: float = 0.15   # Stiffer than shoulder — bones don't stretch
const JOINT_SOFTNESS_KNEE: float = 0.15
const JOINT_SOFTNESS_LATCH: float = 0.05   # Rigid grip on holds

# Joint positions (relative to torso center)
const JOINT_POS_NECK: Vector2 = Vector2(0, -50)
const JOINT_POS_LEFT_ARM: Vector2 = Vector2(-30, -50)
const JOINT_POS_RIGHT_ARM: Vector2 = Vector2(30, -50)
const JOINT_POS_LEFT_LEG: Vector2 = Vector2(-22, 50)
const JOINT_POS_RIGHT_LEG: Vector2 = Vector2(22, 50)

# Elbow/knee joint positions (relative to Player origin)
const JOINT_POS_LEFT_ELBOW: Vector2 = Vector2(-30, -10)
const JOINT_POS_RIGHT_ELBOW: Vector2 = Vector2(30, -10)
const JOINT_POS_LEFT_KNEE: Vector2 = Vector2(-22, 90)
const JOINT_POS_RIGHT_KNEE: Vector2 = Vector2(22, 90)

# Upper limb initial positions
const POS_UPPER_LEFT_ARM: Vector2 = Vector2(-30, -30)
const POS_UPPER_RIGHT_ARM: Vector2 = Vector2(30, -30)
const POS_UPPER_LEFT_LEG: Vector2 = Vector2(-22, 70)
const POS_UPPER_RIGHT_LEG: Vector2 = Vector2(22, 70)

# ============================================================
# MOVEMENT FORCES
# ============================================================
const MOVE_FORCE: float = 15000.0         # Force limb applies toward mouse
const MOVE_FORCE_EXHAUSTED: float = 5000.0 # Force at 0 stamina (sluggish response)
const MAX_VELOCITY: float = 800.0          # Limb speed cap (pixels/s)
const MAX_VELOCITY_EXHAUSTED: float = 350.0 # Speed cap at 0 stamina
const MOVE_DAMPING: float = 0.92           # Velocity retention per frame (lower = faster oscillation decay)
const MOVE_DEAD_ZONE: float = 10.0         # Pixels before force applies
const MOVE_FORCE_RAMP: float = 150.0       # Pixels over which force ramps from 0→full

# ============================================================
# STANDING SUPPORT
# ============================================================
const STAND_SUPPORT_FORCE: float = 4500.0
const STAND_UPRIGHT_TORQUE: float = 6000.0
const STAND_DAMPING: float = 0.85

# ============================================================
# HEAD TRACKING
# ============================================================
const HEAD_LOOK_SPEED: float = 50.0
const HEAD_UPRIGHT_FORCE: float = 3000.0   # Reserved for future use
const HEAD_LOOK_ANGLE_DOWN: float = 60.0   # Degrees — looking down (toward holds below)
const HEAD_LOOK_ANGLE_UP: float = 40.0     # Degrees — looking up (limited by neck)
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
const COM_TORQUE_STRENGTH_EXHAUSTED: float = 16000.0  # Torque at 0 stamina (violent pendulum)
const COM_TORQUE_DAMPING_EXHAUSTED: float = 0.995     # Damping at 0 stamina (almost no friction)
const COM_TORQUE_RAMP_EXHAUSTED: float = 0.3          # Cube-root-like — tiny offset = huge torque

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
const COM_DOT_RADIUS_EXHAUSTED: float = 16.0          # Dot: 8→16px when tired
const COM_RING_MIN_RADIUS_EXHAUSTED: float = 20.0     # Ring inner: 12→20px
const COM_RING_MAX_RADIUS_EXHAUSTED: float = 28.0     # Ring outer: 16→28px
const COM_TRAIL_DOT_SCALE_EXHAUSTED: float = 1.8      # Trail dots 1.8x bigger when tired
const COM_TRAIL_LENGTH: int = 10
const COM_TRAIL_SAMPLE_INTERVAL: int = 3

# HORIZONTAL OVERSHOOT (pendulum feel when tired)
const COM_OVERSHOOT_GAIN: float = 1.2                # CoM velocity → overshoot amount (wild)
const COM_OVERSHOOT_DECAY: float = 0.985             # Per-frame return to center (very slow decay)
const COM_OVERSHOOT_MAX: float = 120.0               # Max horizontal drift (px)

# PENDULUM ROPE VISUAL
const COM_ROPE_WIDTH_MAX: float = 3.0                # Rope thickness at 0 stamina
const COM_ANCHOR_RADIUS: float = 5.0                 # Anchor dot at ideal CoM position

# COM INERTIA (smoothing — lower = more sluggish, less mouse-reactive)
const COM_SMOOTHING: float = 0.08                    # Exponential lerp weight per frame

# ============================================================
# JOINT ANGLE LIMITS (code-enforced, degrees)
# ============================================================
const SHOULDER_ANGLE_MIN: float = -160.0    # Max forward/upward reach
const SHOULDER_ANGLE_MAX: float = 160.0     # Max backward reach (blocked behind back)
const JOINT_LIMIT_TORQUE: float = 8000.0    # Corrective torque strength at limit
const JOINT_LIMIT_DAMPING: float = 0.8      # Angular velocity damping when hitting limit

# Elbow/knee angle limits (symmetric — character can face either way)
const ELBOW_ANGLE_MIN: float = -150.0
const ELBOW_ANGLE_MAX: float = 150.0
const KNEE_ANGLE_MIN: float = -135.0
const KNEE_ANGLE_MAX: float = 135.0
const ELBOW_KNEE_LIMIT_TORQUE: float = 3000.0
const ELBOW_KNEE_LIMIT_DAMPING: float = 0.7

# Standing knee spring (prevents collapse when standing)
const KNEE_STRAIGHTEN_TORQUE: float = 6000.0   # Simulates quadriceps locking knee
const THIGH_UPRIGHT_TORQUE: float = 5000.0     # Keeps thighs vertical when standing
const KNEE_STRAIGHTEN_DAMPING: float = 0.85
const THIGH_UPRIGHT_DAMPING: float = 0.85

