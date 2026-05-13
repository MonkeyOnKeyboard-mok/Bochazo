# ThrowController.gd
# Gesto simple: click → arrastrar hacia atras → soltar = lanza
# La distancia arrastrada = potencia. El desplazamiento lateral = curva.
extends Node

var bocha_root: Node3D

enum GesturePhase {
	IDLE,       # Esperando que el usuario haga click
	DRAGGING,   # Usuario tiene el boton presionado y esta arrastrando
	RELEASED    # Usuario solto, listo para lanzar
}

var gesture_phase: GesturePhase = GesturePhase.IDLE

# Datos del gesto
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_current_pos: Vector2 = Vector2.ZERO
var drag_distance: float = 0.0
var drag_direction: Vector2 = Vector2.ZERO

# Configuracion
@export var min_drag_distance: float = 20.0    # Pixeles minimos para considerar un lanzamiento
@export var max_drag_distance: float = 400.0   # Pixeles maximos (potencia maxima)
@export var sensitivity: float = 1.0

func start_aiming() -> void:
	gesture_phase = GesturePhase.IDLE
	drag_start_pos = Vector2.ZERO
	drag_current_pos = Vector2.ZERO
	drag_distance = 0.0
	drag_direction = Vector2.ZERO

func stop_aiming() -> void:
	gesture_phase = GesturePhase.IDLE
	drag_start_pos = Vector2.ZERO
	drag_current_pos = Vector2.ZERO
	drag_distance = 0.0
	drag_direction = Vector2.ZERO

func update_aim() -> void:
	if gesture_phase == GesturePhase.DRAGGING:
		drag_current_pos = get_viewport().get_mouse_position()
		var delta = drag_current_pos - drag_start_pos
		drag_distance = delta.length()
		if drag_distance > 0:
			drag_direction = delta.normalized()

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			print("[ThrowController] Mouse DOWN -> inicio arrastre")
			gesture_phase = GesturePhase.DRAGGING
			drag_start_pos = get_viewport().get_mouse_position()
			drag_current_pos = drag_start_pos
			drag_distance = 0.0
			drag_direction = Vector2.ZERO
		else:
			if gesture_phase == GesturePhase.DRAGGING:
				print("[ThrowController] Mouse UP -> RELEASED (distancia: ", drag_distance, ")")
				gesture_phase = GesturePhase.RELEASED

func get_throw_data() -> Dictionary:
	var data = {
		"power": 0.0,
		"direction": Vector3.ZERO,
		"curve": 0.0
	}

	if gesture_phase != GesturePhase.RELEASED:
		return data

	# Potencia basada en la distancia arrastrada
	var normalized = clamp(drag_distance / max_drag_distance, 0.0, 1.0)
	data.power = normalized * bocha_root.max_throw_power

	# Direccion: -X es hacia adelante en el sistema de ejes de la escena
	data.direction = Vector3(-1, 0, 0)

	# Curva basada en el desplazamiento lateral del arrastre
	# Si arrastro hacia la izquierda (drag_direction.x > 0 en pantalla), curva a la izquierda
	var lateral = drag_direction.x
	data.curve = clamp(lateral * sensitivity, -1.0, 1.0)

	print("[ThrowController] throw_data: power=", data.power, " curve=", data.curve, " drag_dist=", drag_distance, " drag_dir=", drag_direction)

	return data

# Para debug visual: que tan lejos arrastro el usuario
func get_drag_progress() -> float:
	if gesture_phase != GesturePhase.DRAGGING:
		return 0.0
	return clamp(drag_distance / max_drag_distance, 0.0, 1.0)
