class_name AIThrowBrain
extends Node

var policies: Array = []
var difficulty_sigma: float = 0.15
var flight: ThrowFlight
var ball: RigidBody3D
var stats: PlayerThrowStats
var last_params: AIThrowParams
var rng: RandomNumberGenerator

const SIGMA_BY_DIFFICULTY: Array[float] = [0.35, 0.25, 0.15, 0.08, 0.02]
const COURT_FRICTIONS: Array[float] = [1.0, 0.8, 0.9, 1.1, 0.6]

func _init():
	rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(5):
		policies.append(AICEMPolicy.new())

func load_weights(path: String) -> bool:
	if path.ends_with(".tres"):
		if ResourceLoader.exists(path):
			var weights_res = load(path) as AICEMWeights
			if weights_res:
				if weights_res.all_policies_weights.size() >= 5:
					var loaded_policies = weights_res.to_policies()
					for i in range(min(5, loaded_policies.size())):
						policies[i] = loaded_policies[i]
					return true
				else:
					policies[0] = weights_res.to_policy()
					return true
		return false
	var policy = AICEMPolicy.load_from_json(path)
	if policy:
		for i in range(5):
			policies[i] = policy
		return true
	return false

func set_difficulty(diff: int):
	difficulty_sigma = SIGMA_BY_DIFFICULTY[clampi(diff, 0, 4)]

func decide(ball_pos: Vector3, bochin_pos: Vector3, court_type: int, bochas: Array = []) -> AIThrowParams:
	var policy = policies[clampi(court_type, 0, 4)]

	if not policy:
		return _fallback_throw(ball_pos, bochin_pos)

	var court_friction = COURT_FRICTIONS[clampi(court_type, 0, 4)]
	var obstacles: Array = []
	for b in bochas:
		if not b or not is_instance_valid(b):
			continue
		if b is Node3D:
			obstacles.append(b.global_position)

	var state = AICEMState.encode(
		ball_pos, bochin_pos, court_friction,
		stats.potencia if stats else 35.0,
		stats.efecto if stats else 0.5,
		obstacles
	)

	var action = policy.compute_action(state)
	action = policy.add_noise(action, difficulty_sigma, rng)

	var p = AICEMPolicy.map_action_to_params(action)
	p.compute_direction(ball_pos, bochin_pos)
	p.compute_waypoints(ball_pos, bochin_pos)
	last_params = p
	return p

func execute_throw(ball_pos: Vector3, bochin_pos: Vector3, court_type: int, bochas: Array = []):
	var p = decide(ball_pos, bochin_pos, court_type, bochas)
	if not flight or not ball:
		return
	_setup_flight()
	if p.is_straight or p.waypoints.size() < 2:
		flight.launch_straight(p.power, p.direction)
	else:
		flight.launch(p.power, p.direction, p.waypoints)

func setup_for_throw(stats_res: PlayerThrowStats, ball_ref: RigidBody3D, flight_ref: ThrowFlight):
	stats = stats_res
	ball = ball_ref
	flight = flight_ref

func _fallback_throw(ball_pos: Vector3, bochin_pos: Vector3) -> AIThrowParams:
	var p = AIThrowParams.new()
	var dist = ball_pos.distance_to(bochin_pos)
	p.power = clampf(dist / 30.0, 0.3, 1.0)
	p.angle_offset = 0.0
	p.is_straight = true
	p.curve_intensity = 0.0
	p.curve_side = 1.0
	p.compute_direction(ball_pos, bochin_pos)
	return p

func _setup_flight():
	if not flight or not stats:
		return
	flight.efecto = stats.efecto
	flight.precision = stats.precision
	flight.control = stats.control
	flight.max_force = stats.potencia
	flight.min_power = stats.min_power
	flight.ball = ball