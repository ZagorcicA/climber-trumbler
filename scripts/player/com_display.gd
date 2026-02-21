extends Node2D

# AI pose-estimation style overlay showing center of mass
# Draws skeleton lines, joint dots, CoM indicator, and trail

var bodies: Array = []

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

	var pulse_speed = lerp(3.0, 8.0, 1.0 - CenterOfMassManager.stamina_ratio)
	ring_phase += delta * pulse_speed
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

	# Stamina-driven color
	var ratio = CenterOfMassManager.stamina_ratio
	var com_color: Color
	if ratio > 0.5:
		com_color = PhysicsConstants.COM_COLOR_FRESH.lerp(PhysicsConstants.COM_COLOR_TIRED, (1.0 - ratio) * 2.0)
	else:
		com_color = PhysicsConstants.COM_COLOR_TIRED.lerp(PhysicsConstants.COM_COLOR_CRITICAL, (0.5 - ratio) * 2.0)

	# Anchor = torso center (the rope hangs from the body's core)
	var anchor_local = to_local(torso.global_position)

	# Effective CoM (sagged + overshoot — the swinging rock)
	var com_global = _calculate_com_global()
	var com_local = to_local(com_global)

	# Stamina-scaled sizes (grow when tired)
	var tiredness = 1.0 - ratio
	var dot_radius = lerp(PhysicsConstants.COM_DOT_RADIUS_EXHAUSTED, PhysicsConstants.COM_DOT_RADIUS, ratio)
	var ring_min = lerp(PhysicsConstants.COM_RING_MIN_RADIUS_EXHAUSTED, PhysicsConstants.COM_RING_MIN_RADIUS, ratio)
	var ring_max = lerp(PhysicsConstants.COM_RING_MAX_RADIUS_EXHAUSTED, PhysicsConstants.COM_RING_MAX_RADIUS, ratio)
	var trail_scale = lerp(PhysicsConstants.COM_TRAIL_DOT_SCALE_EXHAUSTED, 1.0, ratio)

	# Pendulum rope (anchor → swinging rock, fades in with tiredness)
	if tiredness > 0.05:
		var rope_alpha = tiredness * 0.8
		var rope_color = Color(com_color.r, com_color.g, com_color.b, rope_alpha)
		var rope_width = lerp(1.0, PhysicsConstants.COM_ROPE_WIDTH_MAX, tiredness)
		draw_line(anchor_local, com_local, rope_color, rope_width)

		# Anchor dot (ideal CoM — small, white-ish, marks the pivot)
		var anchor_alpha = tiredness * 0.6
		var anchor_color = Color(1.0, 1.0, 1.0, anchor_alpha)
		var anchor_radius = lerp(2.0, PhysicsConstants.COM_ANCHOR_RADIUS, tiredness)
		draw_circle(anchor_local, anchor_radius, anchor_color)

	# Trail (fading dots using stamina color, scaled by tiredness)
	for i in range(trail.size()):
		var alpha = lerp(0.6, 0.05, float(i) / float(PhysicsConstants.COM_TRAIL_LENGTH))
		var trail_color = Color(com_color.r, com_color.g, com_color.b, alpha)
		var radius = lerp(5.0, 2.0, float(i) / float(PhysicsConstants.COM_TRAIL_LENGTH)) * trail_scale
		draw_circle(to_local(trail[i]), radius, trail_color)

	# Crosshair
	var ch = PhysicsConstants.COM_CROSSHAIR_SIZE
	draw_line(com_local + Vector2(-ch, 0), com_local + Vector2(ch, 0), PhysicsConstants.COM_CROSSHAIR_COLOR, 1.0)
	draw_line(com_local + Vector2(0, -ch), com_local + Vector2(0, ch), PhysicsConstants.COM_CROSSHAIR_COLOR, 1.0)

	# Pulsing ring (stamina color, lower alpha, grows when tired)
	var pulse = (sin(ring_phase) + 1.0) * 0.5
	var ring_radius = lerp(ring_min, ring_max, pulse)
	var ring_color = Color(com_color.r, com_color.g, com_color.b, 0.3)
	draw_arc(com_local, ring_radius, 0, TAU, 32, ring_color, 2.0)

	# CoM dot (drawn last, on top — the heavy swinging rock)
	draw_circle(com_local, dot_radius, com_color)


func _calculate_com_global() -> Vector2:
	return CenterOfMassManager.effective_com_position
