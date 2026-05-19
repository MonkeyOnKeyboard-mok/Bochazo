extends Node
class_name GesturePower

@export var tracker: GestureTracker
@export var max_drag_px: float = 300.0
@export var bar: ProgressBar

var peak_value: float = 0.0

func _ready():
	if not tracker or not bar: return
	tracker.gesture_started.connect(_reset)
	tracker.gesture_dragging.connect(_update)

func _reset(_s):
	bar.value = 0.0
	peak_value = 0.0

func _update(cur, start):
	var current = clampf((cur.y - start.y) / max_drag_px, 0.0, 1.0) * 100.0
	peak_value = maxf(peak_value, current)
	bar.value = peak_value
