class_name AICEMSimulator
extends Node3D

signal batch_done()

const MAX_POOL: int = 20
const MAX_OBS: int = 6
const STOP_VEL: float = 0.1
const MAX_SIM_TIME: float = 8.0
const COURT_FRICTIONS: Array[float] = [1.0, 0.8, 0.9, 1.1, 0.6]

var ball_scene: PackedScene
var _ball_pool: Array[RigidBody3D] = []
var _flight_pool: Array[ThrowFlight] = []
var _obstacle_pool: Array[RigidBody3D] = []
var _bochin_marker: Node3D

var _pending: int = 0
var _batch_results: PackedVector3Array = []

func init_simulator(scn: PackedScene):
	ball_scene = scn
	_build_ball_pool()
	_build_obstacle_pool()
	_bochin_marker = Node3D.new()
	add_child(_bochin_marker)

	for i in range(MAX_POOL):
		var flight = ThrowFlight.new()
		add_child(flight)
		_flight_pool.append(flight)

func _build_ball_pool():
	for i in range(MAX_POOL):
		var ball = ball_scene.instantiate() as RigidBody3D
		if ball.has_method("set") and "training_mode" in ball:
			ball.set("training_mode", true)
		ball.visible = false
		ball.freeze = true
		add_child(ball)
		_ball_pool.append(ball)

func _build_obstacle_pool():
	for i in range(MAX_OBS):
		var obs = RigidBody3D.new()
		obs.freeze = true
		obs.mass = 1.0
		obs.collision_mask = 1
		obs.collision_layer = 1
		var col = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 0.5
		col.shape = shape
		obs.add_child(col)
		var mat = PhysicsMaterial.new()
		mat.friction = 1.0
		mat.bounce = 0.3
		obs.physics_material_override = mat
		obs.visible = false
		obs.position = Vector3(0, -100, 0)
		add_child(obs)
		_obstacle_pool.append(obs)

func place_bochin(pos: Vector3):
	_bochin_marker.global_position = pos

func place_obstacles(obstacle_positions: Array):
	for i in range(MAX_OBS):
		if i < obstacle_positions.size() and obstacle_positions[i] is Vector3:
			_obstacle_pool[i].global_position = obstacle_positions[i] as Vector3
			_obstacle_pool[i].visible = true
			_obstacle_pool[i].freeze = true
		else:
			_obstacle_pool[i].visible = false
			_obstacle_pool[i].position = Vector3(0, -100, 0)

func hide_obstacles():
	for obs in _obstacle_pool:
		obs.visible = false
		obs.position = Vector3(0, -100, 0)

func simulate_scenario(actions: Array, bochin_pos: Vector3, ball_pos: Vector3, potencia: float, efecto: float, court_idx: int = 0, obstacles: Array = []) -> Array[float]:
	place_bochin(bochin_pos)
	place_obstacles(obstacles)

	var court_friction = COURT_FRICTIONS[clampi(court_idx, 0, 4)]

	var k = actions.size()
	var rewards: Array[float] = []
	rewards.resize(k)
	var offset = 0

	while offset < k:
		var count = mini(MAX_POOL, k - offset)
		var loc_results = await _run_batch(count, actions, offset, bochin_pos, ball_pos, potencia, efecto, court_friction)
		for i in range(count):
			var dist = loc_results[i].distance_to(bochin_pos)
			rewards[offset + i] = _compute_reward(dist)
		offset += count

	hide_obstacles()
	return rewards

func _reset_ball(ball: RigidBody3D, pos: Vector3):
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
	if "settings_set" in ball:
		ball.settings_set = false
	if "player" in ball:
		ball.player = ""

func _run_batch(count: int, actions: Array, offset: int, bochin_pos: Vector3, ball_pos: Vector3, potencia: float, efecto: float, court_friction: float) -> PackedVector3Array:
	_pending = count
	_batch_results.clear()
	_batch_results.resize(count)

	for i in range(count):
		var ball = _ball_pool[i]
		_reset_ball(ball, ball_pos)
		ball.stopped_moving.connect(_on_batch_stopped.bind(i), CONNECT_ONE_SHOT)

	for i in range(count):
		for j in range(i + 1, count):
			_ball_pool[i].add_collision_exception_with(_ball_pool[j])

	for i in range(count):
		var ai = offset + i
		if ai >= actions.size():
			_pending -= 1
			_batch_results[i] = ball_pos
			continue
		var action: Array = actions[ai]
		var p = AICEMPolicy.map_action_to_params(action)
		var direction = (bochin_pos - ball_pos)
		direction.y = 0
		if direction.length() > 0.1:
			direction = direction.normalized()
		else:
			direction = Vector3.FORWARD
		direction = direction.rotated(Vector3.UP, p.angle_offset)
		var wps = p.compute_waypoints(ball_pos, bochin_pos)
		var flight = _flight_pool[i]
		flight.ball = _ball_pool[i]
		flight.max_force = potencia
		flight.efecto = efecto * court_friction
		flight.precision = 0.95
		flight.control = 0.85

		if not p.is_straight and wps.size() >= 2:
			flight.launch(p.power, direction, wps)
		else:
			flight.launch_straight(p.power, direction)

	while _pending > 0:
		await get_tree().physics_frame

	var results = PackedVector3Array()
	for i in range(count):
		results.append(_batch_results[i])
		_ball_pool[i].visible = false
		_ball_pool[i].freeze = true
		_flight_pool[i]._active = false
		_flight_pool[i]._waypoints.clear()
		_flight_pool[i].ball = null
		for j in range(count):
			if i != j:
				_ball_pool[i].remove_collision_exception_with(_ball_pool[j])

	return results

func _on_batch_stopped(ball_ref, idx: int):
	if idx < _batch_results.size() and is_instance_valid(ball_ref):
		_batch_results[idx] = ball_ref.global_position
	_pending -= 1

func _compute_reward(dist: float) -> float:
	var inv_reward = 1.0 / (1.0 + dist)
	if dist < 0.5:
		inv_reward += 0.5
	elif dist < 1.0:
		inv_reward += 0.3
	elif dist < 2.0:
		inv_reward += 0.15
	elif dist < 3.0:
		inv_reward += 0.05
	if dist > 15.0:
		inv_reward -= 0.3
	elif dist > 10.0:
		inv_reward -= 0.15
	return clampf(inv_reward, 0.0, 2.0)
