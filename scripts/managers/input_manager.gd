extends Node

# InputManager Singleton (SSOT for input state)
# Centralized input handling for the entire game
# This is an autoload singleton - accessible globally as InputManager

# Mouse state
var mouse_position: Vector2 = Vector2.ZERO

# Touch state — per-finger tracking for multi-touch
var active_touches: Dictionary = {}  # finger_index (int) → screen_position (Vector2)

# Input state for limb controls
var latch_just_pressed: bool = false
var detach_just_pressed: bool = false
var limb_keys_held: Array = []  # Limb indices currently held via keyboard

func _input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			active_touches[event.index] = event.position
		else:
			active_touches.erase(event.index)
	elif event is InputEventScreenDrag:
		if event.index in active_touches:
			active_touches[event.index] = event.position

func _process(_delta):
	# Update mouse position
	mouse_position = get_viewport().get_mouse_position()

	# Reset per-frame input flags
	latch_just_pressed = false
	detach_just_pressed = false

	# Check latch/detach inputs
	if Input.is_action_just_pressed("latch_limb"):
		latch_just_pressed = true

	if Input.is_action_just_pressed("detach_limb"):
		detach_just_pressed = true

	# Check which limb keys are held (multiple allowed simultaneously)
	limb_keys_held = []
	if Input.is_action_pressed("select_limb_1"):
		limb_keys_held.append(2)    # left leg
	if Input.is_action_pressed("select_limb_2"):
		limb_keys_held.append(0)    # left arm
	if Input.is_action_pressed("select_limb_3"):
		limb_keys_held.append(1)    # right arm
	if Input.is_action_pressed("select_limb_4"):
		limb_keys_held.append(3)    # right leg

func get_mouse_world_position() -> Vector2:
	# Get mouse position in world coordinates (accounting for camera)
	var camera = get_viewport().get_camera_2d()
	if camera:
		return camera.get_global_mouse_position()
	return mouse_position

func screen_to_world(screen_pos: Vector2) -> Vector2:
	var canvas_transform = get_viewport().get_canvas_transform()
	return canvas_transform.affine_inverse() * screen_pos
