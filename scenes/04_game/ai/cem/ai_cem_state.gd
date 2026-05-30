class_name AICEMState
extends RefCounted

const STATE_SIZE: int = 10
const MAX_DISTANCE: float = 50.0
const MIN_FRIC: float = 0.5
const MAX_FRIC: float = 1.2
const MIN_POT: float = 25.0
const MAX_POT: float = 50.0

static func encode(ball_pos: Vector3, bochin_pos: Vector3, court_friction: float, potencia: float, efecto: float, obstacles: Array = []) -> Array:
	var state = []
	var to_bochin = bochin_pos - ball_pos
	to_bochin.y = 0.0
	var dist = to_bochin.length()
	var dir = to_bochin.normalized() if dist > 0.1 else Vector3.FORWARD

	state.append(clampf(dir.x, -1.0, 1.0))
	state.append(clampf(dir.z, -1.0, 1.0))
	state.append(clampf(dist / MAX_DISTANCE, 0.0, 1.0))
	state.append(clampf((court_friction - MIN_FRIC) / (MAX_FRIC - MIN_FRIC), 0.0, 1.0))
	state.append(clampf((potencia - MIN_POT) / (MAX_POT - MIN_POT), 0.0, 1.0))
	state.append(clampf(efecto, 0.0, 1.0))

	var nearest_dist = 1.0
	var nearest_angle = 0.0
	var density = 0.0
	var nearby_count_norm = 0.0

	var throw_dir = dir
	var relevant: Array = []
	for obs_pos in obstacles:
		if not obs_pos is Vector3:
			continue
		var to_obs: Vector3 = obs_pos - ball_pos
		to_obs.y = 0.0
		var proj = to_obs.dot(throw_dir)
		if proj > 0.0 and proj < dist:
			var proj_vec = throw_dir * proj
			var diff = to_obs - proj_vec
			diff.y = 0.0
			var lateral = diff.length()
			relevant.append({"pos": obs_pos, "lateral": lateral})

	if relevant.size() > 0:
		relevant.sort_custom(func(a, b): return a["lateral"] < b["lateral"])
		var nearest = relevant[0]
		nearest_dist = clampf(1.0 - nearest["lateral"] / 5.0, 0.0, 1.0)
		var obs_dir: Vector3 = nearest["pos"] - ball_pos
		obs_dir.y = 0.0
		if obs_dir.length() > 0.1:
			obs_dir = obs_dir.normalized()
			nearest_angle = clampf(throw_dir.cross(obs_dir).y, -1.0, 1.0)

	var bochin_dists: Array[float] = []
	for obs_pos in obstacles:
		if not obs_pos is Vector3:
			continue
		bochin_dists.append(float(Vector3(obs_pos).distance_to(bochin_pos)))
	bochin_dists.sort()
	var cnt = mini(bochin_dists.size(), 3)
	var inv_sum = 0.0
	for i in range(cnt):
		inv_sum += 1.0 / maxf(bochin_dists[i], 0.5)
	density = clampf(inv_sum / 3.0, 0.0, 1.0)
	nearby_count_norm = clampf(float(obstacles.size()) / 6.0, 0.0, 1.0)

	state.append(nearest_dist)
	state.append(nearest_angle)
	state.append(density)
	state.append(nearby_count_norm)

	return state

static func encode_from_game(ball_pos: Vector3, bochin_pos: Vector3, court_type: int, stats: PlayerThrowStats, bochas: Array = []) -> Array:
	var court_frictions: Array[float] = [1.0, 0.8, 0.9, 1.1, 0.6]
	var friction = court_frictions[court_type] if court_type >= 0 and court_type < 5 else 1.0

	var obstacles: Array = []
	for b in bochas:
		if not b or not is_instance_valid(b):
			continue
		if b is Node3D:
			obstacles.append(b.global_position)

	return encode(ball_pos, bochin_pos, friction, stats.potencia, stats.efecto, obstacles)