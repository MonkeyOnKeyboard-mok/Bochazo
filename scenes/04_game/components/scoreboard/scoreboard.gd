extends Node3D

var original_pos : Vector3
var original_rot : Vector3

var center_pos : Vector3

# Distancia frente a la cámara donde aparece el marcador
@export var camera_distance : float = 5.0
# Cuánto tiempo está en el centro antes de volver
@export var hold_duration : float = 4.0
# Duración de entrada y salida
@export var move_duration : float = 0.6

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	original_pos = global_position
	original_rot.y = global_rotation.y
	GameManager.connect("soft_reset", show_scores)
	GameManager.connect("full_reset", show_scores)
	var camera := get_viewport().get_camera_3d()
	if not camera: return
	center_pos = camera.global_position \
		+ camera.global_basis.z * -camera_distance

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func show_scores() -> void:

	var tween := create_tween()
	tween.set_parallel(false)

	## Etapa 1 — volar al centro
	tween.tween_property(self, "global_position", center_pos, move_duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


## Etapa 2 — quedarse en el centro (acá podés emitir señal, actualizar texto, etc.)
	tween.tween_interval(hold_duration)
	if GameManager.game_ended:
		print("Is the game over?", GameManager.game_ended)
		return

## Etapa 3 — volver a la posición original
	tween.tween_property(self, "global_position", original_pos, move_duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	
	await tween.finished
	reset()

func reset() -> void:
	GameManager.soft_reset_end.emit()
