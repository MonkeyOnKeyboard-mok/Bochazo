extends Node
class_name GestureTracker

@export var debug_enabled: bool = true
@onready var debug_line: Line2D = $DebugLine

var start_pos: Vector2
var points: PackedVector2Array = []
var is_tracking: bool = false
var prev_pos: Vector2 = Vector2.ZERO
var was_moving_down: bool = false
var flick_emitted: bool = false

signal gesture_started(start_pos: Vector2)
signal gesture_dragging(current: Vector2, start: Vector2)
signal flick_detected(dir: Vector2)
signal gesture_ended(points: PackedVector2Array)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_tracking = event.pressed
		if is_tracking:
			start_pos = event.position # Coordenadas de pantalla puras
			points.clear()
			points.append(start_pos)
			debug_line.clear_points()
			prev_pos = start_pos
			was_moving_down = false
			flick_emitted = false
			gesture_started.emit(start_pos)
		else:
			gesture_ended.emit(points)

	elif is_tracking and event is InputEventMouseMotion:
		var pos = event.position
		points.append(pos)
		if debug_enabled and debug_line:
			debug_line.add_point(pos) # Sin to_local(), directo a UI

		var dy = pos.y - prev_pos.y
		if dy > 2.0: was_moving_down = true
		
		if was_moving_down and dy < -2.0 and not flick_emitted:
			# Vector limpio del flick: X horizontal, Y vertical negativo (hacia arriba)
			var flick_vec = Vector2(pos.x - prev_pos.x, dy).normalized()
			flick_detected.emit(flick_vec)
			flick_emitted = true

		gesture_dragging.emit(pos, start_pos)
		prev_pos = pos
