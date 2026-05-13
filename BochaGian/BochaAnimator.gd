# BochaAnimator.gd
# Feedback visual de la bocha durante el aiming:
# - Durante PULL_BACK: el mesh sigue al mouse hacia atras
# - Durante PUSH_FORWARD: el mesh vuelve hacia adelante siguiendo el push
# - Flecha visual que muestra direccion y potencia del lanzamiento
# - Cambio de color segun potencia cargada
extends Node

var bocha_root: Node3D
var mesh_instance: MeshInstance3D
var original_mesh_pos: Vector3
var original_material: Material

@export var max_visual_offset: float = 1.5  # Distancia maxima que se mueve el mesh

# Flecha visual
var arrow_mesh: MeshInstance3D
var arrow_material: StandardMaterial3D

func _ready() -> void:
	await get_tree().process_frame
	if bocha_root and bocha_root.physics_body:
		for child in bocha_root.physics_body.get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				original_mesh_pos = child.position
				if mesh_instance.material_override:
					original_material = mesh_instance.material_override.duplicate()
				break

		# Crear flecha visual
		if bocha_root.physics_body:
			_create_arrow()

func _create_arrow() -> void:
	arrow_mesh = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	cylinder.height = 1.0
	arrow_mesh.mesh = cylinder

	arrow_material = StandardMaterial3D.new()
	arrow_material.albedo_color = Color(1.0, 0.3, 0.3, 0.8)
	arrow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arrow_mesh.material_override = arrow_material

	arrow_mesh.visible = false
	bocha_root.physics_body.add_child(arrow_mesh)

func update_visual_feedback(drag_progress: float) -> void:
	if mesh_instance == null:
		return

	var tc = bocha_root.throw_controller
	if tc == null:
		return

	# Usar el offset correcto dependiendo de la fase
	var offset_3d: Vector3
	var phase = tc.gesture_phase
	if phase == tc.GesturePhase.PUSH_FORWARD:
		# Durante el push, el offset es negativo (la bocha vuelve hacia adelante)
		offset_3d = -tc.push_offset
	elif phase == tc.GesturePhase.PULL_BACK:
		# Durante el pull-back, el offset es positivo (la bocha va hacia atras)
		offset_3d = tc.drag_offset
	else:
		# IDLE o RELEASED: no hay offset
		offset_3d = Vector3.ZERO

	# Limitar distancia maxima visual
	if offset_3d.length() > max_visual_offset:
		offset_3d = offset_3d.normalized() * max_visual_offset

	# Aplicar offset al mesh (solo X y Z, mantener Y original)
	mesh_instance.position.x = original_mesh_pos.x + offset_3d.x
	mesh_instance.position.z = original_mesh_pos.z + offset_3d.z

	# Cambio de color: blanco (0%) -> rojo (100%)
	if mesh_instance.material_override:
		var mat = mesh_instance.material_override.duplicate()
		var r = 1.0
		var g = 1.0 - drag_progress * 0.8
		var b = 1.0 - drag_progress * 0.8
		mat.albedo_color = Color(r, g, b, 1.0)
		mesh_instance.material_override = mat

	# Actualizar flecha visual
	_update_arrow(offset_3d, drag_progress)

func _update_arrow(offset: Vector3, progress: float) -> void:
	if arrow_mesh == null:
		return

	var tc = bocha_root.throw_controller
	if tc == null:
		return

	# Solo mostrar flecha durante PULL_BACK o PUSH_FORWARD
	if tc.gesture_phase != tc.GesturePhase.PULL_BACK and tc.gesture_phase != tc.GesturePhase.PUSH_FORWARD:
		arrow_mesh.visible = false
		return

	if progress < 0.05:
		arrow_mesh.visible = false
		return

	arrow_mesh.visible = true

	# La flecha va desde la posicion original del mesh hasta la posicion actual
	var start_pos = original_mesh_pos
	var end_pos = Vector3(
		original_mesh_pos.x + offset.x,
		original_mesh_pos.y,
		original_mesh_pos.z + offset.z
	)

	# Centro de la flecha
	var mid = (start_pos + end_pos) / 2.0
	arrow_mesh.position = mid

	# Direccion y longitud
	var dir = end_pos - start_pos
	var length = dir.length()

	if length < 0.01:
		arrow_mesh.visible = false
		return

	# Orientar la flecha
	var quat = Quaternion(Vector3.UP, dir.normalized())
	arrow_mesh.quaternion = quat

	# Escalar la flecha
	arrow_mesh.scale = Vector3(1.0, length, 1.0)

	# Color mas intenso con mas potencia
	var alpha = 0.3 + progress * 0.7
	arrow_material.albedo_color = Color(1.0, 0.3, 0.3, alpha)

func reset_visual() -> void:
	if mesh_instance == null:
		return
	mesh_instance.position = original_mesh_pos
	if original_material:
		mesh_instance.material_override = original_material.duplicate()

	if arrow_mesh:
		arrow_mesh.visible = false
