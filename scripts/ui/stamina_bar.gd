extends ProgressBar

"""
StaminaBar UI Controller
Displays current stamina and changes color based on position difficulty.

Color coding:
- Green: Resting/efficient position
- Yellow: Stable position
- Orange: Hard/moderate position
- Red: Desperate position or low stamina (<30%)
"""

# Color definitions
const COLOR_RESTING = Color(0.2, 0.8, 0.3)      # Green
const COLOR_EFFICIENT = Color(0.4, 0.9, 0.4)    # Light green
const COLOR_STABLE = Color(0.9, 0.9, 0.3)       # Yellow
const COLOR_MODERATE = Color(1.0, 0.7, 0.2)     # Orange
const COLOR_HARD = Color(1.0, 0.5, 0.1)         # Dark orange
const COLOR_DESPERATE = Color(1.0, 0.2, 0.2)    # Red
const COLOR_CRITICAL = Color(0.9, 0.1, 0.1)     # Dark red

func _ready():
	# Initialize bar
	max_value = PhysicsConstants.MAX_STAMINA
	value = PhysicsConstants.MAX_STAMINA
	show_percentage = false

	# Connect to StaminaManager signals
	StaminaManager.stamina_changed.connect(_on_stamina_changed)
	StaminaManager.stamina_depleted.connect(_on_stamina_depleted)

	# Initial color
	_update_color(100.0, "stable")

func _on_stamina_changed(new_value: float, difficulty: String):
	"""Update bar value and color based on stamina and position."""
	# Smooth value transition
	value = new_value

	# Update color based on difficulty and stamina level
	_update_color(new_value, difficulty)

func _update_color(stamina_value: float, difficulty: String):
	"""Set bar color based on position difficulty and stamina level."""

	# Critical stamina overrides position color
	if stamina_value < PhysicsConstants.STAMINA_WARNING_THRESHOLD:
		modulate = COLOR_CRITICAL
		return

	# Color based on position difficulty
	match difficulty:
		"resting":
			modulate = COLOR_RESTING
		"efficient":
			modulate = COLOR_EFFICIENT
		"stable":
			modulate = COLOR_STABLE
		"moderate":
			modulate = COLOR_MODERATE
		"hard":
			modulate = COLOR_HARD
		"desperate":
			modulate = COLOR_DESPERATE
		_:
			modulate = COLOR_STABLE

func _on_stamina_depleted():
	"""Visual feedback when stamina is fully depleted."""
	modulate = COLOR_CRITICAL
