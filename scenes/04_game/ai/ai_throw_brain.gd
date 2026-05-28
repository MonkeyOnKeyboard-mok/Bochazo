class_name AIThrowBrain
extends Node

var spatial_db: AISpatialDB
var difficulty: int = 0
var court_type: int = 0
var fallback_params: AIThrowParams

var flight: ThrowFlight
var ball: RigidBody3D
var stats: PlayerThrowStats
var last_params: AIThrowParams

func load_db(path: String) -> bool:
	spatial_db = AISpatialDB.load_from_json(path)
	if spatial_db:
		return true
	return false

func decide(context: AIContext) -> AIThrowParams:
	var dist = context.bochin_dist_norm * 30.0
	var ct = court_type
	var p = null
	if spatial_db:
		p = spatial_db.get_throw(ct, dist, difficulty)
	if p == null:
		p = _fallback_throw(dist)
	_adjust_for_context(p, context)
	if difficulty > 0:
		_apply_noise(p)
	last_params = p
	return p

func execute_throw(context: AIContext, ball_pos: Vector3, bochin_pos: Vector3):
	var p = decide(context)
	last_params = p
	p.direction = p.compute_direction(ball_pos, bochin_pos)
	p.waypoints = p.compute_waypoints(ball_pos, bochin_pos)
	_setup_flight()
	if p.is_straight or p.waypoints.size() < 2:
		flight.launch_straight(p.power, p.direction)
	else:
		flight.launch(p.power, p.direction, p.waypoints)

func setup_for_throw(stats_res: PlayerThrowStats, ball_ref: RigidBody3D, flight_ref: ThrowFlight):
	stats = stats_res
	ball = ball_ref
	flight = flight_ref

func _fallback_throw(dist: float) -> AIThrowParams:
	var p = AIThrowParams.new()
	p.power = clampf(dist / 30.0, 0.3, 1.0)
	p.angle_offset = 0.0
	p.is_straight = true
	p.curve_intensity = 0.0
	p.curve_side = 1.0
	return p

func _adjust_for_context(p: AIThrowParams, ctx: AIContext):
	p.power = clampf(p.power + (ctx.bochin_dist_norm - 0.5) * 0.2, 0.3, 1.0)
	if ctx.nearest_enemy_dist < 3.0:
		p.curve_intensity = clampf(p.curve_intensity + 0.2, 0.0, 1.0)
		p.is_straight = false

func _apply_noise(p: AIThrowParams):
	var noise_amount = float(difficulty) * 0.05
	p.power = clampf(p.power + randf_range(-noise_amount, noise_amount), 0.3, 1.0)
	p.angle_offset = clampf(p.angle_offset + randf_range(-noise_amount * 2, noise_amount * 2), -0.3, 0.3)
	if not p.is_straight:
		p.curve_intensity = clampf(p.curve_intensity + randf_range(-noise_amount, noise_amount), 0.0, 1.0)

func _setup_flight():
	flight.efecto = stats.efecto
	flight.precision = stats.precision
	flight.control = stats.control
	flight.max_force = stats.potencia
	flight.min_power = stats.min_power
	flight.ball = ball