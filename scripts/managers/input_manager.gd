extends Node

# InputManager Singleton (SSOT for input state)
# Centralized input handling for the entire game
# This is an autoload singleton - accessible globally as InputManager

# Mouse state
var mouse_position: Vector2 = Vector2.ZERO

# Touch state
var is_touch_active: bool = false
var touch_screen_position: Vector2 = Vector2.ZERO

# Input state for limb controls
var latch_just_pressed: bool = false
var detach_just_pressed: bool = false
var limb_key_held: int = -1  # Limb index currently held via keyboard, -1 for none

func _input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			is_touch_active = true
			touch_screen_position = event.position
		else:
			is_touch_active = false
	elif event is InputEventScreenDrag:
		if is_touch_active:
			touch_screen_position = event.position

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

	# Check which limb key is held (mapping: 1=left leg, 2=left arm, 3=right arm, 4=right leg)
	if Input.is_action_pressed("select_limb_1"):
		limb_key_held = 2    # left leg
	elif Input.is_action_pressed("select_limb_2"):
		limb_key_held = 0    # left arm
	elif Input.is_action_pressed("select_limb_3"):
		limb_key_held = 1    # right arm
	elif Input.is_action_pressed("select_limb_4"):
		limb_key_held = 3    # right leg
	else:
		limb_key_held = -1

func get_mouse_world_position() -> Vector2:
	# Get mouse position in world coordinates (accounting for camera)
	var camera = get_viewport().get_camera_2d()
	if camera:
		return camera.get_global_mouse_position()
	return mouse_position

func get_target_world_position() -> Vector2:
	if is_touch_active:
		var canvas_transform = get_viewport().get_canvas_transform()
		return canvas_transform.affine_inverse() * touch_screen_position
	return get_mouse_world_position()
