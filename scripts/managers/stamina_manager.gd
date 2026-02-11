extends Node

"""
StaminaManager Singleton (SSOT for stamina state)
Manages stamina drain/regeneration based on limb position configuration.
Implements realistic climbing mechanics where arm-only positions drain faster.

This is an autoload singleton - accessible globally as StaminaManager
"""

# Current state
var current_stamina: float = PhysicsConstants.MAX_STAMINA
var current_position_difficulty: String = "stable"  # For UI color feedback

# Signals
signal stamina_changed(new_value: float, difficulty: String)
signal stamina_depleted()
signal stamina_warning()  # Emitted at 30% threshold

# Warning flag to prevent spam
var warning_emitted: bool = false

func _ready():
	pass

func update_stamina(delta: float, arms_latched: int, legs_latched: int, is_grounded: bool, hold_difficulty_multiplier: float = 1.0):
	"""
	Update stamina based on current limb configuration and grounded state.
	Called every frame by Player.

	Args:
		delta: Time since last frame
		arms_latched: Number of arms currently attached (0-2)
		legs_latched: Number of legs currently attached (0-2)
		is_grounded: Whether player's torso is touching the floor
		hold_difficulty_multiplier: Average drain multiplier from hold types (easy=1.0, medium=1.5, hard=2.5)
	"""
	var total_latched = arms_latched + legs_latched

	# If grounded, regenerate stamina slowly - player is supported by floor
	if is_grounded:
		_regenerate_stamina(delta, PhysicsConstants.MULT_GROUNDED)
		current_position_difficulty = "resting"
	else:
		# Not grounded - use normal position-based stamina logic
		var multiplier = _calculate_multiplier(total_latched, arms_latched, legs_latched)

		# Determine if draining or regenerating
		if total_latched > 0:
			# Latched - check if draining or regenerating based on position
			if total_latched >= 3:
				# Resting position - regenerate (hold difficulty doesn't affect regen)
				_regenerate_stamina(delta, multiplier)
			else:
				# Active climbing - drain (apply hold difficulty multiplier)
				_drain_stamina(delta, multiplier * hold_difficulty_multiplier)
		else:
			# Free falling - regenerate fast
			_regenerate_stamina(delta, multiplier)

		# Update difficulty for UI
		_update_difficulty_category(total_latched, arms_latched, legs_latched)

	# Emit signal
	stamina_changed.emit(current_stamina, current_position_difficulty)

	# Check for warning threshold
	if current_stamina < PhysicsConstants.STAMINA_WARNING_THRESHOLD and not warning_emitted:
		stamina_warning.emit()
		warning_emitted = true
	elif current_stamina >= PhysicsConstants.STAMINA_WARNING_THRESHOLD:
		warning_emitted = false

func _calculate_multiplier(total: int, arms: int, legs: int) -> float:
	"""Calculate drain/regen multiplier based on limb configuration."""

	# 0 limbs - free falling, fast regen
	if total == 0:
		return PhysicsConstants.MULT_FREE_FALLING

	# 1 limb - desperate, very high drain
	elif total == 1:
		return PhysicsConstants.MULT_DESPERATE

	# 2 limbs
	elif total == 2:
		# Both arms - the hard challenge!
		if arms == 2 and legs == 0:
			return PhysicsConstants.MULT_ARMS_ONLY
		# Both legs - efficient/resting
		elif arms == 0 and legs == 2:
			return PhysicsConstants.MULT_EFFICIENT
		# Mixed (1 arm + 1 leg) - moderate
		else:
			return PhysicsConstants.MULT_MODERATE

	# 3+ limbs - resting position, fast regen
	else:
		return PhysicsConstants.MULT_RESTING

func _drain_stamina(delta: float, multiplier: float):
	"""Drain stamina with position-based multiplier."""
	var drain_amount = PhysicsConstants.BASE_DRAIN_RATE * multiplier * delta
	current_stamina -= drain_amount

	if current_stamina <= 0:
		current_stamina = 0
		stamina_depleted.emit()

func _regenerate_stamina(delta: float, multiplier: float):
	"""Regenerate stamina with position-based multiplier."""
	var regen_amount = PhysicsConstants.BASE_REGEN_RATE * multiplier * delta
	current_stamina += regen_amount

	if current_stamina > PhysicsConstants.MAX_STAMINA:
		current_stamina = PhysicsConstants.MAX_STAMINA

func _update_difficulty_category(total: int, arms: int, legs: int):
	"""Update difficulty category for UI color feedback."""

	if total == 0:
		current_position_difficulty = "resting"
	elif total == 1:
		current_position_difficulty = "desperate"
	elif total == 2:
		if arms == 2 and legs == 0:
			current_position_difficulty = "hard"  # Arms only!
		elif arms == 0 and legs == 2:
			current_position_difficulty = "efficient"
		else:
			current_position_difficulty = "moderate"
	elif total >= 3:
		current_position_difficulty = "resting"
	else:
		current_position_difficulty = "stable"

func can_latch() -> bool:
	"""Check if player has enough stamina to latch."""
	return current_stamina >= PhysicsConstants.MIN_LATCH_STAMINA

func reset():
	"""Reset stamina to full (called on level restart)."""
	current_stamina = PhysicsConstants.MAX_STAMINA
	current_position_difficulty = "stable"
	warning_emitted = false
