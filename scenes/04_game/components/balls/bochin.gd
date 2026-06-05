extends BocceBall
class_name Bochin

func _physics_process(_delta):
	_check_velocity_for_rodado()
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

func _check_velocity_for_rodado() -> void:
	if _is_stopped: return
	if !is_thrown : return
	var speed = linear_velocity.length()
	Audio.update_rodando(speed)
	if linear_velocity.length() < stop_velocity_threshold_rodado:
		Audio.stop_rodando()

func bochin_valid_check() -> bool:
	if self.global_position.x < 0.0:
		return false
	else: return true
