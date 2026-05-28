extends RigidBody3D
class_name TrainingBall

signal ball_stopped(final_pos: Vector3)

var player: String = ""
var _stop_timer: float = 0.0
var _stopped: bool = false
var _max_sim_time: float = 8.0
var _sim_time: float = 0.0

func _physics_process(delta):
	if _stopped: return
	_sim_time += delta
	if _sim_time > _max_sim_time:
		_force_stop()
		return
	if linear_velocity.length() < 0.3:
		_stop_timer += delta
		if _stop_timer > 0.15:
			_force_stop()
	else:
		_stop_timer = 0.0

func _force_stop():
	_stopped = true
	freeze = true
	ball_stopped.emit(global_position)

func reset_at(pos: Vector3):
	_stopped = false
	_stop_timer = 0.0
	_sim_time = 0.0
	freeze = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_position = pos
	contact_monitor = true
