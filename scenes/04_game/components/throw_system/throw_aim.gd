extends Node
class_name ThrowAim

@export var dir_module: GestureDirection
@export var max_spread_deg: float = 3.0

var dir: Vector3 = Vector3(1.0, 0.0, 0.0)
var max_tangent: float
var launch_cos: float
var launch_sin: float
var launch_angle_rad: float

func _ready():
	max_tangent = tan(deg_to_rad(max_spread_deg))
	launch_angle_rad = 0.0  # set by ThrowHandler from config
	_update_launch()
	if dir_module:
		dir_module.aim_calculated.connect(_on_aim)

func _update_launch():
	launch_cos = cos(launch_angle_rad)
	launch_sin = sin(launch_angle_rad)

func _on_aim(aim_x: float):
	var raw = Vector3(launch_cos, launch_sin, aim_x * max_tangent)
	dir = raw.normalized()
