extends Node3D

## Anchor Points
var mainPos : Vector3 = Vector3(35,6.195, 00) ## In Test Scene
var mainRot : Vector3 = Vector3(-24.0,90, 00) ## In Test Scene

## Zoom 
var checkPos : Vector3 = Vector3(-20,6.195, 00) ## In Test Scene
var checkRot : Vector3 = Vector3(-65,90, 00) ## In Test Scene

@onready var camera : Camera3D = $Camera

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_position = mainPos
	global_rotation_degrees = mainRot

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
