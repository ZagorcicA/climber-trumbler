extends Control

# Start screen controller
# Displays the main menu with title and play button

@onready var play_button_easy = %PlayButtonEasy
@onready var play_button_medium = %PlayButtonMedium
@onready var play_button_hard = %PlayButtonHard

# Level scene paths
const LEVEL_EASY_PATH = "res://scenes/levels/LevelEasy.tscn"
const LEVEL_MEDIUM_PATH = "res://scenes/levels/LevelMedium.tscn"
const LEVEL_HARD_PATH = "res://scenes/levels/LevelHard.tscn"

# Initializes the start screen and sets up button connections.
func _ready():
	# Connect each button's pressed signal with a bound level argument
	play_button_easy.pressed.connect(_on_play_button_pressed.bind("easy"))
	play_button_medium.pressed.connect(_on_play_button_pressed.bind("medium"))
	play_button_hard.pressed.connect(_on_play_button_pressed.bind("hard"))

	# Give the easy button focus for keyboard/controller navigation
	play_button_easy.grab_focus()

# Called when the Play button is pressed.
# Loads the first level scene.
func _on_play_button_pressed(level: String):
	match level:
		"easy":
			get_tree().change_scene_to_file(LEVEL_EASY_PATH)
		"medium":
			get_tree().change_scene_to_file(LEVEL_MEDIUM_PATH)
		"hard":
			get_tree().change_scene_to_file(LEVEL_HARD_PATH)
