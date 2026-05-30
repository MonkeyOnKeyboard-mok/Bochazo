extends Node3D

const BOCHIN = preload("uid://4qe83ntmmj7w")
const BOCCE_BALL = preload("uid://khh2to667k2u")

@onready var bocha_pos: Marker3D = $BochaPos

var ball : RigidBody3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.connect("spawn_bocha", spawn_bocha)
	spawn_bocha()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func spawn_bocha() -> void:
	var bochin = null
	if GameManager.bochin_thrown == false: 
		bochin = BOCHIN.instantiate()
	else: 
		bochin = BOCCE_BALL.instantiate()
	add_child(bochin)
	ball = bochin
	ball.global_position = bocha_pos.global_position
	%brain.ball = ball
	GameManager.bocha_spawned.emit(ball)
