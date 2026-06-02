extends Node
class_name ThrowFlight

var ball: RigidBody3D

#var throw_pos : Vector3 = Vector3 (-25.8,0.438, -0.42)	
# Del testing print: bola pos: (-27.8862, 1.800941, -0.42152)

var efecto: float = 0.5
var precision: float = 0.95
var control: float = 0.85
var max_force: float = 35.0
var min_power: float = 0.05

var _active: bool = false
var _waypoints: PackedVector3Array = []
var _current_wp: int = 0
var _waypoint_reach: float = 1.2
var _steer_factor: float = 20.0

func launch(power: float, direction: Vector3, waypoints: PackedVector3Array):
	if not ball: return
	_waypoints = waypoints
	_current_wp = 1 if waypoints.size() > 1 else 0
	_active = true
	var spread = (1.0 - precision) * 0.06
	var dir = direction.rotated(Vector3.UP, randf_range(-spread, spread))
	GameManager.emit_signal("throw")
	while !GameManager.throw_for_real:
		await get_tree().create_timer(0.05).timeout
	animation_fix_and_etc()
	ball.apply_central_impulse(dir * power * max_force)
	ball.is_thrown = true ## Agregado Santi
	GameManager.throw_for_real = false
	GameManager.permission_to_throw = false
	if control < 1.0:
		var wobble = (1.0 - control) * 0.1
		ball.apply_central_impulse(Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * wobble)

func launch_straight(power: float, direction: Vector3):
	if not ball: return
	_waypoints.clear()
	_active = false
	var spread = (1.0 - precision) * 0.04
	var dir = direction.rotated(Vector3.UP, randf_range(-spread, spread))
	GameManager.emit_signal("throw")
	while !GameManager.throw_for_real:
		await get_tree().create_timer(0.05).timeout
	animation_fix_and_etc() ## Fix this
	ball.apply_central_impulse(dir * power * max_force)
	ball.is_thrown = true ## Agregado Santi
	GameManager.throw_for_real = false
	GameManager.permission_to_throw = false

func _physics_process(_delta):
	if not _active or not ball: return
	if ball.linear_velocity.length() < 0.3:
		_active = false
		return
	if _current_wp >= _waypoints.size():
		_active = false
		return

	var target = _waypoints[_current_wp]
	var to_target = Vector3(target.x - ball.global_position.x, 0, target.z - ball.global_position.z)
	var dist = to_target.length()

	if dist < _waypoint_reach:
		_current_wp += 1
		if _current_wp >= _waypoints.size():
			_active = false
		return

	var vel = ball.linear_velocity
	var vel_horiz = Vector3(vel.x, 0, vel.z)
	if vel_horiz.length() < 0.2: return

	var forward = Vector3.RIGHT
	var right = forward.cross(Vector3.UP).normalized()
	var desired = to_target.normalized()
	var lateral = desired.dot(right)
	ball.apply_central_force(right * lateral * efecto * _steer_factor)

func animation_fix_and_etc() -> void:
	ball.freeze = true
	ball.global_position = GameManager.global_ball_pos
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.freeze = false
	await get_tree().create_timer(1.5).timeout
	camera_follow()

func camera_follow() -> void:
	get_parent().camera_manager.start_follow(ball)
