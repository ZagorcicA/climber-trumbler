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
var torso_on_ground: bool = false  # Tracks if torso is touching floor/ground
var legs_on_ground: int = 0  # Count of legs touching the floor

const STAND_SUPPORT_FORCE = 2500.0  # Upward force when legs grounded
const STAND_UPRIGHT_TORQUE = 8000.0  # Torque to keep torso vertical
const STAND_DAMPING = 0.85  # Reduce horizontal sliding

func _ready():
	# Register all limbs in order: 1=LeftArm, 2=RightArm, 3=LeftLeg, 4=RightLeg
	limbs = [left_arm, right_arm, left_leg, right_leg]

	# Select first limb by default
	if limbs.size() > 0:
		select_limb(0)

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
	torso.apply_central_force(Vector2(0, -STAND_SUPPORT_FORCE * support_multiplier))

	# Upright torque correction (proportional controller)
	torso.apply_torque(-torso.rotation * STAND_UPRIGHT_TORQUE)

	# Horizontal damping to prevent sliding
	torso.linear_velocity.x *= STAND_DAMPING

func _handle_limb_selection():
	# Use InputManager for centralized input handling (SSOT)
	var limb_index = InputManager.limb_selection_pressed
	if limb_index >= 0 and limb_index < limbs.size():
		select_limb(limb_index)

func _handle_limb_actions():
	# Handle latch and detach actions
	var selected = get_selected_limb()
	if not selected:
		return

	# Latch selected limb to nearest hold
	if InputManager.latch_just_pressed:
		# Check if player has enough stamina to latch
		if not StaminaManager.can_latch():
			print("Not enough stamina to latch!")
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

func _update_head_tracking():
	"""Update head to look at cursor when limb is selected, or stay upright when idle"""
	var selected = get_selected_limb()

	if selected and not selected.is_latched:
		# Limb is selected and moving - head tracks cursor
		var mouse_pos = InputManager.get_mouse_world_position()
		head.track_position(mouse_pos)
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
	print("Stamina depleted! All limbs released!")

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
			print("[STATE] Player grounded - torso floor contact")

func _on_torso_body_exited(body: Node):
	"""
	Called when Torso stops colliding with something.
	Update grounded state if leaving the floor.
	"""
	if body is StaticBody2D:
		# Check if body was on layer 2 (environment/floor)
		if body.collision_layer & 2:
			torso_on_ground = false
			print("[STATE] Player airborne - torso left floor")

func _on_leg_body_entered(body: Node):
	if body is StaticBody2D and body.collision_layer & 2:
		legs_on_ground += 1
		print("[STATE] Leg grounded (legs_on_ground: %d)" % legs_on_ground)

func _on_leg_body_exited(body: Node):
	if body is StaticBody2D and body.collision_layer & 2:
		legs_on_ground = max(0, legs_on_ground - 1)
		print("[STATE] Leg left ground (legs_on_ground: %d)" % legs_on_ground)
