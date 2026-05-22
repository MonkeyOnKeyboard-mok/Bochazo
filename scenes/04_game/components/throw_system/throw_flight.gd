extends Node
class_name ThrowFlight

var ball: RigidBody3D

var curve_strength: float = 0.5
var curve_duration: float = 3.0
var wobble_speed: float = 8.0
var wobble_force: float = 0.15

var _active: bool = false
var _mode: int = 0
var _time: float = 0.0
var _wobble_phase: float = 0.0
var _curve_profile: PackedFloat64Array = []
var _start_pos: Vector3 = Vector3.ZERO
var _total_dist: float = 0.0

enum Mode { STRAIGHT, KNUCKLEBALL, CURVE }

func start_straight():
	_active = false
	_mode = Mode.STRAIGHT

func start_knuckleball():
	_mode = Mode.KNUCKLEBALL
	_active = true
	_time = 0.0
	_wobble_phase = randf_range(0.0, TAU)
	_curve_profile.clear()
	_start_pos = ball.global_position
	var vel = ball.linear_velocity
	_total_dist = vel.length() * curve_duration if vel.length() > 0.1 else 0.0

func start_curve(aim_points: PackedVector2Array):
	if aim_points.size() < 3:
		start_straight()
		return

	_mode = Mode.CURVE
	_active = true
	_time = 0.0
	_curve_profile = _build_profile(aim_points)
	_start_pos = ball.global_position
	var vel = ball.linear_velocity
	_total_dist = vel.length() * curve_duration if vel.length() > 0.1 else 0.0

func _build_profile(points: PackedVector2Array) -> PackedFloat64Array:
	var smoothed = _smooth(points, 2)
	var start = smoothed[0]
	var end = smoothed[smoothed.size() - 1]
	var dir = (end - start).normalized()
	if dir.length() < 0.1:
		return PackedFloat64Array()

	var perp = Vector2(-dir.y, dir.x)
	var length = (end - start).length()
	if length < 10.0:
		return PackedFloat64Array()

	var profile = PackedFloat64Array()
	var samples = 30

	for i in range(samples):
		var t = float(i) / float(samples - 1)
		var line_point = start + dir * length * t

		var closest = _closest(smoothed, line_point)
		var lateral = (closest - line_point).dot(perp)

		profile.append(lateral / length)

	var max_val = 0.0
	for v in profile:
		if absf(v) > max_val:
			max_val = absf(v)

	if max_val > 0.001:
		for i in range(profile.size()):
			profile[i] = profile[i] / max_val

	return profile

func _smooth(points: PackedVector2Array, passes: int) -> PackedVector2Array:
	var result = points.duplicate()
	for _p in passes:
		if result.size() < 3:
			break
		var next = PackedVector2Array()
		next.append(result[0])
		for i in range(1, result.size() - 1):
			next.append(result[i - 1] * 0.25 + result[i] * 0.5 + result[i + 1] * 0.25)
		next.append(result[result.size() - 1])
		result = next
	return result

func _closest(points: PackedVector2Array, target: Vector2) -> Vector2:
	var best = points[0]
	var best_d = 1e18
	for p in points:
		var d = (p - target).length_squared()
		if d < best_d:
			best_d = d
			best = p
	return best

func _physics_process(delta):
	if not _active:
		return

	var vel = ball.linear_velocity
	if vel.length() < 0.1:
		_active = false
		return

	var traveled = (ball.global_position - _start_pos).length()
	var progress = 1.0
	if _total_dist > 0:
		progress = clampf(traveled / _total_dist, 0.0, 1.0)

	var lateral_force: float = 0.0

	match _mode:
		Mode.KNUCKLEBALL:
			_time += delta
			lateral_force = sin(_time * wobble_speed + _wobble_phase) * wobble_force

		Mode.CURVE:
			if _curve_profile.size() > 0:
				var idx = progress * float(_curve_profile.size() - 1)
				var i0 = int(floor(idx))
				var i1 = min(i0 + 1, _curve_profile.size() - 1)
				var t = idx - floor(idx)
				lateral_force = lerp(_curve_profile[i0], _curve_profile[i1], t) * curve_strength

	if absf(lateral_force) > 0.001:
		var right = ball.global_transform.basis.x
		ball.apply_central_force(right * lateral_force)

	if progress >= 1.0:
		_active = false
