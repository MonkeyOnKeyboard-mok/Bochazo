# PositionController.gd
extends Node

var bocha_root: Node3D

func update_position() -> void:
	var direction = 0.0

	if Input.is_action_pressed("move_left"):
		direction -= 1.0
	if Input.is_action_pressed("move_right"):
		direction += 1.0

	if direction == 0.0:
		return

	var speed = bocha_root.lateral_speed * direction
	var new_z = bocha_root.physics_body.position.z + speed * get_process_delta_time()

	# Respetar limites laterales (eje Z = izquierda/derecha)
	new_z = clamp(new_z, bocha_root.lateral_bounds.x, bocha_root.lateral_bounds.y)

	# Mover solo en Z (lateral), mantener X e Y
	var new_pos = bocha_root.physics_body.position
	new_pos.z = new_z
	bocha_root.physics_body.position = new_pos
