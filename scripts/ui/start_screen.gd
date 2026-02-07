extends Control

# Start screen controller
# Displays the main menu with title and play button

@onready var play_button = %PlayButtonEasy

# Path to the first level
const LEVEL_EASY_PATH = "res://scenes/environment/levels/LevelEasy.tscn"

# Path to the first level
const LEVEL_MEDIUM_PATH = "res://scenes/environment/levels/LevelMedium.tscn"

# Path to the first level
const LEVEL_HARD_PATH = "res://scenes/environment/levels/LevelHard.tscn"

# Initializes the start screen and sets up button focus.
func _ready():
	# Give the play button focus for keyboard/controller navigation
	play_button.grab_focus()

# Called when the Play button is pressed.
# Loads the first level scene.
func _on_play_button_pressed():
	get_tree().change_scene_to_file(LEVEL_EASY_PATH)
