extends MeshInstance3D

var player : String 

# Posición Y base en el mundo 3D (en metros, cuando score == 0)
@export var base_y: float = 0.0

# Cuántos metros baja por cada punto sumado
@export var meters_per_point: float = 0.82

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
	_start_rotation = rotation_degrees
	if GameManager.player1_char:
		player = GameManager.player1_char
	_add_score(2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _add_score(score:int)-> void:
	var target_y := base_y + score * meters_per_point

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(false)

	## Etapa 1 — spin + salto (rápido, 35%)
	var spin_target := _start_rotation + spin_axis * 360.0

	_tween.tween_property(
		self, "rotation_degrees",
		spin_target,
		anim_duration * 0.35
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	_tween.parallel().tween_property(
		self, "position:y",
		position.y + jump_height,
		anim_duration * 0.35
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	## Etapa 2 — rotación a cero + caída al destino (suave, 65%)
	_tween.tween_property(
		self, "rotation_degrees",
		_start_rotation,
		anim_duration * 0.65
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)

	_tween.parallel().tween_property(
		self, "position:y",
		target_y,
		anim_duration * 0.65
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
