extends Node2D

# Player controller for ragdoll climber
# Manages limb selection and input coordination

@onready var torso = $Torso
@onready var head = $Head
@onready var left_arm = $LeftArm
@onready var right_arm = $RightArm
@onready var left_leg = $LeftLeg
@onready var right_leg = $RightLeg

var limbs: Array = []
var selected_limb_index: int = -1
var selection_source: String = "keyboard"  # "keyboard" or "touch"
var _was_touch_active: bool = false
var _prev_limb_key_held: int = -1
var torso_on_ground: bool = false  # Tracks if torso is touching floor/ground
var legs_on_ground: int = 0  # Count of legs touching the floor

func _ready():
	# Register all limbs in order: 1=LeftArm, 2=RightArm, 3=LeftLeg, 4=RightLeg
	limbs = [left_arm, right_arm, left_leg, right_leg]

	# No limb selected by default — player selects via touch
	selected_limb_index = -1

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
	if legs_on_ground <= 0:
		return

	# Upward support force (like "leg muscles")
	var support_multiplier = 1.0 if legs_on_ground >= 2 else 0.6
	torso.apply_central_force(Vector2(0, -PhysicsConstants.STAND_SUPPORT_FORCE * support_multiplier))

	# Upright torque correction (proportional controller)
	torso.apply_torque(-torso.rotation * PhysicsConstants.STAND_UPRIGHT_TORQUE)

	# Horizontal damping to prevent sliding
	torso.linear_velocity.x *= PhysicsConstants.STAND_DAMPING

func _handle_limb_selection():
	# KEYBOARD: hold-to-select with edge detection
	var key_held = InputManager.limb_key_held
	if key_held >= 0 and key_held != _prev_limb_key_held:
		# Key just pressed → detach if latched, then select
		if limbs[key_held].is_latched:
			limbs[key_held].detach_from_hold()
		select_limb(key_held)
		selection_source = "keyboard"
	elif key_held < 0 and _prev_limb_key_held >= 0 and selection_source == "keyboard":
		# Key just released → try latch, then deselect
		var selected = get_selected_limb()
		if selected and not selected.is_latched and StaminaManager.can_latch():
			var nearest_hold = selected.get_nearest_hold()
			if nearest_hold:
				selected.latch_to_hold(nearest_hold)
		select_limb(-1)
	_prev_limb_key_held = key_held

	# TOUCH: detect finger-down (rising edge)
	var touch_active = InputManager.is_touch_active
	if touch_active and not _was_touch_active:
		var touch_world_pos = InputManager.get_target_world_position()
		var nearest_index = _find_nearest_limb(touch_world_pos)
		if nearest_index >= 0:
			if limbs[nearest_index].is_latched:
				# Tap a latched limb → detach and start moving
				limbs[nearest_index].detach_from_hold()
			select_limb(nearest_index)
			selection_source = "touch"

	# TOUCH: finger-up → try to latch, then deselect
	if not touch_active and _was_touch_active and selection_source == "touch":
		var selected = get_selected_limb()
		if selected and not selected.is_latched and StaminaManager.can_latch():
			var nearest_hold = selected.get_nearest_hold()
			if nearest_hold:
				selected.latch_to_hold(nearest_hold)
		select_limb(-1)

	_was_touch_active = touch_active

func _handle_limb_actions():
	# Handle latch and detach actions
	var selected = get_selected_limb()
	if not selected:
		return

	# Latch selected limb to nearest hold
	if InputManager.latch_just_pressed:
		# Check if player has enough stamina to latch
		if not StaminaManager.can_latch():
			return

		var nearest_hold = selected.get_nearest_hold()
		if nearest_hold:
			selected.latch_to_hold(nearest_hold)

	# Detach selected limb
	if InputManager.detach_just_pressed:
		selected.detach_from_hold()

func select_limb(index: int):
	# Deselect previous limb
	if selected_limb_index >= 0 and selected_limb_index < limbs.size():
		limbs[selected_limb_index].set_selected(false)

	# Select new limb
	selected_limb_index = index
	if selected_limb_index >= 0 and selected_limb_index < limbs.size():
		limbs[selected_limb_index].set_selected(true)

func get_selected_limb():
	if selected_limb_index >= 0 and selected_limb_index < limbs.size():
		return limbs[selected_limb_index]
	return null

func _find_nearest_limb(world_pos: Vector2) -> int:
	var best_index: int = -1
	var best_distance: float = PhysicsConstants.TOUCH_SELECT_RADIUS
	for i in range(limbs.size()):
		var distance = world_pos.distance_to(limbs[i].global_position)
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index

func _update_head_tracking():
	"""Update head to look at cursor when limb is selected, or stay upright when idle"""
	var selected = get_selected_limb()

	if selected and not selected.is_latched:
		# Limb is selected and moving - head tracks cursor
		var target_pos = InputManager.get_target_world_position()
		head.track_position(target_pos)
	else:
		# No limb selected or limb is latched - head stays upright
		head.stop_tracking()

func _is_grounded() -> bool:
	return torso_on_ground or legs_on_ground > 0

func _update_stamina(delta: float):
	"""
	Update stamina system based on current limb configuration.
	Counts which limbs are latched and passes to StaminaManager.
	"""
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
	"""
	Called when stamina reaches 0.
	Detaches all limbs, causing player to fall.
	"""
	# Detach all latched limbs
	for limb in limbs:
		if limb.is_latched:
			limb.detach_from_hold()

func _on_torso_body_entered(body: Node):
	"""
	Called when Torso starts colliding with something.
	Check if it's the floor (layer 2) to determine if player is grounded.
	"""
	if body is StaticBody2D:
		# Check if body is on layer 2 (environment/floor)
		if body.collision_layer & 2:  # Bitwise check for layer 2
			torso_on_ground = true

func _on_torso_body_exited(body: Node):
	"""
	Called when Torso stops colliding with something.
	Update grounded state if leaving the floor.
	"""
	if body is StaticBody2D:
		# Check if body was on layer 2 (environment/floor)
		if body.collision_layer & 2:
			torso_on_ground = false

func _on_leg_body_entered(body: Node):
	if body is StaticBody2D and body.collision_layer & 2:
		legs_on_ground += 1

func _on_leg_body_exited(body: Node):
	if body is StaticBody2D and body.collision_layer & 2:
		legs_on_ground = max(0, legs_on_ground - 1)
