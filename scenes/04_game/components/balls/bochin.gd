extends BocceBall
class_name Bochin

func _physics_process(_delta):
	if _is_stopped: return
	if linear_velocity.length() < stop_velocity_threshold:
		_is_stopped = true
		freeze = true
		stopped_moving.emit(self)
		print("me frene y encima soy el bochin")
		GameManager.bochin_thrown = true
		GameManager.bochin = self
		if debug_verbose: print("[BocceBall] Se detuvo")
		freeze = false
