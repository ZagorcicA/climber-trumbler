extends Camera2D

@export var target_path: NodePath = "../Player"
var target: Node2D
const LOOK_AHEAD_Y := -150.0
const CENTER_X := 576.0

func _ready():
	target = get_node_or_null(target_path)
	position_smoothing_enabled = true
	position_smoothing_speed = 4.0

func _process(_delta):
	if target:
		position.y = target.position.y + LOOK_AHEAD_Y
	position.x = CENTER_X
