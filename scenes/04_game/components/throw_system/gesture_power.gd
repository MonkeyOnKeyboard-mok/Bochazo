extends Node
class_name GesturePower

var tracker: GestureTracker
var bar: ProgressBar
var max_drag_px: float = 300.0
var power_frac: float = 0.0

func _reset(_pos: Vector2):
	power_frac = 0.0
	if bar: bar.value = 0.0

func _on_dragging(cur: Vector2, start: Vector2):
	var raw = absf(cur.y - start.y)
	power_frac = clampf(raw / max_drag_px, 0.0, 1.0)
	if bar: bar.value = power_frac * 100.0
