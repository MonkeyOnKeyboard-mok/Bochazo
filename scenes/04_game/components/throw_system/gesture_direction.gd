extends Node
class_name GestureDirection

@export var tracker: GestureTracker
@export var preview_line: Line2D
@export var preview_length: float = 150.0

signal direction_calculated(dir: Vector2)

func _ready():
	if not tracker or not preview_line: return
	tracker.flick_detected.connect(_on_flick)

func _on_flick(dir: Vector2):
	preview_line.clear_points()
	# Dibujamos en espacio de pantalla (UI)
	preview_line.add_point(dir * -preview_length) # Invertido para que apunte "hacia donde tiras"
	preview_line.add_point(Vector2.ZERO)
	direction_calculated.emit(dir)
