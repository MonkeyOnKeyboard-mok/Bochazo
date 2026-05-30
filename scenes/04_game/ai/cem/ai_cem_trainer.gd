class_name AICEMTrainer
extends Node

signal iteration_done(iter: int, sigma: float, best_reward: float, avg_reward: float, best_dist: float, avg_dist: float, elite_count: int, court_stats: Dictionary)
signal court_swap_requested(court_idx: int)
signal scenario_started(bochin_pos: Vector3, ball_pos: Vector3, court_idx: int)
signal training_done()

var policies: Array = []
var sigmas: Array = []
var elite_ratio: float = 0.2
var sigma_decay: float = 0.92
var min_sigma: float = 0.02
var max_iterations: int = 100
var scenarios_per_iter: int = 50
var samples_per_scenario: int = 20
var convergence_patience: int = 5
var ridge_lambda: float = 0.01
var target_court: int = -1

var simulator: AICEMSimulator
var rng: RandomNumberGenerator
var is_training: bool = false
var current_iteration: int = 0
var total_throws: int = 0
var _current_scenario: Dictionary = {}

const COURT_NAMES: Array[String] = ["Flat", "Dirty", "Grass", "Pro", "Sand"]

var _cancel_requested: bool = false

func start_training(sim: AICEMSimulator, start_sigma: float = 0.5):
	if is_training:
		return
	is_training = true
	_cancel_requested = false
	simulator = sim
	rng = RandomNumberGenerator.new()
	rng.randomize()
	total_throws = 0

	var court_indices: Array
	if target_court >= 0:
		court_indices = [target_court]
		policies.clear()
		sigmas.clear()
		for i in range(5):
			policies.append(AICEMPolicy.new())
			sigmas.append(start_sigma)
	else:
		court_indices = [0, 1, 2, 3, 4]
		policies.clear()
		sigmas.clear()
		for i in range(5):
			policies.append(AICEMPolicy.new())
			sigmas.append(start_sigma)

	var consecutive_low_sigma = 0

	var last_court_idx = -1

	for iteration in range(max_iterations):
		if _cancel_requested:
			break
		current_iteration = iteration

		var all_data_by_court: Array = []
		for i in range(5):
			all_data_by_court.append([])

		var active_courts: Array
		if target_court >= 0:
			active_courts = [target_court]
		else:
			active_courts = range(5) as Array

		for ci in active_courts:
			if _cancel_requested:
				break

			if ci != last_court_idx:
				court_swap_requested.emit(ci)
				await get_tree().process_frame
				await get_tree().process_frame
				last_court_idx = ci

			for m in range(scenarios_per_iter):
				if _cancel_requested:
					break
				var scenario = AICEMScenario.generate_for_court(rng, ci)
				_current_scenario = scenario
				scenario_started.emit(scenario["bochin_pos"], scenario["ball_pos"], ci)
				var state: Array = scenario["state"]
				var policy = policies[ci] as AICEMPolicy
				var sigma_val = sigmas[ci]
				var mean_action = policy.compute_action(state)

				var actions: Array = []
				for k in range(samples_per_scenario):
					var noisy_action = policy.add_noise(mean_action, sigma_val, rng)
					actions.append(noisy_action)

				var rewards = await simulator.simulate_scenario(
					actions,
					scenario["bochin_pos"],
					scenario["ball_pos"],
					scenario["potencia"],
					scenario["efecto"],
					ci,
					scenario["obstacles"]
				)
				total_throws += actions.size()

				for k in range(actions.size()):
					all_data_by_court[ci].append({
						"state": state,
						"action": actions[k],
						"reward": rewards[k],
					})

		if _cancel_requested:
			break

		var global_best_reward = -1.0
		var global_avg_reward = 0.0
		var global_best_dist = 999.0
		var global_avg_dist = 0.0
		var total_elites = 0
		var court_stats: Dictionary = {}
		var courts_with_data = 0

		for ci in range(5):
			var data = all_data_by_court[ci]
			if data.size() == 0:
				court_stats[COURT_NAMES[ci]] = {"best_r": 0.0, "avg_r": 0.0, "best_d": 999.0, "avg_d": 999.0, "sigma": sigmas[ci], "n": 0}
				continue

			data.sort_custom(func(a, b): return a["reward"] > b["reward"])

			var elite_count = maxi(1, int(data.size() * elite_ratio))
			var elites = data.slice(0, elite_count)

			_update_policy_least_squares(policies[ci], elites)

			sigmas[ci] *= sigma_decay
			if sigmas[ci] < min_sigma:
				sigmas[ci] = min_sigma

			var best_r = elites[0]["reward"]
			var avg_r = 0.0
			var best_d = 999.0
			var avg_d = 0.0
			for e in elites:
				avg_r += e["reward"]
				var d = 1.0 / e["reward"] - 1.0
				avg_d += d
				if d < best_d:
					best_d = d
			avg_r /= elite_count
			avg_d /= elite_count

			if best_r > global_best_reward:
				global_best_reward = best_r
			global_avg_reward += avg_r
			if best_d < global_best_dist:
				global_best_dist = best_d
			global_avg_dist += best_d
			total_elites += elite_count
			courts_with_data += 1

			court_stats[COURT_NAMES[ci]] = {
				"best_r": best_r,
				"avg_r": avg_r,
				"best_d": best_d,
				"avg_d": avg_d,
				"sigma": sigmas[ci],
				"n": data.size(),
			}

		if courts_with_data > 0:
			global_avg_reward /= courts_with_data
			global_avg_dist /= courts_with_data

		iteration_done.emit(iteration, sigmas[active_courts[0]], global_best_reward, global_avg_reward, global_best_dist, global_avg_dist, total_elites, court_stats)

		var all_converged = true
		for ci in active_courts:
			if sigmas[ci] > min_sigma:
				all_converged = false
				break
		if all_converged:
			consecutive_low_sigma += 1
			if consecutive_low_sigma >= convergence_patience:
				break
		else:
			consecutive_low_sigma = 0

	is_training = false
	_current_scenario = {}
	training_done.emit()

func cancel_training():
	_cancel_requested = true

func _update_policy_least_squares(policy: AICEMPolicy, elites: Array):
	var states: Array = []
	var actions: Array = []
	for e in elites:
		states.append(e["state"])
		actions.append(e["action"])

	var augmented = AICEMMatrix.ragged_to_augmented(states, actions)
	var s_aug = augmented["s_aug"]
	var a = augmented["a"]

	if s_aug.size() == 0 or a.size() == 0:
		return

	var theta = AICEMMatrix.solve_least_squares(s_aug, a, ridge_lambda)

	var state_dim = AICEMPolicy.STATE_SIZE
	for i in range(AICEMPolicy.ACTION_SIZE):
		for j in range(state_dim):
			policy.W[i][j] = theta[j][i]
		policy.b[i] = theta[state_dim][i]

func get_policy(court_idx: int) -> AICEMPolicy:
	if court_idx >= 0 and court_idx < policies.size():
		return policies[court_idx]
	return policies[0]