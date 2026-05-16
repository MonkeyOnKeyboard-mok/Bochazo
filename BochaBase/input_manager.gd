extends Node3D
class_name BochaInputManager

@export var speed : float = 5.0
@export var throw_speed : float = 10.0
@export var bocha_rb: RigidBody3D
signal action_completed

var throwed : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _physics_process(_delta: float) -> void:
	if !throwed:
		_move_before_throw()
		_throw()

func _move_before_throw() ->void:
	var direction := 0.0
	if Input.is_action_pressed("move_left"):
		direction += 1.0
	if Input.is_action_pressed("move_right"):
		direction -= 1.0
	bocha_rb.linear_velocity.z = direction * speed

func _throw() -> void:
	var direction := 0.0
	if Input.is_action_pressed("start_throw"):
		throwed = true
		direction = -1.0
		bocha_rb.linear_velocity.x = direction * throw_speed
	action_completed.emit()
