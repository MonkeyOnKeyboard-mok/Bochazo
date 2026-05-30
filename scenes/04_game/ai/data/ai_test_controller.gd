class_name AITestController
extends Node3D

@export var ball_scene: PackedScene
@export var stats: PlayerThrowStats

@onready var throw_btn: Button = $CanvasLayer/ThrowBtn
@onready var reset_btn: Button = $CanvasLayer/ResetBtn
@onready var load_btn: Button = $CanvasLayer/LoadBtn
@onready var noise_slider: HSlider = $CanvasLayer/NoiseSlider
@onready var noise_lbl: Label = $CanvasLayer/NoiseLbl
@onready var curve_slider: HSlider = $CanvasLayer/CurveSlider
@onready var curve_lbl: Label = $CanvasLayer/CurveLbl
@onready var court_opt: OptionButton = $CanvasLayer/CourtOpt
@onready var status_lbl: Label = $CanvasLayer/StatusLbl
@onready var result_lbl: Label = $CanvasLayer/ResultLbl
@onready var target_marker: Node3D = $TargetMarker

const BALL_Y: float = 1.0
const SPAWN_X: float = -25.0
const COURT_LENGTH: float = 35.0
const COURT_WIDTH: float = 13.0
const COURT_FRICTIONS: Array[float] = [1.0, 0.8, 0.9, 1.1, 0.6]
const COURT_NAMES: Array[String] = ["Flat", "Dirty", "Grass", "Pro", "Sand"]
const COURT_SCENES: Array[String] = [
	"res://scenes/04_game/components/court/flat_court.tscn",
	"res://scenes/04_game/components/court/dirty_court.tscn",
	"res://scenes/04_game/components/court/grass_court.tscn",
	"res://scenes/04_game/components/court/pro_court.tscn",
	"res://scenes/04_game/components/court/sand_court.tscn"
]

var model: AIInverseModel
var rng: RandomNumberGenerator
var _balls: Array[RigidBody3D] = []
var _flights: Array[ThrowFlight] = []
var _current_court: Node = null
var _current_court_idx: int = -1
var _throw_count: int = 0
var _indexed_dist: float = 0.0
var _function_dist: float = 0.0
var _indexed_wins: int = 0
var _function_wins: int = 0
var _pending: int = 0
var _results: Array = []

func _ready():
	throw_btn.pressed.connect(_on_throw)
	reset_btn.pressed.connect(_on_reset)
	load_btn.pressed.connect(_on_load)
	rng = RandomNumberGenerator.new()
	rng.randomize()
	model = AIInverseModel.new()
	_populate_courts()
	noise_slider.value = 0.5
	noise_slider.min_value = 0.0
	noise_slider.max_value = 1.0
	noise_slider.step = 0.05
	noise_lbl.text = "Noise: 0.50m"
	curve_slider.value = 0.5
	curve_slider.min_value = 0.0
	curve_slider.max_value = 2.0
	curve_slider.step = 0.1
	curve_lbl.text = "Curve Pref: 0.5"

func _process(_delta):
	noise_lbl.text = "Noise: %.2fm" % noise_slider.value
	curve_lbl.text = "Curve Pref: %.1f" % curve_slider.value
	model.curve_preference = curve_slider.value

func _populate_courts():
	for cn in COURT_NAMES:
		court_opt.add_item(cn)

func _on_load():
	var ok = model.load_all()
	if not ok:
		status_lbl.text = "ERROR: No data! Run simulation first."
		return
	var total = 0
	for cn in COURT_NAMES:
		total += model.get_throw_count(COURT_NAMES.find(cn))
	status_lbl.text = "Loaded! %d throws" % total

func _on_throw():
	if model.throws_by_court.size() == 0:
		status_lbl.text = "Load data first!"
		return
	if model.get_throw_count(court_opt.get_selected_id()) == 0:
		status_lbl.text = "No data for this court!"
		return

	var court_idx = court_opt.get_selected_id()
	await _swap_court(court_idx)

	var noise_radius = noise_slider.value
	var target_x = rng.randf_range(3.0, COURT_LENGTH - 3.0)
	var target_z = rng.randf_range(-COURT_WIDTH / 2.0 + 1.0, COURT_WIDTH / 2.0 - 1.0)
	if noise_radius > 0:
		var angle = rng.randf() * TAU
		var dist = rng.randf() * noise_radius
		target_x += cos(angle) * dist
		target_z += sin(angle) * dist
	target_x = clampf(target_x, 2.0, COURT_LENGTH - 2.0)
	target_z = clampf(target_z, -COURT_WIDTH / 2.0 + 0.5, COURT_WIDTH / 2.0 - 0.5)
	var target_pos = Vector3(target_x, BALL_Y, target_z)
	target_marker.global_position = target_pos

	var start_z = rng.randf_range(-COURT_WIDTH / 2.0 + 1.0, COURT_WIDTH / 2.0 - 1.0)
	var start_pos = Vector3(SPAWN_X, BALL_Y, start_z)

	var indexed_params = model.find_nearest(target_x, target_z, court_idx)
	var function_params = model.find_function(target_x, target_z, court_idx)

	if indexed_params.is_empty() or function_params.is_empty():
		status_lbl.text = "No matching throws found!"
		return

	_clear_balls()

	status_lbl.text = "Throwing INDEXED..."
	_pending = 1
	_results = []
	_results.resize(2)
	_results[0] = Vector3(9999, -9999, 9999)
	_results[1] = Vector3(9999, -9999, 9999)

	var ball_i = _spawn_ball(start_pos)
	var dir_i = _compute_direction(start_pos, target_pos, indexed_params)

	var flight_i = ThrowFlight.new()
	add_child(flight_i)
	flight_i.ball = ball_i
	flight_i.max_force = float(indexed_params.get("mf", 35.0))
	flight_i.efecto = float(indexed_params.get("ef", 0.6)) * COURT_FRICTIONS[court_idx]
	flight_i.precision = 0.95
	flight_i.control = 0.85
	var pw_i = float(indexed_params["pw"])
	var ci_i = float(indexed_params["ci"])
	var straight_i = bool(indexed_params["str"])
	if not straight_i and ci_i >= 0.05:
		var wps_i = _compute_waypoints(start_pos, target_pos, float(indexed_params["ang"]), float(indexed_params["cs"]), ci_i)
		flight_i.launch(pw_i, dir_i, wps_i)
	else:
		flight_i.launch_straight(pw_i, dir_i)
	ball_i.stopped_moving.connect(_on_ball_stopped.bind(0), CONNECT_ONE_SHOT)
	_flights.append(flight_i)

	while _pending > 0:
		await get_tree().physics_frame

	await get_tree().create_timer(0.3).timeout

	status_lbl.text = "Throwing FUNCTION..."

	_pending = 1
	var ball_f = _spawn_ball(start_pos)
	var dir_f = _compute_direction(start_pos, target_pos, function_params)

	var flight_f = ThrowFlight.new()
	add_child(flight_f)
	flight_f.ball = ball_f
	flight_f.max_force = float(function_params.get("mf", 35.0))
	flight_f.efecto = float(function_params.get("ef", 0.6)) * COURT_FRICTIONS[court_idx]
	flight_f.precision = 0.95
	flight_f.control = 0.85
	var pw_f = float(function_params["pw"])
	var ci_f = float(function_params["ci"])
	var straight_f = bool(function_params["str"])
	if not straight_f and ci_f >= 0.05:
		var wps_f = _compute_waypoints(start_pos, target_pos, float(function_params["ang"]), float(function_params["cs"]), ci_f)
		flight_f.launch(pw_f, dir_f, wps_f)
	else:
		flight_f.launch_straight(pw_f, dir_f)
	ball_f.stopped_moving.connect(_on_ball_stopped.bind(1), CONNECT_ONE_SHOT)
	_flights.append(flight_f)

	while _pending > 0:
		await get_tree().physics_frame

	_indexed_dist = _results[0].distance_to(target_pos)
	_function_dist = _results[1].distance_to(target_pos)

	var winner = ""
	if _indexed_dist < _function_dist:
		_indexed_wins += 1
		winner = "INDEXED wins!"
	elif _function_dist < _indexed_dist:
		_function_wins += 1
		winner = "FUNCTION wins!"
	else:
		winner = "TIE!"

	_throw_count += 1
	status_lbl.text = "Throw #%d | %s | Noise: %.2fm" % [_throw_count, COURT_NAMES[court_idx], noise_slider.value]
	result_lbl.text = "Indexed: %.2fm | Function: %.2fm | %s\nTotal: I=%d F=%d" % [
		_indexed_dist, _function_dist, winner, _indexed_wins, _function_wins]

func _compute_direction(start_pos: Vector3, target_pos: Vector3, params: Dictionary) -> Vector3:
	var dir = (target_pos - start_pos)
	dir.y = 0
	if dir.length() < 0.1:
		return Vector3.FORWARD
	return dir.normalized().rotated(Vector3.UP, float(params.get("ang", 0.0)))

func _compute_waypoints(start_pos: Vector3, target_pos: Vector3, angle_offset: float, curve_side: float, curve_intensity: float) -> PackedVector3Array:
	var raw_dir = (target_pos - start_pos)
	raw_dir.y = 0
	if raw_dir.length() < 0.1:
		raw_dir = Vector3.FORWARD
	else:
		raw_dir = raw_dir.normalized()
	var dir = raw_dir.rotated(Vector3.UP, angle_offset)
	var right = dir.cross(Vector3.UP).normalized()
	var dist = start_pos.distance_to(target_pos)
	var wp_count = clampi(int(3 + curve_intensity * 8), 4, 12)
	var wps: PackedVector3Array = []
	for i in range(wp_count):
		var t = float(i) / float(wp_count - 1)
		var pos = start_pos + dir * dist * t * 1.1
		var lateral = sin(t * PI) * curve_intensity * curve_side * dist * 0.3
		pos += right * lateral
		pos.y = start_pos.y
		wps.append(pos)
	return wps

func _spawn_ball(pos: Vector3) -> RigidBody3D:
	var ball = ball_scene.instantiate() as RigidBody3D
	if "training_mode" in ball:
		ball.training_mode = true
	if "player" in ball:
		ball.player = ""
	add_child(ball)
	ball.global_position = pos
	ball.freeze = false
	if "_is_stopped" in ball:
		ball._is_stopped = false
	_balls.append(ball)
	return ball

func _clear_balls():
	for ball in _balls:
		if is_instance_valid(ball):
			ball.queue_free()
	_balls.clear()
	for flight in _flights:
		if is_instance_valid(flight):
			flight.queue_free()
	_flights.clear()

func _on_ball_stopped(ball_ref, idx: int):
	if idx < _results.size() and is_instance_valid(ball_ref):
		_results[idx] = ball_ref.global_position
	_pending -= 1

func _on_reset():
	_clear_balls()
	_throw_count = 0
	_indexed_wins = 0
	_function_wins = 0
	_indexed_dist = 0.0
	_function_dist = 0.0
	status_lbl.text = "Ready"
	result_lbl.text = ""

func _swap_court(court_idx: int):
	if court_idx == _current_court_idx:
		return
	if _current_court and is_instance_valid(_current_court):
		_current_court.queue_free()
		_current_court = null
		await get_tree().process_frame
	var scene = load(COURT_SCENES[court_idx]) as PackedScene
	if scene:
		_current_court = scene.instantiate()
		add_child(_current_court)
		var court_node = _current_court as StaticBody3D
		if court_node:
			var mat = PhysicsMaterial.new()
			mat.friction = COURT_FRICTIONS[court_idx]
			mat.bounce = 0.3
			court_node.physics_material_override = mat
	_current_court_idx = court_idx