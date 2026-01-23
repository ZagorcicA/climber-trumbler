extends StaticBody2D

# Climbing hold that limbs can latch onto
# Provides visual feedback when a limb is attached

@onready var attached_indicator = $AttachedIndicator

var attached_limbs: Array = []

func _ready():
	# Add to holds group so limbs can detect it
	add_to_group("holds")

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
