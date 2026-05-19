extends Node
class_name GestureDirection

@export var tracker: GestureTracker
@export var preview_line: Line2D
@export var preview_length: float = 150.0
@export var aim_sensitivity: float = 300.0

signal aim_calculated(aim_x: float)

func _ready():
	if not tracker: return
	tracker.gesture_dragging.connect(_on_dragging)
	tracker.gesture_ended.connect(_on_gesture_ended)

func _on_dragging(cur, start):
	if not preview_line: return
	var aim_x = clampf((cur.x - start.x) / aim_sensitivity, -1.0, 1.0)
	preview_line.clear_points()
	preview_line.add_point(Vector2.ZERO)
	preview_line.add_point(Vector2(aim_x * preview_length, 0))

func _on_gesture_ended(points):
	if points.size() < 2: return
	var aim_x = clampf((points[points.size() - 1].x - points[0].x) / aim_sensitivity, -1.0, 1.0)
	preview_line.clear_points()
	aim_calculated.emit(aim_x)
