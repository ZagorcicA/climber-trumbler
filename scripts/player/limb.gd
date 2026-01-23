extends RigidBody2D

# Individual limb controller
# Handles physics movement, selection state, and hold attachment

@onready var grab_area = $GrabArea
@onready var selection_highlight = $SelectionHighlight

var is_selected: bool = false
var is_latched: bool = false
var target_position: Vector2 = Vector2.ZERO
var latch_joint: PinJoint2D = null
var nearby_holds: Array = []
var current_hold = null  # Reference to the hold we're attached to

# Movement parameters
const MOVE_FORCE = 15000.0  # Much higher force to swing the whole body
const MAX_VELOCITY = 800.0  # Higher max velocity for dynamic movement
const DAMPING = 0.99  # Minimal damping for responsive feel

func _ready():
	# Connect area signals to detect nearby holds
	grab_area.area_entered.connect(_on_hold_detected)
	grab_area.area_exited.connect(_on_hold_lost)

func _physics_process(_delta):
	if is_selected and not is_latched:
		# Move limb toward mouse position
		target_position = get_global_mouse_position()
		_move_toward_target()

func _move_toward_target():
	var direction = (target_position - global_position).normalized()
	var distance = global_position.distance_to(target_position)

	# Apply force toward target
	if distance > 10.0:  # Dead zone to prevent jittering
		var force = direction * MOVE_FORCE
		apply_central_force(force)

	# Limit velocity to prevent wild movements
	if linear_velocity.length() > MAX_VELOCITY:
		linear_velocity = linear_velocity.normalized() * MAX_VELOCITY

	# Apply damping for more controlled movement
	linear_velocity *= DAMPING

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
	latch_joint.softness = 0.05

	# Store reference and notify hold
	current_hold = hold
	hold.attach_limb(self)

	is_latched = true
	print("Limb latched to hold at ", hold.global_position)
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
	print("Limb detached from hold")

func _on_hold_detected(area):
	# Area entered grab zone
	if area.is_in_group("holds"):
		var hold = area.get_parent()
		nearby_holds.append(hold)
		print("Hold detected! Nearby holds count: ", nearby_holds.size())

func _on_hold_lost(area):
	# Area left grab zone
	if area.is_in_group("holds"):
		var hold = area.get_parent()
		nearby_holds.erase(hold)
		print("Hold lost! Nearby holds count: ", nearby_holds.size())
