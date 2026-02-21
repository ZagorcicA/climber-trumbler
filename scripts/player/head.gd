extends RigidBody2D

# Head controller that tracks cursor when limbs are selected
# Maintains upright position when idle

var target_rotation: float = 0.0
var is_tracking: bool = false


func _ready():
	pass

func _physics_process(delta):
	if is_tracking:
		# Head looks at cursor
		_track_cursor(delta)
	else:
		# Head tries to stay upright
		_stabilize_upright(delta)

func track_position(world_position: Vector2):
	"""Make head look toward a specific world position"""
	is_tracking = true

	# Calculate angle from head to target
	var direction = world_position - global_position
	target_rotation = direction.angle() + PI/2  # Adjust because sprite faces UP by default (not right)


	# Clamp with asymmetric limits (positive = looking down, negative = looking up)
	var current_angle = rotation
	var angle_diff = wrapf(target_rotation - current_angle, -PI, PI)
	var max_down_rad = deg_to_rad(PhysicsConstants.HEAD_LOOK_ANGLE_DOWN)
	var max_up_rad = deg_to_rad(PhysicsConstants.HEAD_LOOK_ANGLE_UP)

	if angle_diff > max_down_rad:
		target_rotation = current_angle + max_down_rad
	elif angle_diff < -max_up_rad:
		target_rotation = current_angle - max_up_rad

func stop_tracking():
	"""Stop tracking and return to idle (upright) behavior"""
	is_tracking = false

func _track_cursor(delta):
	"""Smoothly rotate head toward target rotation"""
	var angle_diff = wrapf(target_rotation - rotation, -PI, PI)

	# Directly set angular velocity to rotate toward target
	var desired_angular_vel = angle_diff * PhysicsConstants.HEAD_LOOK_SPEED
	angular_velocity = desired_angular_vel


func _stabilize_upright(delta):
	"""Apply force to keep head pointing up (0 degrees)"""
	var upright_angle = 0.0  # 0 degrees = pointing up
	var angle_diff = wrapf(upright_angle - rotation, -PI, PI)

	# Directly set angular velocity to rotate toward upright
	var desired_angular_vel = angle_diff * PhysicsConstants.HEAD_UPRIGHT_CORRECTION
	angular_velocity = desired_angular_vel


func wrapf(value: float, min_val: float, max_val: float) -> float:
	"""Wrap angle to range [-PI, PI]"""
	var range_size = max_val - min_val
	return min_val + fmod(fmod(value - min_val, range_size) + range_size, range_size)
