extends Node

# CenterOfMassManager Singleton
# Shared center-of-mass state. Player feeds it each physics frame,
# other scripts (com_display, stamina) read from it.

# Current weighted center of mass (global coords)
var com_position: Vector2 = Vector2.ZERO

# Average position of latched holds (global coords)
var support_centroid: Vector2 = Vector2.ZERO

# Number of currently latched limbs
var support_count: int = 0

# Horizontal distance from CoM to support centroid (the "barn door" signal)
var com_offset_horizontal: float = 0.0

# Stamina-driven CoM state
var stamina_ratio: float = 1.0              # 1.0=full, 0.0=empty
var effective_com_position: Vector2         # com_position + stamina sag + overshoot

# Horizontal overshoot tracking
var _prev_com_x: float = 0.0
var _com_velocity_x: float = 0.0
var _effective_offset_x: float = 0.0


func update_stamina_ratio(ratio: float) -> void:
	stamina_ratio = ratio


func update_effective_com() -> void:
	var sag = (1.0 - stamina_ratio) * PhysicsConstants.COM_STAMINA_SAG_MAX
	var tiredness = 1.0 - stamina_ratio

	# Track horizontal velocity and accumulate overshoot
	_com_velocity_x = com_position.x - _prev_com_x
	_prev_com_x = com_position.x
	_effective_offset_x += _com_velocity_x * PhysicsConstants.COM_OVERSHOOT_GAIN * tiredness
	_effective_offset_x *= PhysicsConstants.COM_OVERSHOOT_DECAY
	_effective_offset_x = clampf(_effective_offset_x, -PhysicsConstants.COM_OVERSHOOT_MAX, PhysicsConstants.COM_OVERSHOOT_MAX)

	effective_com_position = com_position + Vector2(_effective_offset_x * tiredness, sag)


func update_com(bodies: Array, masses: Array, total_mass: float) -> void:
	var weighted_sum = Vector2.ZERO
	for i in range(bodies.size()):
		weighted_sum += masses[i] * bodies[i].global_position
	com_position = weighted_sum / total_mass


func update_support(latched_positions: Array) -> void:
	support_count = latched_positions.size()
	if support_count == 0:
		support_centroid = Vector2.ZERO
		com_offset_horizontal = 0.0
		return

	var sum = Vector2.ZERO
	for pos in latched_positions:
		sum += pos
	support_centroid = sum / support_count
	com_offset_horizontal = com_position.x - support_centroid.x
