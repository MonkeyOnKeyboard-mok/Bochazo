# InputHandler.gd
extends Node

var bocha_root: Node3D
var ray_query: PhysicsRayQueryParameters3D

func is_clicking_on_bocha(mouse_position: Vector2) -> bool:
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return false

	# Crear rayo desde la cámara hacia la posición del mouse
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_position) * 100.0

	ray_query = PhysicsRayQueryParameters3D.create(
		ray_origin, ray_end, 1 << 0  # collision mask 1
	)
	ray_query.collide_with_areas = false
	ray_query.collide_with_bodies = true

	var space_state = bocha_root.physics_body.get_world_3d().direct_space_state
	var result = space_state.intersect_ray(ray_query)

	if result.is_empty():
		return false

	# Verificar si el collider pertenece a esta bocha
	return result.collider == bocha_root.physics_body
