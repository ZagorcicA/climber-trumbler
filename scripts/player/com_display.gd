extends Node2D

# AI pose-estimation style overlay showing center of mass
# Draws skeleton lines, joint dots, CoM indicator, and trail

var bodies: Array = []
var masses: Array = []
var total_mass: float = 0.0

var trail: Array = []
var frame_counter: int = 0
var ring_phase: float = 0.0


func _ready():
	var player = get_parent()
	bodies = [
		player.get_node("Torso"),
		player.get_node("Head"),
		player.get_node("LeftArm"),
		player.get_node("RightArm"),
		player.get_node("LeftLeg"),
		player.get_node("RightLeg"),
	]
	masses = [
		PhysicsConstants.MASS_TORSO,
		PhysicsConstants.MASS_HEAD,
		PhysicsConstants.MASS_ARM,
		PhysicsConstants.MASS_ARM,
		PhysicsConstants.MASS_LEG,
		PhysicsConstants.MASS_LEG,
	]
	for m in masses:
		total_mass += m


func _physics_process(delta):
	frame_counter += 1
	if frame_counter >= PhysicsConstants.COM_TRAIL_SAMPLE_INTERVAL:
		frame_counter = 0
		trail.push_front(_calculate_com_global())
		if trail.size() > PhysicsConstants.COM_TRAIL_LENGTH:
			trail.resize(PhysicsConstants.COM_TRAIL_LENGTH)

	ring_phase += delta * 3.0
	if ring_phase > TAU:
		ring_phase -= TAU

	queue_redraw()


func _draw():
	if bodies.is_empty():
		return

	var torso_local = to_local(bodies[0].global_position)

	# Skeleton lines: torso → each body part (star topology)
	for i in range(1, bodies.size()):
		var body_local = to_local(bodies[i].global_position)
		draw_line(torso_local, body_local, PhysicsConstants.COM_LINE_COLOR, PhysicsConstants.COM_LINE_WIDTH)

	# Joint dots at each body position
	for body in bodies:
		var pos = to_local(body.global_position)
		draw_circle(pos, PhysicsConstants.COM_JOINT_RADIUS, PhysicsConstants.COM_JOINT_COLOR)

	# Center of mass
	var com_global = _calculate_com_global()
	var com_local = to_local(com_global)

	# Trail (fading magenta dots)
	for i in range(trail.size()):
		var alpha = lerp(0.6, 0.05, float(i) / float(PhysicsConstants.COM_TRAIL_LENGTH))
		var trail_color = Color(PhysicsConstants.COM_DOT_COLOR.r, PhysicsConstants.COM_DOT_COLOR.g, PhysicsConstants.COM_DOT_COLOR.b, alpha)
		var radius = lerp(5.0, 2.0, float(i) / float(PhysicsConstants.COM_TRAIL_LENGTH))
		draw_circle(to_local(trail[i]), radius, trail_color)

	# Crosshair
	var ch = PhysicsConstants.COM_CROSSHAIR_SIZE
	draw_line(com_local + Vector2(-ch, 0), com_local + Vector2(ch, 0), PhysicsConstants.COM_CROSSHAIR_COLOR, 1.0)
	draw_line(com_local + Vector2(0, -ch), com_local + Vector2(0, ch), PhysicsConstants.COM_CROSSHAIR_COLOR, 1.0)

	# Pulsing ring
	var pulse = (sin(ring_phase) + 1.0) * 0.5
	var ring_radius = lerp(PhysicsConstants.COM_RING_MIN_RADIUS, PhysicsConstants.COM_RING_MAX_RADIUS, pulse)
	draw_arc(com_local, ring_radius, 0, TAU, 32, PhysicsConstants.COM_RING_COLOR, 2.0)

	# CoM dot (drawn last, on top)
	draw_circle(com_local, PhysicsConstants.COM_DOT_RADIUS, PhysicsConstants.COM_DOT_COLOR)


func _calculate_com_global() -> Vector2:
	var weighted_sum = Vector2.ZERO
	for i in range(bodies.size()):
		weighted_sum += masses[i] * bodies[i].global_position
	return weighted_sum / total_mass
