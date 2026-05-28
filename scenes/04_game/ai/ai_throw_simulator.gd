class_name AISimulator
extends Node

signal simulation_done(params: AIThrowParams, reward: float, final_dist: float)

var _ball_scene: PackedScene
var _bochin_pos: Vector3 = Vector3.ZERO
var _ball_start: Vector3 = Vector3(-25, 1, 0)
var _sim_count: int = 0
var _max_sims: int = 200

var results: Array = []

func setup(ball_scene: PackedScene, bochin_pos: Vector3, ball_start: Vector3, court_type: int, stats: PlayerThrowStats):
	_ball_scene = ball_scene
	_bochin_pos = bochin_pos
	_ball_start = ball_start
	_sim_count = 0
	results.clear()

func run_batch(count: int):
	for i in range(count):
		var params = _random_params()
		var final_pos = _simulate_throw(params)
		var final_dist = final_pos.distance_to(_bochin_pos)
		var reward = _calculate_reward(final_dist)
		results.append({
			"params": params,
			"final_dist": final_dist,
			"reward": reward,
		})
	_sim_count += count

func _random_params() -> AIThrowParams:
	var p = AIThrowParams.new()
	p.power = randf_range(0.2, 1.0)
	p.angle_offset = randf_range(-0.3, 0.3)
	p.curve_intensity = randf()
	p.curve_side = 1.0 if randi() % 2 == 0 else -1.0
	p.is_straight = randf() < 0.3
	return p

func _simulate_throw(params: AIThrowParams) -> Vector3:
	var ball = _ball_scene.instantiate() as RigidBody3D
	ball.global_position = _ball_start
	get_parent().add_child(ball)
	ball.freeze = false

	var dir = params.compute_direction(_ball_start, _bochin_pos)
	var wps = params.compute_waypoints(_ball_start, _bochin_pos)

	var force = dir * params.power * 35.0
	ball.apply_central_impulse(force)

	var right = dir.cross(Vector3.UP).normalized()
	if wps.size() > 1:
		for i in range(60):
			await get_tree().physics_frame
			if ball.linear_velocity.length() < 0.1:
				break

	var final_pos = ball.global_position
	ball.queue_free()
	return final_pos

func _calculate_reward(final_dist: float) -> float:
	var score = clampf(1.0 - final_dist / 30.0, 0.0, 1.0)
	if final_dist < 1.0:
		score += 0.5
	elif final_dist < 3.0:
		score += 0.3
	elif final_dist > 10.0:
		score -= 0.3
	return score
