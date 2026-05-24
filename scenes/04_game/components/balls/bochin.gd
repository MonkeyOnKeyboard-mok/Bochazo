extends BocceBall
class_name Bochin

func _physics_process(_delta):
	if !is_thrown:
		global_position = GameManager.current_player.marker.global_position
	if _is_stopped: return
	if linear_velocity.length() < stop_velocity_threshold:
		if !is_thrown: return
		_is_stopped = true
		freeze = true
		stopped_moving.emit(self)
		print("me frene y encima soy el bochin")
		GameManager.bochin_thrown = true
		GameManager.bochin = self
		if debug_verbose: print("[BocceBall] Se detuvo")
		freeze = false
