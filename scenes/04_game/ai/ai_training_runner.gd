class_name AITrainingRunner
extends Node

var ball_scene: PackedScene
var spawn_pos: Vector3 = Vector3(-25, 1, 0)
var stats: PlayerThrowStats
var ball_parent: Node

var db: AISpatialDB
var current_iteration: int = 0
var total_throws: int = 0
var is_done: bool = false

var total_iterations: int = 500
var balls_per_batch: int = 10
var court_configs: Array[AICourtConfig] = []
var current_court: Node = null

const COURT_LENGTH: float = 35.0
const COURT_WIDTH: float = 13.0
const BALL_Y: float = 1.0
const SPAWN_X: float = -25.0

const COURT_SCENES: Array[String] = [
	"res://scenes/04_game/components/court/flat_court.tscn",
	"res://scenes/04_game/components/court/dirty_court.tscn",
	"res://scenes/04_game/components/court/grass_court.tscn",
	"res://scenes/04_game/components/court/pro_court.tscn",
	"res://scenes/04_game/components/court/sand_court.tscn"
]

const COURT_FRICTIONS: Array[float] = [1.0, 0.8, 0.9, 1.1, 0.6]
const COURT_NAMES: Array[String] = ["Flat", "Dirty", "Grass", "Pro", "Sand"]

signal iteration_completed(iteration: int, throws: int, buckets: int)
signal training_complete()
signal progress_update(msg: String)
signal bochin_spawned(pos: Vector3)
signal court_changed(court_type: int, court_name: String)

var _pending: int = 0
var _results: Array[Vector3] = []
var _balls: Array = []
var _flights: Array = []
var _batch_params: Array[AIThrowParams] = []
var _batch_bochin_pos: Vector3 = Vector3.ZERO
var _current_court_type: int = 0

func start_training(iterations: int):
	is_done = false
	current_iteration = 0
	total_throws = 0
	total_iterations = iterations
	db = AISpatialDB.new()
	_court_configs_setup()
	_run_training()

func _court_configs_setup():
	court_configs.clear()
	for i in range(5):
		var c = AICourtConfig.new()
		c.court_type = i
		c.court_name = COURT_NAMES[i]
		c.court_friction = COURT_FRICTIONS[i]
		c.court_bounce = 0.3
		c.court_scene_path = COURT_SCENES[i]
		court_configs.append(c)

func _run_training():
	for i in range(total_iterations):
		current_iteration = i
		_current_court_type = i % court_configs.size()
		var cfg = court_configs[_current_court_type]
		_swap_court(cfg)
		court_changed.emit(_current_court_type, cfg.court_name)

		_batch_bochin_pos = Vector3(
			randf_range(0.0, COURT_LENGTH),
			BALL_Y,
			randf_range(-COURT_WIDTH / 2.0 + 0.5, COURT_WIDTH / 2.0 - 0.5)
		)
		bochin_spawned.emit(_batch_bochin_pos)

		var start_positions: Array[Vector3] = []
		_batch_params.clear()
		for j in range(balls_per_batch):
			start_positions.append(Vector3(SPAWN_X, BALL_Y, randf_range(-COURT_WIDTH / 2.0 + 0.5, COURT_WIDTH / 2.0 - 0.5)))
			_batch_params.append(_random_throw(start_positions[j], _batch_bochin_pos))

		var final_positions = await _simulate_batch(_batch_params, start_positions, _batch_bochin_pos)

		for j in range(balls_per_batch):
			var dist = final_positions[j].distance_to(_batch_bochin_pos)
			var initial_dist = start_positions[j].distance_to(_batch_bochin_pos)
			db.add_throw(_current_court_type, initial_dist, _batch_params[j], dist)
			total_throws += 1

		iteration_completed.emit(i, total_throws, db.bucket_count())
		progress_update.emit("Iter %d/%d | throws=%d | buckets=%d | court=%s" % [i + 1, total_iterations, total_throws, db.bucket_count(), cfg.court_name])

	is_done = true
	training_complete.emit()

func _swap_court(cfg: AICourtConfig):
	if current_court and is_instance_valid(current_court):
		current_court.queue_free()
		current_court = null
		await get_tree().process_frame
	var scene = load(cfg.court_scene_path) as PackedScene
	if scene:
		current_court = scene.instantiate()
		ball_parent.add_child(current_court)
		var court_node = current_court as StaticBody3D
		if court_node:
			var mat = PhysicsMaterial.new()
			mat.friction = cfg.court_friction
			mat.bounce = cfg.court_bounce
			court_node.physics_material_override = mat
		await get_tree().process_frame

func _random_throw(spawn: Vector3, target: Vector3) -> AIThrowParams:
	var p = AIThrowParams.new()
	var r = randf()
	if r < 0.5:
		p.power = randf_range(0.08, 0.35)
	elif r < 0.8:
		p.power = randf_range(0.3, 0.6)
	else:
		p.power = randf_range(0.55, 0.95)
	p.angle_offset = randf_range(-0.12, 0.12)
	p.is_straight = randf() < 0.3
	if p.is_straight:
		p.curve_intensity = 0.0
	else:
		p.curve_intensity = randf_range(0.1, 0.7)
	p.curve_side = 1.0 if randi() % 2 == 0 else -1.0
	return p

func _simulate_batch(params: Array[AIThrowParams], start_positions: Array[Vector3], bp: Vector3) -> Array[Vector3]:
	var n = params.size()
	_results.resize(n)
	_balls.resize(n)
	_flights.resize(n)
	_pending = n

	for i in range(n):
		var ball = ball_scene.instantiate() as TrainingBall
		ball.global_position = start_positions[i]
		ball_parent.add_child(ball)
		ball.reset_at(start_positions[i])
		_balls[i] = ball
		ball.ball_stopped.connect(_on_ball_stopped.bind(i))

	await get_tree().process_frame

	for i in range(n):
		for j in range(i + 1, n):
			_balls[i].add_collision_exception_with(_balls[j])

	for i in range(n):
		var p = params[i]
		var sp = start_positions[i]
		var ball = _balls[i] as TrainingBall

		var direction = (bp - sp)
		direction.y = 0
		direction = direction.normalized() if direction.length() > 0.1 else Vector3.FORWARD
		direction = direction.rotated(Vector3.UP, p.angle_offset)
		var wps = p.compute_waypoints(sp, bp)
		var max_f = stats.potencia if stats else 35.0
		ball.apply_central_impulse(direction * p.power * max_f)

		var friction_mult = court_configs[_current_court_type].court_friction
		var flight_ref: ThrowFlight = null
		if not p.is_straight and wps.size() >= 2:
			flight_ref = ThrowFlight.new()
			add_child(flight_ref)
			flight_ref.ball = ball
			flight_ref.efecto = (stats.efecto if stats else 0.5) * friction_mult
			flight_ref.max_force = max_f
			flight_ref.precision = stats.precision if stats else 0.95
			flight_ref.control = stats.control if stats else 0.85
			flight_ref.launch(p.power, direction, wps)
		_flights[i] = flight_ref

	while _pending > 0:
		await get_tree().process_frame

	var final_results: Array[Vector3] = []
	final_results.assign(_results)

	for i in range(n):
		if is_instance_valid(_balls[i]):
			_balls[i].queue_free()
		if _flights[i] and is_instance_valid(_flights[i]):
			_flights[i].queue_free()
	_balls.clear()
	_flights.clear()

	return final_results

func _on_ball_stopped(pos: Vector3, idx: int):
	if pos == null and is_instance_valid(_balls[idx]):
		pos = _balls[idx].global_position
	_results[idx] = pos
	_pending -= 1
