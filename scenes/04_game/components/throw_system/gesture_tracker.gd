extends Node
class_name GestureTracker

@export var debug_enabled: bool = true
@export var max_draw_points: int = 60
@onready var debug_line: Line2D = $DebugLine

var start_pos: Vector2
var points: PackedVector2Array = []
var is_tracking: bool = false

signal gesture_started(start_pos: Vector2)
signal gesture_dragging(current: Vector2, start: Vector2)
signal gesture_ended(points: PackedVector2Array)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_tracking = event.pressed
		if is_tracking:
			start_pos = event.position
			points.clear()
			points.append(start_pos)
			debug_line.clear_points()
			gesture_started.emit(start_pos)
		else:
			gesture_ended.emit(points)

	elif is_tracking and event is InputEventMouseMotion:
		var pos = event.position
		points.append(pos)
		if debug_enabled and debug_line:
			debug_line.add_point(pos)

		if max_draw_points > 0 and points.size() >= max_draw_points:
			is_tracking = false
			gesture_ended.emit(points)
		else:
			gesture_dragging.emit(pos, start_pos)
