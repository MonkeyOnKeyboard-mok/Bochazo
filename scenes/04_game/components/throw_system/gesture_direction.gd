extends Node
class_name GestureDirection

var tracker: GestureTracker
var preview_line: Line2D
var preview_length: float = 150.0
var aim_sensitivity: float = 300.0

signal aim_calculated(aim_x: float)

var aim_x: float = 0.0

func _on_dragging(cur, start):
	if not preview_line: return
	aim_x = clampf((cur.x - start.x) / aim_sensitivity, -1.0, 1.0)
	preview_line.clear_points()
	preview_line.add_point(Vector2.ZERO)
	preview_line.add_point(Vector2(aim_x * preview_length, 0))

func _on_gesture_ended(aim_points, was_straight):
	if was_straight:
		aim_x = 0.0
		aim_calculated.emit(0.0)
		return
	if aim_points.size() < 2:
		aim_x = 0.0
		aim_calculated.emit(0.0)
		return
	aim_x = clampf((aim_points[aim_points.size() - 1].x - aim_points[0].x) / aim_sensitivity, -1.0, 1.0)
	preview_line.clear_points()
	aim_calculated.emit(aim_x)

func connect_signals():
	if not tracker:
		return
	tracker.gesture_dragging.connect(_on_dragging)
	tracker.gesture_ended.connect(_on_gesture_ended)
