extends Node3D

## Anchor Points
var mainPos : Vector3 = Vector3(35,6.195, 00)## In Test Scene
var mainRot : Vector3 = Vector3(-24.0,90, 00)## In Test Scene

var checkPos : Vector3 = Vector3(-20,6.195, 00)## In Test Scene
var checkRot : Vector3 = Vector3(-65,90, 00)## In Test Scene

# Called when the node enters the scene tree for the first time.
@onready var camera : Camera3D = $Camera

func _ready() -> void:
	global_position = mainPos
	global_rotation_degrees = mainRot
	print(get_viewport().get_camera_3d())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
