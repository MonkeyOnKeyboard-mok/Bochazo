extends RigidBody3D
class_name TrainingBall

signal stopped_moving(ball_ref)

@export var physics_config: PhysicsConfig
var stop_velocity_threshold: float = 0.1
var _min_active_frames: int = 15
var _active_frames: int = 0
var _max_sim_time: float = 8.0
var _sim_time: float = 0.0
var _is_stopped: bool = false

var _steering: bool = false
var _waypoints: PackedVector3Array = []
var _waypoint_idx: int = 0
var _waypoint_reach: float = 1.2
var _efecto: float = 0.5
var _steer_factor: float = 20.0

func _ready():
	_apply_physics()

func _apply_physics():
	if physics_config:
		mass = physics_config.ball_mass
		linear_damp = physics_config.linear_damping
		angular_damp = physics_config.angular_damping
		stop_velocity_threshold = physics_config.stop_velocity_threshold
		var mat = PhysicsMaterial.new()
		mat.friction = physics_config.ball_friction
		mat.bounce = physics_config.ball_bounce
		physics_material_override = mat

func _physics_process(delta):
	if _is_stopped:
		return
	_sim_time += delta
	_active_frames += 1
	if _sim_time > _max_sim_time:
		_force_stop()
		return
	if _active_frames < _min_active_frames:
		return
	if linear_velocity.length() < stop_velocity_threshold:
		_is_stopped = true
		freeze = true
		_steering = false
		stopped_moving.emit(self)
	elif _steering and _waypoints.size() > 1:
		_process_waypoints()

func _process_waypoints():
	if _waypoint_idx >= _waypoints.size():
		_steering = false
		return
	var vel = linear_velocity
	var vel_horiz = Vector3(vel.x, 0, vel.z)
	if vel_horiz.length() < 0.2:
		_steering = false
		return
	var target = _waypoints[_waypoint_idx]
	var to_target = Vector3(target.x - global_position.x, 0, target.z - global_position.z)
	var dist = to_target.length()
	if dist < _waypoint_reach:
		_waypoint_idx += 1
		if _waypoint_idx >= _waypoints.size():
			_steering = false
		return
	var forward = vel_horiz.normalized()
	var right = forward.cross(Vector3.UP).normalized()
	var desired = to_target.normalized()
	var lateral = desired.dot(right)
	apply_central_force(right * lateral * _efecto * _steer_factor)

func _force_stop():
	_is_stopped = true
	freeze = true
	_steering = false
	stopped_moving.emit(self)

func reset_at(pos: Vector3):
	_is_stopped = false
	_sim_time = 0.0
	_active_frames = 0
	freeze = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_position = pos
	contact_monitor = true
	_steering = false
	_waypoints.clear()
	_waypoint_idx = 0

func set_waypoints(wps: PackedVector3Array, efecto_val: float):
	if wps.size() < 2:
		_steering = false
		_waypoints.clear()
		return
	_waypoints = wps
	_waypoint_idx = 1
	_steering = true
	_efecto = efecto_val