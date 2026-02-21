extends Node2D

# Player controller for ragdoll climber
# Manages limb selection and input coordination

@onready var torso = $Torso
@onready var head = $Head
@onready var left_arm = $LeftArm
@onready var right_arm = $RightArm
@onready var left_leg = $LeftLeg
@onready var right_leg = $RightLeg
@onready var upper_left_arm = $UpperLeftArm
@onready var upper_right_arm = $UpperRightArm
@onready var upper_left_leg = $UpperLeftLeg
@onready var upper_right_leg = $UpperRightLeg

var limbs: Array = []
var touch_limb_map: Dictionary = {}      # finger_index → limb_index
var _prev_touch_fingers: Array = []      # previous frame's active finger indices
var keyboard_selected_indices: Array = []  # keyboard-controlled limb indices
var _prev_limb_keys_held: Array = []
var torso_on_ground: bool = false  # Tracks if torso is touching floor/ground
var legs_on_ground: int = 0  # Count of legs touching the floor

# CoM physics data (set in _ready)
var _com_bodies: Array = []
var _com_masses: Array = []
var _com_total: float = 0.0

func _ready():
	# Register all limbs in order: 0=LeftArm, 1=RightArm, 2=LeftLeg, 3=RightLeg
	limbs = [left_arm, right_arm, left_leg, right_leg]

	# Set split limb masses (upper + lower = original total)
	upper_left_arm.mass = PhysicsConstants.MASS_UPPER_ARM
	upper_right_arm.mass = PhysicsConstants.MASS_UPPER_ARM
	left_arm.mass = PhysicsConstants.MASS_FOREARM
	right_arm.mass = PhysicsConstants.MASS_FOREARM
	upper_left_leg.mass = PhysicsConstants.MASS_THIGH
	upper_right_leg.mass = PhysicsConstants.MASS_THIGH
	left_leg.mass = PhysicsConstants.MASS_SHIN
	right_leg.mass = PhysicsConstants.MASS_SHIN

	# Build CoM body/mass arrays for the manager (10 bodies)
	_com_bodies = [
		torso, head,
		upper_left_arm, left_arm, upper_right_arm, right_arm,
		upper_left_leg, left_leg, upper_right_leg, right_leg,
	]
	_com_masses = [
		PhysicsConstants.MASS_TORSO, PhysicsConstants.MASS_HEAD,
		PhysicsConstants.MASS_UPPER_ARM, PhysicsConstants.MASS_FOREARM,
		PhysicsConstants.MASS_UPPER_ARM, PhysicsConstants.MASS_FOREARM,
		PhysicsConstants.MASS_THIGH, PhysicsConstants.MASS_SHIN,
		PhysicsConstants.MASS_THIGH, PhysicsConstants.MASS_SHIN,
	]
	for m in _com_masses:
		_com_total += m

	# Wire upper_segment references so limbs distribute force through the chain
	left_arm.upper_segment = upper_left_arm
	right_arm.upper_segment = upper_right_arm
	left_leg.upper_segment = upper_left_leg
	right_leg.upper_segment = upper_right_leg

	# Connect to stamina depletion signal
	StaminaManager.stamina_depleted.connect(_on_stamina_depleted)

	# Connect to torso collision signals for grounded detection
	torso.body_entered.connect(_on_torso_body_entered)
	torso.body_exited.connect(_on_torso_body_exited)

	# Connect leg collision signals for standing support
	left_leg.body_entered.connect(_on_leg_body_entered)
	left_leg.body_exited.connect(_on_leg_body_exited)
	right_leg.body_entered.connect(_on_leg_body_entered)
	right_leg.body_exited.connect(_on_leg_body_exited)

func _process(delta):
	_handle_limb_selection()
	_handle_limb_actions()
	_update_head_tracking()
	_update_stamina(delta)

func _physics_process(_delta):
	# Feed CoM manager every frame
	CenterOfMassManager.update_com(_com_bodies, _com_masses, _com_total)

	var latched_positions: Array = []
	for limb in limbs:
		if limb.is_latched and limb.current_hold and is_instance_valid(limb.current_hold):
			latched_positions.append(limb.current_hold.global_position)
	CenterOfMassManager.update_support(latched_positions)

	CenterOfMassManager.update_stamina_ratio(StaminaManager.current_stamina / PhysicsConstants.MAX_STAMINA)
	CenterOfMassManager.update_effective_com()

	_clamp_torso_above_holds()
	_enforce_joint_limits()

	if legs_on_ground > 0:
		# Upward support force (like "leg muscles")
		var support_multiplier = 1.0 if legs_on_ground >= 2 else 0.6
		torso.apply_central_force(Vector2(0, -PhysicsConstants.STAND_SUPPORT_FORCE * support_multiplier))

		# Upright torque correction (proportional controller)
		torso.apply_torque(-torso.rotation * PhysicsConstants.STAND_UPRIGHT_TORQUE)

		# Horizontal damping to prevent sliding
		torso.linear_velocity.x *= PhysicsConstants.STAND_DAMPING

		# Straighten knees and keep thighs vertical
		_straighten_legs_for_standing()
	elif CenterOfMassManager.support_count > 0:
		_apply_com_torque()


func _apply_com_torque():
	var offset = CenterOfMassManager.com_offset_horizontal
	# Normalize by max offset, clamp to [-1, 1]
	var normalized = clampf(offset / PhysicsConstants.COM_MAX_OFFSET, -1.0, 1.0)
	# Stamina scaling — tired = stronger pendulum, less damping, sub-linear ramp
	var ratio = CenterOfMassManager.stamina_ratio
	var ramp = lerp(PhysicsConstants.COM_TORQUE_RAMP_EXHAUSTED, PhysicsConstants.COM_TORQUE_RAMP, ratio)
	# Apply power curve (sqrt when exhausted — small offsets create big torque)
	var factor = sign(normalized) * pow(abs(normalized), ramp)
	var strength = lerp(PhysicsConstants.COM_TORQUE_STRENGTH_EXHAUSTED, PhysicsConstants.COM_TORQUE_STRENGTH, ratio)
	var damping = lerp(PhysicsConstants.COM_TORQUE_DAMPING_EXHAUSTED, PhysicsConstants.COM_TORQUE_DAMPING, ratio)
	torso.apply_torque(factor * strength)
	torso.angular_velocity *= damping

func _enforce_joint_limits():
	# Shoulders: upper arms relative to torso
	_limit_angle_pair(upper_left_arm, torso, PhysicsConstants.SHOULDER_ANGLE_MIN, PhysicsConstants.SHOULDER_ANGLE_MAX, PhysicsConstants.JOINT_LIMIT_TORQUE, PhysicsConstants.JOINT_LIMIT_DAMPING)
	_limit_angle_pair(upper_right_arm, torso, PhysicsConstants.SHOULDER_ANGLE_MIN, PhysicsConstants.SHOULDER_ANGLE_MAX, PhysicsConstants.JOINT_LIMIT_TORQUE, PhysicsConstants.JOINT_LIMIT_DAMPING)
	# Elbows: forearms relative to upper arms
	_limit_angle_pair(left_arm, upper_left_arm, PhysicsConstants.ELBOW_ANGLE_MIN, PhysicsConstants.ELBOW_ANGLE_MAX, PhysicsConstants.ELBOW_KNEE_LIMIT_TORQUE, PhysicsConstants.ELBOW_KNEE_LIMIT_DAMPING)
	_limit_angle_pair(right_arm, upper_right_arm, PhysicsConstants.ELBOW_ANGLE_MIN, PhysicsConstants.ELBOW_ANGLE_MAX, PhysicsConstants.ELBOW_KNEE_LIMIT_TORQUE, PhysicsConstants.ELBOW_KNEE_LIMIT_DAMPING)
	# Knees: shins relative to thighs
	_limit_angle_pair(left_leg, upper_left_leg, PhysicsConstants.KNEE_ANGLE_MIN, PhysicsConstants.KNEE_ANGLE_MAX, PhysicsConstants.ELBOW_KNEE_LIMIT_TORQUE, PhysicsConstants.ELBOW_KNEE_LIMIT_DAMPING)
	_limit_angle_pair(right_leg, upper_right_leg, PhysicsConstants.KNEE_ANGLE_MIN, PhysicsConstants.KNEE_ANGLE_MAX, PhysicsConstants.ELBOW_KNEE_LIMIT_TORQUE, PhysicsConstants.ELBOW_KNEE_LIMIT_DAMPING)

func _limit_angle_pair(child: RigidBody2D, parent: RigidBody2D, min_deg: float, max_deg: float, limit_torque: float, limit_damping: float):
	var relative_angle = rad_to_deg(child.rotation - parent.rotation)
	# Normalize to [-180, 180]
	relative_angle = fmod(relative_angle + 180.0, 360.0) - 180.0

	var correction = 0.0
	if relative_angle < min_deg:
		correction = min_deg - relative_angle
	elif relative_angle > max_deg:
		correction = max_deg - relative_angle

	if correction != 0.0:
		child.apply_torque(deg_to_rad(correction) * limit_torque)
		child.angular_velocity *= limit_damping

func _straighten_legs_for_standing():
	for pair in [[upper_left_leg, left_leg], [upper_right_leg, right_leg]]:
		var thigh = pair[0]
		var shin = pair[1]
		# Knee spring: push shin rotation toward thigh rotation (straight leg)
		var knee_angle = shin.rotation - thigh.rotation
		shin.apply_torque(-knee_angle * PhysicsConstants.KNEE_STRAIGHTEN_TORQUE)
		shin.angular_velocity *= PhysicsConstants.KNEE_STRAIGHTEN_DAMPING
		# Keep thigh vertical with damping
		thigh.apply_torque(-thigh.rotation * PhysicsConstants.THIGH_UPRIGHT_TORQUE)
		thigh.angular_velocity *= PhysicsConstants.THIGH_UPRIGHT_DAMPING
		# Also push shin toward vertical (prevents splayed-out legs)
		shin.apply_torque(-shin.rotation * PhysicsConstants.THIGH_UPRIGHT_TORQUE * 0.5)

func _clamp_torso_above_holds():
	# Prevent cartwheeling: when arms are latched, the torso can't rise above
	# the hold point. This stops free limbs (legs) from pulling the body over.
	var arm_hold_y_sum = 0.0
	var arm_hold_count = 0

	for i in [0, 1]:  # Arms only (indices 0=LeftArm, 1=RightArm)
		var limb = limbs[i]
		if limb.is_latched and limb.current_hold and is_instance_valid(limb.current_hold):
			arm_hold_y_sum += limb.current_hold.global_position.y
			arm_hold_count += 1

	if arm_hold_count == 0:
		return

	# Allow torso up to just below the hold (20px ≈ chest-to-hand distance)
	var hold_y = arm_hold_y_sum / arm_hold_count
	var min_torso_y = hold_y - 20.0

	if torso.global_position.y < min_torso_y:
		# Hard clamp: snap torso back to the ceiling and kill upward velocity
		torso.global_position.y = min_torso_y
		if torso.linear_velocity.y < 0:
			torso.linear_velocity.y = 0

func _handle_limb_selection():
	_handle_keyboard_selection()
	_handle_touch_selection()
	_update_limb_targets()

func _handle_keyboard_selection():
	var keys_held = InputManager.limb_keys_held

	# Rising edge: newly pressed keys → detach if latched, select
	for key in keys_held:
		if key not in _prev_limb_keys_held:
			if limbs[key].is_latched:
				limbs[key].detach_from_hold()
			if key not in keyboard_selected_indices:
				keyboard_selected_indices.append(key)
			limbs[key].set_selected(true)

	# Falling edge: released keys → try latch, deselect
	for key in _prev_limb_keys_held:
		if key not in keys_held:
			var limb = limbs[key]
			if not limb.is_latched and StaminaManager.can_latch():
				var nearest_hold = limb.get_nearest_hold()
				if nearest_hold:
					limb.latch_to_hold(nearest_hold)
			limb.set_selected(false)
			limb.force_divisor = 1
			keyboard_selected_indices.erase(key)

	_prev_limb_keys_held = keys_held.duplicate()

func _handle_touch_selection():
	var curr_fingers = InputManager.active_touches.keys()

	# New fingers (rising edge) — find and bind limbs
	for finger in curr_fingers:
		if finger not in _prev_touch_fingers and finger not in touch_limb_map:
			var world_pos = InputManager.screen_to_world(InputManager.active_touches[finger])
			var excluded = touch_limb_map.values()
			excluded.append_array(keyboard_selected_indices)
			var nearest = _find_nearest_limb(world_pos, excluded)
			if nearest >= 0:
				if limbs[nearest].is_latched:
					limbs[nearest].detach_from_hold()
				limbs[nearest].set_selected(true)
				touch_limb_map[finger] = nearest

	# Released fingers (falling edge) — latch and unbind
	for finger in _prev_touch_fingers:
		if finger not in curr_fingers and finger in touch_limb_map:
			var limb_index = touch_limb_map[finger]
			var limb = limbs[limb_index]
			if not limb.is_latched and StaminaManager.can_latch():
				var nearest_hold = limb.get_nearest_hold()
				if nearest_hold:
					limb.latch_to_hold(nearest_hold)
			limb.set_selected(false)
			touch_limb_map.erase(finger)

	_prev_touch_fingers = curr_fingers.duplicate()

func _update_limb_targets():
	# Touch-controlled limbs
	for finger in touch_limb_map:
		var limb_index = touch_limb_map[finger]
		var screen_pos = InputManager.active_touches.get(finger)
		if screen_pos:
			limbs[limb_index].target_position = InputManager.screen_to_world(screen_pos)

	# Keyboard-controlled limbs all follow mouse — share force to prevent flying
	var mouse_pos = InputManager.get_mouse_world_position()
	var active_keyboard_count = 0
	for limb_index in keyboard_selected_indices:
		if not limbs[limb_index].is_latched:
			active_keyboard_count += 1
	for limb_index in keyboard_selected_indices:
		limbs[limb_index].target_position = mouse_pos
		limbs[limb_index].force_divisor = max(1, active_keyboard_count)

func _handle_limb_actions():
	# Handle latch and detach actions (keyboard Space/X) for all keyboard-selected limbs
	if keyboard_selected_indices.is_empty():
		return

	if InputManager.latch_just_pressed and StaminaManager.can_latch():
		for limb_index in keyboard_selected_indices:
			var limb = limbs[limb_index]
			if not limb.is_latched:
				var nearest_hold = limb.get_nearest_hold()
				if nearest_hold:
					limb.latch_to_hold(nearest_hold)

	if InputManager.detach_just_pressed:
		for limb_index in keyboard_selected_indices:
			limbs[limb_index].detach_from_hold()

func get_selected_limb():
	if not keyboard_selected_indices.is_empty():
		return limbs[keyboard_selected_indices[0]]
	return null

func _find_nearest_limb(world_pos: Vector2, exclude: Array = []) -> int:
	var best_index: int = -1
	var best_distance: float = PhysicsConstants.TOUCH_SELECT_RADIUS
	for i in range(limbs.size()):
		if i in exclude:
			continue
		var distance = world_pos.distance_to(limbs[i].global_position)
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index

func _update_head_tracking():
	var track_pos = null

	# Prefer touch targets
	if not touch_limb_map.is_empty():
		var finger = touch_limb_map.keys()[0]
		var screen_pos = InputManager.active_touches.get(finger)
		if screen_pos:
			track_pos = InputManager.screen_to_world(screen_pos)
	# Fall back to keyboard/mouse
	elif not keyboard_selected_indices.is_empty():
		for idx in keyboard_selected_indices:
			if not limbs[idx].is_latched:
				track_pos = InputManager.get_mouse_world_position()
				break

	if track_pos:
		head.track_position(track_pos)
	else:
		head.stop_tracking()

func _is_grounded() -> bool:
	return torso_on_ground or legs_on_ground > 0

func _update_stamina(delta: float):
	# Count latched arms (indices 0-1) and gather hold difficulty multipliers
	var arms_latched = 0
	var hold_drain_multiplier = 0.0
	var total_latched = 0

	for limb in limbs:
		if limb.is_latched:
			total_latched += 1
			# Get drain multiplier from the hold this limb is attached to
			if limb.current_hold and is_instance_valid(limb.current_hold):
				hold_drain_multiplier += limb.current_hold.get_drain_multiplier()
			else:
				hold_drain_multiplier += 1.0  # Default if no valid hold

	if limbs[0].is_latched:  # Left arm
		arms_latched += 1
	if limbs[1].is_latched:  # Right arm
		arms_latched += 1

	# Count latched legs (indices 2-3)
	var legs_latched = 0
	if limbs[2].is_latched:  # Left leg
		legs_latched += 1
	if limbs[3].is_latched:  # Right leg
		legs_latched += 1

	# Average hold difficulty multiplier (1.0 if no limbs latched)
	var avg_hold_multiplier = hold_drain_multiplier / total_latched if total_latched > 0 else 1.0

	# Update StaminaManager with current configuration, grounded state, and hold difficulty
	StaminaManager.update_stamina(delta, arms_latched, legs_latched, _is_grounded(), avg_hold_multiplier)

func _on_stamina_depleted():
	# Detach all latched limbs
	for limb in limbs:
		if limb.is_latched:
			limb.detach_from_hold()

func _on_torso_body_entered(body: Node):
	if body is StaticBody2D:
		if body.collision_layer & 2:
			torso_on_ground = true

func _on_torso_body_exited(body: Node):
	if body is StaticBody2D:
		if body.collision_layer & 2:
			torso_on_ground = false

func _on_leg_body_entered(body: Node):
	if body is StaticBody2D and body.collision_layer & 2:
		legs_on_ground += 1

func _on_leg_body_exited(body: Node):
	if body is StaticBody2D and body.collision_layer & 2:
		legs_on_ground = max(0, legs_on_ground - 1)
