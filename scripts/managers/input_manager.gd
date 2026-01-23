extends Node

# InputManager Singleton (SSOT for input state)
# Centralized input handling for the entire game
# This is an autoload singleton - accessible globally as InputManager

# Mouse state
var mouse_position: Vector2 = Vector2.ZERO

# Input state for limb controls
var latch_just_pressed: bool = false
var detach_just_pressed: bool = false
var limb_selection_pressed: int = -1  # 0-3 for limbs 1-4, -1 for none

func _process(_delta):
	# Update mouse position
	mouse_position = get_viewport().get_mouse_position()

	# Reset per-frame input flags
	latch_just_pressed = false
	detach_just_pressed = false
	limb_selection_pressed = -1

	# Check latch/detach inputs
	if Input.is_action_just_pressed("latch_limb"):
		latch_just_pressed = true

	if Input.is_action_just_pressed("detach_limb"):
		detach_just_pressed = true

	# Check limb selection inputs
	if Input.is_action_just_pressed("select_limb_1"):
		limb_selection_pressed = 0
	elif Input.is_action_just_pressed("select_limb_2"):
		limb_selection_pressed = 1
	elif Input.is_action_just_pressed("select_limb_3"):
		limb_selection_pressed = 2
	elif Input.is_action_just_pressed("select_limb_4"):
		limb_selection_pressed = 3

func get_mouse_world_position() -> Vector2:
	# Get mouse position in world coordinates (accounting for camera)
	var camera = get_viewport().get_camera_2d()
	if camera:
		return camera.get_global_mouse_position()
	return mouse_position
