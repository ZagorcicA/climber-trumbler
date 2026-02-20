extends Node2D

# AI pose-estimation style overlay showing center of mass
# Draws skeleton lines, joint dots, CoM indicator, and trail

var bodies: Array = []
var masses: Array = []
var total_mass: float = 0.0

var trail: Array = []
var frame_counter: int = 0
var ring_phase: float = 0.0


var torso: RigidBody2D
var joint_neck: Vector2
var joint_l_shoulder: Vector2
var joint_r_shoulder: Vector2
var joint_l_hip: Vector2
var joint_r_hip: Vector2


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

	torso = bodies[0]
	joint_neck = PhysicsConstants.JOINT_POS_NECK
	joint_l_shoulder = PhysicsConstants.JOINT_POS_LEFT_ARM
	joint_r_shoulder = PhysicsConstants.JOINT_POS_RIGHT_ARM
	joint_l_hip = PhysicsConstants.JOINT_POS_LEFT_LEG
	joint_r_hip = PhysicsConstants.JOINT_POS_RIGHT_LEG


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

	# Compute joint world positions (rotate with torso)
	var neck = to_local(torso.to_global(joint_neck))
	var l_sh = to_local(torso.to_global(joint_l_shoulder))
	var r_sh = to_local(torso.to_global(joint_r_shoulder))
	var l_hp = to_local(torso.to_global(joint_l_hip))
	var r_hp = to_local(torso.to_global(joint_r_hip))
	var hip_mid = (l_hp + r_hp) * 0.5

	# Body part positions
	var head_pos = to_local(bodies[1].global_position)
	var l_arm_pos = to_local(bodies[2].global_position)
	var r_arm_pos = to_local(bodies[3].global_position)
	var l_leg_pos = to_local(bodies[4].global_position)
	var r_leg_pos = to_local(bodies[5].global_position)

	var line_color = PhysicsConstants.COM_LINE_COLOR
	var line_width = PhysicsConstants.COM_LINE_WIDTH

	# 8 anatomical skeleton segments
	draw_line(neck, head_pos, line_color, line_width)        # Neck → Head
	draw_line(l_sh, r_sh, line_color, line_width)            # Shoulder bar
	draw_line(l_sh, l_arm_pos, line_color, line_width)       # L.shoulder → L.arm
	draw_line(r_sh, r_arm_pos, line_color, line_width)       # R.shoulder → R.arm
	draw_line(neck, hip_mid, line_color, line_width)          # Spine
	draw_line(l_hp, r_hp, line_color, line_width)            # Hip bar
	draw_line(l_hp, l_leg_pos, line_color, line_width)       # L.hip → L.leg
	draw_line(r_hp, r_leg_pos, line_color, line_width)       # R.hip → R.leg

	# Joint anchor dots (5 joints)
	var joint_color = PhysicsConstants.COM_JOINT_COLOR
	var joint_radius = PhysicsConstants.COM_JOINT_RADIUS
	for pos in [neck, l_sh, r_sh, l_hp, r_hp]:
		draw_circle(pos, joint_radius, joint_color)

	# Body part dots (6 body centers)
	for body in bodies:
		var pos = to_local(body.global_position)
		draw_circle(pos, joint_radius, joint_color)

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
