extends MeshInstance3D
class_name Punteador

var player : String 

# Posición Y base en el mundo 3D (en metros, cuando score == 0)
@export var base_y: float = 0.0

# Cuántos metros baja por cada punto sumado
@export var meters_per_point: float = -0.3

# Altura del salto inicial (metros, hacia arriba)
@export var jump_height: float = 0.3

# Eje de rotación del spin (Y = gira sobre sí mismo como un peonza)
@export var spin_axis: Vector3 = Vector3.UP

# Duración total en segundos
@export var anim_duration: float = 2.0

var _tween: Tween
var _start_rotation: Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.connect("update_scoreboard", _add_score)
	#GameManager.connect("full_reset", reset)
	_start_rotation = rotation_degrees
	base_y = position.y
	_settings()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func reset() -> void:
	_start_rotation = rotation_degrees
	base_y = position.y

func _add_score(score: int, inc_player: String) -> void:
	await get_tree().create_timer(1.8).timeout
	if inc_player != player: 
		print (" volviendo xd")
		return
	var target_y := base_y + score * meters_per_point

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(false)

	var spin_target := _start_rotation + spin_axis * 360.0

	# Etapa 1 — saltar desde base_y, no desde la posición actual
	_tween.tween_property(
		self, "position:y",
		base_y + jump_height,
		anim_duration * 0.35
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	_tween.parallel().tween_property(
		self, "rotation_degrees",
		spin_target,
		anim_duration * 0.35
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Etapa 2 — caer al destino final
	_tween.tween_property(
		self, "position:y",
		target_y,
		anim_duration * 0.65
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)

	_tween.parallel().tween_property(
		self, "rotation_degrees",
		_start_rotation,
		anim_duration * 0.65
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)

	base_y = target_y

func _settings() -> void:
	pass
