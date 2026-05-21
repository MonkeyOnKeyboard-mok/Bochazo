extends Node
class_name ThrowHandler

var max_force: float = 35.0
var min_power: float = 0.05

var _tracker: GestureTracker
var _power_bar: ProgressBar
var _aim: ThrowAim
var _flight: ThrowFlight
var _direction: GestureDirection

func connect_signals():
	_tracker = _find("GestureTracker")
	_power_bar = _find("PowerBar")
	_aim = _find("ThrowAim")
	_flight = _find("ThrowFlight")
	_direction = _find("GestureDirection")

	if _tracker:
		_tracker.gesture_ended.connect(_on_throw)

func set_max_force(v: float):
	max_force = v

func set_min_power(v: float):
	min_power = v

func _on_throw(aim_points: PackedVector2Array, was_straight: bool):
	if not _power_bar:
		return

	var p = clampf(_power_bar.value / 100.0, 0.0, 1.0)
	if p < min_power:
		return

	if not _aim or not _flight or not _flight.ball:
		return

	var throw_dir = _aim.dir
	var aim_x = _direction.aim_x if _direction else 0.0

	if was_straight:
		print("[Throw] knuckleball | power: %d%%" % int(p * 100))
		_flight.ball.apply_central_impulse(throw_dir * p * max_force)
		_flight.start_knuckleball()
		return

	if aim_points.size() < 3:
		print("[Throw] straight | power: %d%% | aim: %.3f" % [int(p * 100), aim_x])
		_flight.ball.apply_central_impulse(throw_dir * p * max_force)
		_flight.start_straight()
		return

	print("[Throw] curve | power: %d%% | aim: %.3f | pts: %d" % [int(p * 100), aim_x, aim_points.size()])
	_flight.ball.apply_central_impulse(throw_dir * p * max_force)
	_flight.start_curve(aim_points)

func _find(name: String) -> Node:
	var n = find_child(name, true, false)
	if n:
		return n
	var parent = get_parent()
	if parent:
		n = parent.find_child(name, true, false)
		if n:
			return n
		var grand = parent.get_parent()
		if grand:
			return grand.find_child(name, true, false)
	return null
