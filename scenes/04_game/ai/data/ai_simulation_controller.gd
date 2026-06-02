class_name AISimulationController
extends Node3D

@export var ball_scene: PackedScene
@export var iterations: int = 50
@export var balls_per_iter: int = 100
@export var max_force: float = 35.0
@export var efecto_val: float = 0.6
@export var precision_val: float = 0.95
@export var control_val: float = 0.85
@export var bounds_min_x: float = -1.0
@export var bounds_max_x: float = 36.0
@export var bounds_min_z: float = -7.0
@export var bounds_max_z: float = 7.0

const BALL_Y: float = 1.0
const SPAWN_X: float = -25.0
const COURT_FRICTIONS: Array[float] = [1.0, 0.8, 0.9, 1.1, 0.6]
const COURT_NAMES: Array[String] = ["Flat", "Dirty", "Grass", "Pro", "Sand"]
const COURT_SCENES: Array[String] = [
	"res://scenes/04_game/components/court/flat_court.tscn",
	"res://scenes/04_game/components/court/dirty_court.tscn",
	"res://scenes/04_game/components/court/grass_court.tscn",
	"res://scenes/04_game/components/court/pro_court.tscn",
	"res://scenes/04_game/components/court/sand_court.tscn"
]

@onready var run_btn: Button = $CanvasLayer/RunBtn
@onready var cancel_btn: Button = $CanvasLayer/CancelBtn
@onready var status_lbl: Label = $CanvasLayer/StatusLbl
@onready var progress_lbl: Label = $CanvasLayer/ProgressLbl
@onready var bocha_pos: Marker3D = $BochaPos

var _ball_pool: Array[RigidBody3D] = []
var _flight_pool: Array[ThrowFlight] = []
var _pending: int = 0
var _batch_results: Array = []
var _throw_params: Array = []
var _results: Array = []
var _is_running: bool = false
var _cancel: bool = false
var _current_court: Node = null
var _current_court_idx: int = -1
var _rng: RandomNumberGenerator

func _ready():
	GameManager.throw_for_real = true
	GameManager.permission_to_throw = true
	GameManager.is_training = true
	run_btn.pressed.connect(_on_run)
	cancel_btn.pressed.connect(_on_cancel)
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

func _on_run():
	if _is_running:
		return
	if not ball_scene:
		status_lbl.text = "ERROR: No ball scene!"
		return
	_is_running = true
	_cancel = false
	run_btn.disabled = true
	_build_pool()
	await _run_all_simulations()
	_teardown_pool()
	_is_running = false
	run_btn.disabled = false

func _on_cancel():
	_cancel = true

func _build_pool():
	for i in range(balls_per_iter):
		var ball = ball_scene.instantiate() as RigidBody3D
		ball.training_mode = true
		ball.collision_layer = 4  # Layer 3 (bochas)
		ball.collision_mask = 1   # Solo colisiona con Layer 1 (cancha)
		ball.visible = false
		ball.freeze = true
		add_child(ball)
		_ball_pool.append(ball)
		var flight = ThrowFlight.new()
		add_child(flight)
		_flight_pool.append(flight)

func _teardown_pool():
	for ball in _ball_pool:
		if is_instance_valid(ball):
			ball.queue_free()
	for flight in _flight_pool:
		if is_instance_valid(flight):
			flight.queue_free()
	_ball_pool.clear()
	_flight_pool.clear()

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
			court_node.collision_layer = 1  # Layer 1 (cancha)
			court_node.collision_mask = 4   # Colisiona con Layer 3 (bochas)
	_current_court_idx = court_idx

func _run_all_simulations():
	DirAccess.make_dir_recursive_absolute("res://resources/ai_data/")
	for ci in range(5):
		if _cancel:
			break
		_results.clear()
		await _swap_court(ci)
		status_lbl.text = "Simulating court: %s (%d/%d)" % [COURT_NAMES[ci], ci + 1, 5]
		for iteration in range(iterations):
			if _cancel:
				break
			progress_lbl.text = "Court %s | Iter %d/%d | Valid: %d" % [COURT_NAMES[ci], iteration + 1, iterations, _results.size()]
			await _run_iteration(ci, COURT_FRICTIONS[ci])
		_save_court_data(ci)
		progress_lbl.text = "Court %s done: %d valid throws" % [COURT_NAMES[ci], _results.size()]
	if not _cancel:
		status_lbl.text = "All done! 5 court files saved to res://resources/ai_data/"

func _run_iteration(_court_idx: int, court_friction: float):
	_pending = balls_per_iter
	_batch_results = []
	_batch_results.resize(balls_per_iter)
	for i in range(balls_per_iter):
		_batch_results[i] = Vector3(9999, -9999, 9999)
	_throw_params = []
	_throw_params.resize(balls_per_iter)

	for i in range(balls_per_iter):
		var ball = _ball_pool[i]
		var start_pos = bocha_pos.global_position
		_reset_ball(ball, start_pos)
		ball.stopped_moving.connect(_on_ball_stopped.bind(i), CONNECT_ONE_SHOT)

		var target_x = _rng.randf_range(2.0, 34.0)
		var target_z = _rng.randf_range(-6.0 + 0.5, 6.0 - 0.5)
		var target_pos = Vector3(target_x, BALL_Y, target_z)

		var power = _rng.randf_range(0.2, 1.0)
		var angle_offset = _rng.randf_range(-0.5, 0.5)
		var curve_intensity = _rng.randf_range(10, 100)
		var curve_side = _rng.randf_range(-1.0, 1.0)
		var is_straight = curve_intensity < 0.05

		var p = AIThrowParams.new()
		p.power = power
		p.angle_offset = angle_offset
		p.curve_intensity = curve_intensity
		p.curve_side = curve_side
		p.is_straight = is_straight
		var direction = p.compute_direction(start_pos, target_pos)
		var wps = p.compute_waypoints(start_pos, target_pos) if not is_straight else PackedVector3Array()

		_throw_params[i] = {
			"sx": start_pos.x, "sz": start_pos.z,
			"pw": power, "ang": angle_offset,
			"ci": curve_intensity, "cs": curve_side, "str": is_straight,
			"mf": max_force, "ef": efecto_val
		}

		var flight = _flight_pool[i]
		flight.ball = ball
		flight.max_force = max_force
		flight.efecto = efecto_val * court_friction
		flight.precision = precision_val
		flight.control = control_val

		if not is_straight and wps.size() >= 2:
			flight.launch(power, direction, wps)
		else:
			flight.launch_straight(power, direction)

	for i in range(balls_per_iter):
		for j in range(i + 1, balls_per_iter):
			_ball_pool[i].add_collision_exception_with(_ball_pool[j])

	while _pending > 0:
		await get_tree().physics_frame

	for i in range(balls_per_iter):
		var final_pos = _batch_results[i]
		var tp = _throw_params[i]
		if final_pos.x >= bounds_min_x and final_pos.x <= bounds_max_x and final_pos.z >= bounds_min_z and final_pos.z <= bounds_max_z:
			_results.append({
				"sx": tp["sx"], "sz": tp["sz"],
				"pw": tp["pw"], "ang": tp["ang"],
				"ci": tp["ci"], "cs": tp["cs"], "str": tp["str"],
				"mf": tp["mf"], "ef": tp["ef"],
				"fx": final_pos.x, "fz": final_pos.z
			})
		_ball_pool[i].visible = false
		_ball_pool[i].freeze = true
		_flight_pool[i]._active = false
		_flight_pool[i]._waypoints.clear()
		_flight_pool[i].ball = null
		for j in range(balls_per_iter):
			if i != j:
				_ball_pool[i].remove_collision_exception_with(_ball_pool[j])

func _on_ball_stopped(ball_ref, idx: int):
	if idx < _batch_results.size() and is_instance_valid(ball_ref):
		_batch_results[idx] = ball_ref.global_position
	_pending -= 1

func _reset_ball(ball: RigidBody3D, pos: Vector3):
	ball.is_thrown = true
	ball.global_position = pos
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.freeze = false
	ball.visible = true
	if "_is_stopped" in ball:
		ball._is_stopped = false
	if "_active_frames" in ball:
		ball._active_frames = 0
	if "_sim_time" in ball:
		ball._sim_time = 0.0
	if "training_mode" in ball:
		ball.training_mode = true

func _save_court_data(court_idx: int):
	var path = "res://resources/ai_data/throws_%s.json" % COURT_NAMES[court_idx].to_lower()
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		status_lbl.text = "ERROR saving %s" % path
		return
	var json_data = {
		"court": COURT_NAMES[court_idx],
		"friction": COURT_FRICTIONS[court_idx],
		"total_throws": _results.size(),
		"throws": _results
	}
	file.store_string(JSON.stringify(json_data, "\t"))
	file.close()
