extends Node
class_name GestureSpin

@export var tracker: GestureTracker
@export var sensitivity: float = 100.0 # ⚙️ GameSense: amplitud del efecto

signal spin_profile_calculated(values: PackedFloat32Array)

func _ready():
	if not tracker: return
	tracker.gesture_ended.connect(_calc_profile)

func _calc_profile(points: PackedVector2Array):
	if points.size() < 3:
		spin_profile_calculated.emit(PackedFloat32Array())
		return

	var start = points[0]
	var end = points[points.size() - 1]
	var dir = (end - start).normalized()
	if dir.length() < 0.1: dir = Vector2(1, 0)

	var perp = Vector2(-dir.y, dir.x) # 90° respecto al lanzamiento
	var profile: PackedFloat32Array

	for p in points:
		var lateral = (p - start).dot(perp) / sensitivity
		profile.append(clamp(lateral, -1.0, 1.0))

	spin_profile_calculated.emit(profile)
