extends StaticBody2D

# Climbing hold that limbs can latch onto
# Provides visual feedback when a limb is attached
# Hold difficulty affects stamina drain rate when latched

enum HoldDifficulty {EASY, MEDIUM, HARD}

@export var hold_difficulty: HoldDifficulty = HoldDifficulty.EASY

# Drain multipliers per difficulty - harder holds drain stamina faster
const DIFFICULTY_DRAIN_MULTIPLIER = {
	HoldDifficulty.EASY: 1.0,
	HoldDifficulty.MEDIUM: 1.5,
	HoldDifficulty.HARD: 2.5,
}

# Visual colors per difficulty
const DIFFICULTY_COLORS = {
	HoldDifficulty.EASY: Color(0.259113, 0.769583, 0.269687, 1),
	HoldDifficulty.MEDIUM: Color(0.284795, 0.297749, 0.878261, 1),
	HoldDifficulty.HARD: Color(0.597306, 0, 0.0655421, 1),
}

@onready var attached_indicator = $AttachedIndicator
@onready var hold_visual = $HoldVisual

var attached_limbs: Array = []

func _ready():
	# Add to holds group so limbs can detect it
	add_to_group("holds")
	# Set hold color based on difficulty
	hold_visual.color = DIFFICULTY_COLORS.get(hold_difficulty, DIFFICULTY_COLORS[HoldDifficulty.EASY])

func attach_limb(limb):
	"""Called when a limb latches to this hold"""
	if limb not in attached_limbs:
		attached_limbs.append(limb)
		_update_visual_state()

func detach_limb(limb):
	"""Called when a limb detaches from this hold"""
	if limb in attached_limbs:
		attached_limbs.erase(limb)
		_update_visual_state()

func _update_visual_state():
	"""Show/hide the attached indicator based on limb count"""
	attached_indicator.visible = attached_limbs.size() > 0

func get_attach_position() -> Vector2:
	"""Returns the world position where limbs should attach"""
	return global_position

func get_drain_multiplier() -> float:
	"""Returns the stamina drain multiplier for this hold's difficulty"""
	return DIFFICULTY_DRAIN_MULTIPLIER.get(hold_difficulty, 1.0)
