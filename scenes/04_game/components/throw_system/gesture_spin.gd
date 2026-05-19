extends Node
class_name GestureSpin

@export var tracker: GestureTracker
@export var sensitivity: float = 100.0

signal spin_calculated(curve: float)

func _ready():
	if not tracker: return
	tracker.gesture_ended.connect(_calc_curve)

func _calc_curve(points: PackedVector2Array):
	if points.size() < 3:
		spin_calculated.emit(0.0)
		return

	var start = points[0]
	var end = points[points.size() - 1]
	var dir = (end - start).normalized()
	if dir.length() < 0.1: dir = Vector2(0, 1)

	var perp = Vector2(-dir.y, dir.x)
	var total = 0.0

	for p in points:
		var lateral = (p - start).dot(perp) / sensitivity
		total += clampf(lateral, -1.0, 1.0)

	spin_calculated.emit(clampf(total / points.size(), -1.0, 1.0))
