extends Punteador


func _settings() -> void:
	if GameManager.player2_char:
		player = GameManager.player2_char
