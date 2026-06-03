extends BocceBall
class_name Bochin

func _physics_process(_delta):
	if !is_thrown:
		if GameManager.current_player:
			global_position = GameManager.current_player.marker.global_position
	if _is_stopped: return
	if linear_velocity.length() < stop_velocity_threshold:
		if !is_thrown: return
		_is_stopped = true
		freeze = true
		stopped_moving.emit(self)
		if !bochin_valid_check():
			GameManager.emit_signal("return_camera")
			GameManager.emit_signal("invalid")
			queue_free()
			GameManager.spawn_bocha.emit()
			GameManager.idle.emit()
			return
		else: 
			print("me frene y encima soy el bochin")
			GameManager.emit_signal("return_camera")
			GameManager.bochin_thrown = true
			GameManager.bochin = self
			GameManager.spawn_bocha.emit()
			GameManager.idle.emit()
			if debug_verbose: print("[BocceBall] Se detuvo")
			freeze = false

func bochin_valid_check() -> bool:
	if self.global_position.x < 0.0:
		return false
	else: return true
