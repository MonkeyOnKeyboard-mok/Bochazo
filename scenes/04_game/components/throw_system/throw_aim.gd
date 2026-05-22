extends Node
class_name ThrowAim

var dir_module: GestureDirection
var max_spread_deg: float = 1.5

var dir: Vector3 = Vector3(1.0, 0.0, 0.0)
var aim_x: float = 0.0
var max_tangent: float
var launch_cos: float
var launch_sin: float
var launch_angle_rad: float

func _update_launch():
	launch_cos = cos(launch_angle_rad)
	launch_sin = sin(launch_angle_rad)

func _on_aim(aim_x_val: float):
	aim_x = aim_x_val
	var raw = Vector3(launch_cos, launch_sin, aim_x * max_tangent)
	dir = raw.normalized()

func connect_signals():
	if not dir_module:
		return
	dir_module.aim_calculated.connect(_on_aim)
