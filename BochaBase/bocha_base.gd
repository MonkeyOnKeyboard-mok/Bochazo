extends Node3D
class_name Bocha

@onready var child_node = $InputManager
@export var camera: Node3D

var mainPos : Vector3 = Vector3(30,2, 00) ## In Test Scene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_position = mainPos
	child_node.action_completed.connect(camera.move_to_check_position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
