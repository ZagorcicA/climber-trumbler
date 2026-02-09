extends RigidBody2D

# Individual limb controller
# Handles physics movement, selection state, and hold attachment

@onready var grab_area = $GrabArea
@onready var selection_highlight = $SelectionHighlight

var is_selected: bool = false
var is_latched: bool = false
var any_limb_latched: bool = false  # Set by player.gd each frame
var target_position: Vector2 = Vector2.ZERO
var latch_joint: PinJoint2D = null
var nearby_holds: Array = []
var current_hold = null  # Reference to the hold we're attached to


func _ready():
	# Connect area signals to detect nearby holds
	grab_area.area_entered.connect(_on_hold_detected)
	grab_area.area_exited.connect(_on_hold_lost)

func _physics_process(_delta):
	# Rotation: selected limbs track mouse, others stabilize
	if is_selected:
		_rotate_toward_mouse()
	else:
		_stabilize_rotation()

	# Movement: only in position mode, when selected and not latched
	if not InputManager.is_rotation_mode and is_selected and not is_latched:
		target_position = get_global_mouse_position()
		_move_toward_target()

func _move_toward_target():
	var direction = (target_position - global_position).normalized()
	var distance = global_position.distance_to(target_position)

	if distance > PhysicsConstants.MOVE_DEAD_ZONE:
		if any_limb_latched:
			# When ANY limb is latched, allow full directional movement
			# (the latched limb acts as a pivot/anchor)
			var force = direction * PhysicsConstants.MOVE_FORCE_ATTACHED
			apply_central_force(force)
		else:
			# When NO limbs are latched, HORIZONTAL ONLY
			# Vertical movement comes only from gravity and ground support
			var horizontal_force = Vector2(direction.x * PhysicsConstants.MOVE_FORCE_HORIZONTAL, 0.0)
			apply_central_force(horizontal_force)

	# Limit velocity to prevent wild movements
	if linear_velocity.length() > PhysicsConstants.MAX_VELOCITY:
		linear_velocity = linear_velocity.normalized() * PhysicsConstants.MAX_VELOCITY

	# Apply damping for more controlled movement
	linear_velocity *= PhysicsConstants.MOVE_DAMPING

func _rotate_toward_mouse():
	var mouse_pos = get_global_mouse_position()
	var direction = mouse_pos - global_position
	var target_rot = direction.angle() - PI / 2  # Limb tip points DOWN (+Y) at rotation 0

	# Clamp rotation to prevent unnatural twisting
	var angle_diff = _wrap_angle(target_rot - rotation)
	var max_angle_rad = deg_to_rad(PhysicsConstants.LIMB_MAX_LOOK_ANGLE)

	if abs(angle_diff) > max_angle_rad:
		angle_diff = sign(angle_diff) * max_angle_rad

	angular_velocity = angle_diff * PhysicsConstants.LIMB_LOOK_SPEED

func _stabilize_rotation():
	var angle_diff = _wrap_angle(0.0 - rotation)
	angular_velocity = angle_diff * PhysicsConstants.LIMB_UPRIGHT_CORRECTION

func _wrap_angle(value: float) -> float:
	var range_size = 2 * PI
	return -PI + fmod(fmod(value + PI, range_size) + range_size, range_size)

func set_selected(selected: bool):
	is_selected = selected
	selection_highlight.visible = selected

func get_nearest_hold():
	if nearby_holds.is_empty():
		return null

	# Find closest hold
	var closest_hold = null
	var closest_distance = INF

	for hold in nearby_holds:
		if hold and is_instance_valid(hold):
			var distance = global_position.distance_to(hold.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_hold = hold

	return closest_hold

func latch_to_hold(hold):
	if is_latched or not hold:
		return false

	# Create pin joint to attach limb to hold
	latch_joint = PinJoint2D.new()
	get_parent().add_child(latch_joint)
	latch_joint.global_position = hold.get_attach_position()
	latch_joint.node_a = get_path()
	latch_joint.node_b = hold.get_path()
	latch_joint.softness = PhysicsConstants.JOINT_SOFTNESS_LATCH

	# Store reference and notify hold
	current_hold = hold
	hold.attach_limb(self)

	is_latched = true
	return true

func detach_from_hold():
	if not is_latched:
		return

	# Notify hold before detaching
	if current_hold and is_instance_valid(current_hold):
		current_hold.detach_limb(self)
		current_hold = null

	# Remove pin joint
	if latch_joint and is_instance_valid(latch_joint):
		latch_joint.queue_free()
		latch_joint = null

	is_latched = false

func _on_hold_detected(area):
	# Area entered grab zone
	if area.is_in_group("holds"):
		var hold = area.get_parent()
		nearby_holds.append(hold)

func _on_hold_lost(area):
	# Area left grab zone
	if area.is_in_group("holds"):
		var hold = area.get_parent()
		nearby_holds.erase(hold)
