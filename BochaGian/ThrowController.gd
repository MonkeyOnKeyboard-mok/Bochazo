# ThrowController.gd
# Detecta el gesto de lanzamiento en dos fases:
# 1. PULL_BACK: Arrastrar hacia atras para "tomar carrera"
# 2. PUSH_FORWARD: Mover hacia adelante (calcula fuerza y direccion)
# 3. RELEASED: Soltar click = lanzar
# Si suelta durante PULL_BACK, lanza con direccion opuesta al arrastre.
extends Node

var bocha_root: Node3D

enum GesturePhase {
	IDLE,           # Esperando que el usuario haga click en la bocha
	PULL_BACK,      # Usuario arrastra hacia atras (cargando)
	PUSH_FORWARD,   # Usuario cambio de direccion y empuja hacia adelante
	RELEASED        # Usuario solto, listo para lanzar
}

var gesture_phase: GesturePhase = GesturePhase.IDLE

# Datos del gesto
var drag_start_world_pos: Vector3 = Vector3.ZERO
var drag_current_world_pos: Vector3 = Vector3.ZERO
var drag_offset: Vector3 = Vector3.ZERO
var drag_distance: float = 0.0
var drag_direction: Vector2 = Vector2.ZERO

# Datos de la fase de push (lanzamiento)
var push_start_pos: Vector3 = Vector3.ZERO
var push_offset: Vector3 = Vector3.ZERO
var push_distance: float = 0.0

# Plano de arrastre
var drag_plane_normal: Vector3 = Vector3.ZERO
var drag_plane_point: Vector3 = Vector3.ZERO

# Rastreo de distancia maxima para detectar cambio de direccion
var max_pull_distance: float = 0.0
var pull_direction: Vector3 = Vector3.ZERO

# Configuracion
@export var min_drag_distance: float = 0.1    # Metros minimos para considerar un lanzamiento
@export var max_drag_distance: float = 4.0    # Metros maximos (potencia maxima)
@export var sensitivity: float = 1.0
@export var direction_change_threshold: float = 0.15  # Metros de retroceso para detectar cambio

func start_aiming() -> void:
	gesture_phase = GesturePhase.IDLE
	drag_offset = Vector3.ZERO
	drag_distance = 0.0
	drag_direction = Vector2.ZERO
	push_offset = Vector3.ZERO
	push_distance = 0.0
	max_pull_distance = 0.0
	pull_direction = Vector3.ZERO

func stop_aiming() -> void:
	gesture_phase = GesturePhase.IDLE
	drag_offset = Vector3.ZERO
	drag_distance = 0.0
	drag_direction = Vector2.ZERO
	push_offset = Vector3.ZERO
	push_distance = 0.0
	max_pull_distance = 0.0
	pull_direction = Vector3.ZERO

func update_aim() -> void:
	if gesture_phase == GesturePhase.PULL_BACK or gesture_phase == GesturePhase.PUSH_FORWARD:
		# Proyectar posicion actual del mouse al plano de arrastre
		var current_world = _get_world_position_from_mouse()
		if current_world != Vector3.INF:
			drag_current_world_pos = current_world
			drag_offset = drag_current_world_pos - drag_start_world_pos
			drag_distance = drag_offset.length()

			# Direccion 2D para compatibilidad con UI existente
			if drag_distance > 0.01:
				var camera = get_viewport().get_camera_3d()
				if camera:
					var screen_start = camera.unproject_position(drag_start_world_pos)
					var screen_current = camera.unproject_position(drag_current_world_pos)
					var screen_delta = screen_current - screen_start
					drag_direction = screen_delta.normalized()

			# Detectar cambio de direccion durante PULL_BACK
			if gesture_phase == GesturePhase.PULL_BACK:
				# Actualizar distancia maxima alcanzada
				if drag_distance > max_pull_distance:
					max_pull_distance = drag_distance
					if drag_distance > 0.01:
						pull_direction = drag_offset.normalized()

				# Detectar si el usuario empezo a volver hacia el punto de inicio
				if max_pull_distance > min_drag_distance and _detect_direction_change():
					print("[ThrowController] Cambio de direccion: PULL_BACK -> PUSH_FORWARD (max_pull: ", max_pull_distance, "m)")
					gesture_phase = GesturePhase.PUSH_FORWARD
					push_start_pos = current_world
					push_offset = Vector3.ZERO
					push_distance = 0.0

			# Calcular offset del push si estamos en fase de push
			if gesture_phase == GesturePhase.PUSH_FORWARD:
				push_offset = drag_current_world_pos - push_start_pos
				push_distance = push_offset.length()

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Verificar si el click fue sobre la bocha usando raycast
			var hit_pos = _raycast_to_bocha(event.position)
			if hit_pos != Vector3.INF:
				print("[ThrowController] Click en bocha -> inicio arrastre en ", hit_pos)
				gesture_phase = GesturePhase.PULL_BACK
				drag_start_world_pos = hit_pos
				drag_current_world_pos = hit_pos
				drag_offset = Vector3.ZERO
				drag_distance = 0.0
				drag_direction = Vector2.ZERO
				push_offset = Vector3.ZERO
				push_distance = 0.0
				max_pull_distance = 0.0
				pull_direction = Vector3.ZERO

				# El plano de arrastre es horizontal (paralelo al suelo) en la altura de la bocha
				drag_plane_normal = Vector3.UP
				drag_plane_point = hit_pos
			else:
				# Click fuera de la bocha, ignorar
				pass
		else:
			# Usuario solto el click
			if gesture_phase == GesturePhase.PULL_BACK:
				# Si el usuario no hizo pull-back real (se movio hacia adelante en vez de atras),
				# ignorar el lanzamiento para evitar tiros hacia atras
				if drag_offset.x > 0:
					print("[ThrowController] Soltó sin pull-back real (movio hacia adelante). Ignorando lanzamiento.")
					gesture_phase = GesturePhase.IDLE
					drag_offset = Vector3.ZERO
					drag_distance = 0.0
					return

				# Soltó durante el pull-back -> lanza con direccion opuesta al offset
				print("[ThrowController] Soltó durante pull-back -> lanza inverso (distancia: ", drag_distance, "m)")
				# Invertir el offset para que el lanzamiento sea en direccion opuesta
				push_offset = -drag_offset
				push_distance = drag_distance
				gesture_phase = GesturePhase.RELEASED
			elif gesture_phase == GesturePhase.PUSH_FORWARD:
				# Soltó durante el push-forward -> lanzar normalmente
				print("[ThrowController] Mouse UP -> RELEASED (push_distance: ", push_distance, "m)")
				gesture_phase = GesturePhase.RELEASED

func get_throw_data() -> Dictionary:
	var data = {
		"power": 0.0,
		"direction": Vector3.ZERO,
		"curve": 0.0
	}

	if gesture_phase != GesturePhase.RELEASED:
		return data

	# Potencia basada en la distancia del push (rango min a max)
	var normalized = clamp(push_distance / max_drag_distance, 0.0, 1.0)
	data.power = lerpf(bocha_root.min_throw_power, bocha_root.max_throw_power, normalized)

	# Direccion: igual al offset del push (+X es adelante)
	if push_distance > 0.01:
		data.direction = push_offset.normalized()
	else:
		data.direction = Vector3(1, 0, 0)

	# Curva basada en desvio lateral del push
	var lateral = push_offset.z
	data.curve = clamp(lateral / max_drag_distance * sensitivity, -1.0, 1.0)

	print("[ThrowController] throw_data: power=", data.power, " curve=", data.curve, " push_dist=", push_distance, "m")

	return data

# Detectar si el usuario cambio de direccion (volviendo hacia el punto de inicio)
func _detect_direction_change() -> bool:
	if max_pull_distance < min_drag_distance:
		return false

	# Calcular cuanto se acerca al punto de inicio desde el punto mas alejado
	var distance_to_start = drag_distance
	var pullback_amount = max_pull_distance - distance_to_start

	# Si se acerco al punto de inicio mas que el umbral, detectamos cambio de direccion
	return pullback_amount > direction_change_threshold

# Obtener la posicion 3D del mouse proyectada al plano de arrastre
func _get_world_position_from_mouse() -> Vector3:
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return Vector3.INF

	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)

	# Interseccion rayo-plano
	var denom = drag_plane_normal.dot(ray_dir)
	if abs(denom) < 0.0001:
		return Vector3.INF  # Rayo paralelo al plano

	var t = drag_plane_normal.dot(drag_plane_point - ray_origin) / denom
	if t < 0:
		return Vector3.INF  # Detras de la camara

	return ray_origin + ray_dir * t

# Raycast para detectar si el click fue sobre la bocha
func _raycast_to_bocha(mouse_position: Vector2) -> Vector3:
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return Vector3.INF

	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_position) * 100.0

	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_bodies = true

	var space_state = bocha_root.physics_body.get_world_3d().direct_space_state
	var result = space_state.intersect_ray(query)

	if result.is_empty():
		return Vector3.INF

	# Verificar que el collider es el de esta bocha
	if result.collider == bocha_root.physics_body:
		return result.position

	return Vector3.INF

# Para debug visual: que tan lejos arrastro el usuario (0.0 a 1.0)
func get_drag_progress() -> float:
	if gesture_phase == GesturePhase.PULL_BACK:
		return clamp(drag_distance / max_drag_distance, 0.0, 1.0)
	elif gesture_phase == GesturePhase.PUSH_FORWARD:
		return clamp(push_distance / max_drag_distance, 0.0, 1.0)
	return 0.0
