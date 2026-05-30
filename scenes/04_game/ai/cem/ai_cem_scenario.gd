class_name AICEMScenario
extends RefCounted

const COURT_FRICTIONS: Array[float] = [1.0, 0.8, 0.9, 1.1, 0.6]
const COURT_LENGTH: float = 35.0
const COURT_WIDTH: float = 13.0
const BALL_Y: float = 1.0
const SPAWN_X: float = -25.0
const MAX_DISTANCE: float = 50.0
const MIN_FRIC: float = 0.5
const MAX_FRIC: float = 1.2
const MIN_POT: float = 25.0
const MAX_POT: float = 50.0

static func generate(rng: RandomNumberGenerator, court_idx: int = -1) -> Dictionary:
	if court_idx < 0:
		court_idx = rng.randi() % 5
	var court_friction = COURT_FRICTIONS[court_idx]

	var bochin_x = _gaussian_bias(rng, COURT_LENGTH / 2.0, COURT_LENGTH / 4.0, 2.0, COURT_LENGTH - 2.0)
	var bochin_z = _gaussian_bias(rng, 0.0, COURT_WIDTH / 4.0, -COURT_WIDTH / 2.0 + 0.5, COURT_WIDTH / 2.0 - 0.5)
	var bochin_pos = Vector3(bochin_x, BALL_Y, bochin_z)

	var ball_x = SPAWN_X + rng.randf_range(0.0, 3.0)
	var ball_z = rng.randf_range(-COURT_WIDTH / 2.0 + 0.5, COURT_WIDTH / 2.0 - 0.5)
	var ball_pos = Vector3(ball_x, BALL_Y, ball_z)

	var num_obstacles = rng.randi() % 7
	var obstacles: Array = []
	var pattern = rng.randi() % 3

	for i in range(num_obstacles):
		var obs_pos: Vector3
		match pattern:
			0:
				var ang = rng.randf() * TAU
				var rad = rng.randf_range(1.5, 3.0)
				obs_pos = Vector3(bochin_x + cos(ang) * rad, BALL_Y, bochin_z + sin(ang) * rad)
			1:
				var t = float(i) / max(num_obstacles - 1, 1) if num_obstacles > 1 else 0.5
				var offset = rng.randf_range(1.5, 2.5)
				obs_pos = Vector3(bochin_x + offset * (i % 2 * 2 - 1), BALL_Y, bochin_z + (t - 0.5) * 4.0)
			2:
				var ang = PI + (float(i) / max(num_obstacles, 1)) * PI * 0.8 - PI * 0.4
				var rad = rng.randf_range(1.5, 2.5)
				obs_pos = Vector3(bochin_x + cos(ang) * rad, BALL_Y, bochin_z + sin(ang) * rad)
		obs_pos.x = clampf(obs_pos.x, 0.5, COURT_LENGTH - 0.5)
		obs_pos.z = clampf(obs_pos.z, -COURT_WIDTH / 2.0 + 0.5, COURT_WIDTH / 2.0 - 0.5)

		var valid = true
		for other in obstacles:
			if obs_pos.distance_to(other) < 0.3:
				valid = false
				break
		if obs_pos.distance_to(bochin_pos) < 0.3:
			valid = false
		if valid:
			obstacles.append(obs_pos)

	var potencia = rng.randf_range(MIN_POT, MAX_POT)
	var efecto = rng.randf_range(0.3, 0.9)

	var state = AICEMState.encode(ball_pos, bochin_pos, court_friction, potencia, efecto, obstacles)

	return {
		"court_idx": court_idx,
		"court_friction": court_friction,
		"bochin_pos": bochin_pos,
		"ball_pos": ball_pos,
		"obstacles": obstacles,
		"potencia": potencia,
		"efecto": efecto,
		"state": state
	}

static func generate_for_court(rng: RandomNumberGenerator, court_idx: int) -> Dictionary:
	return generate(rng, court_idx)

static func _gaussian_bias(rng: RandomNumberGenerator, mean: float, std: float, min_val: float, max_val: float) -> float:
	var val = rng.randfn(mean, std)
	return clampf(val, min_val, max_val)