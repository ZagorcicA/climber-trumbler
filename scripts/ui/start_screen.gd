extends Control

# Start screen controller
# Displays the main menu with title and play button

@onready var play_button = %PlayButton

# Path to the first level
const LEVEL_1_PATH = "res://scenes/environment/Level1.tscn"

# Initializes the start screen and sets up button focus.
func _ready():
	# Give the play button focus for keyboard/controller navigation
	play_button.grab_focus()

# Called when the Play button is pressed.
# Loads the first level scene.
func _on_play_button_pressed():
	get_tree().change_scene_to_file(LEVEL_1_PATH)
