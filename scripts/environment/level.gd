extends Node2D

# Level management script
# Handles level-specific logic, win/lose conditions, and restart

@onready var player = $Player

func _ready():
	pass

func _process(_delta):
	# Handle restart input
	if Input.is_action_just_pressed("restart_level"):
		restart_level()

func restart_level():
	# Reset stamina before reload
	StaminaManager.reset()
	# Reload the current scene
	get_tree().reload_current_scene()

func check_win_condition():
	# Will be implemented when we add the win trigger
	pass
