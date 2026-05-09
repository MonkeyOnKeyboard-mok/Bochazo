extends Node3D
class_name Bocha

@export var speed := 5.0
@onready var bocha_rb: RigidBody3D = $BochaRigidBody

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _physics_process(_delta: float) -> void:
	var direction := 0.0
	if Input.is_action_pressed("move_left"):
		print("pressing left")
		direction -= 1.0
	if Input.is_action_pressed("move_right"):
		direction += 1.0
	bocha_rb.linear_velocity.x = direction * speed
