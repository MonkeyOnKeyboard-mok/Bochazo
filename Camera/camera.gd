extends Node3D

## Anchor Points
var mainPos: Vector3 = Vector3(-40.222, 4.05, 0.0)
var mainRot: Vector3 = Vector3(0, -90.0, 0.0)
var followRot: Vector3 = Vector3(-90.0, -90.0, 0.0)

var followOffset : float =  20.0

@onready var main_cam: Camera3D = $TestCamera

@export var follow_height: float = 30.0
@export var pushback_distance: float = 2.5
@export var pushback_duration: float = 0.3
@export var rise_duration: float = 2.3
@export var return_duration: float = 1.5

var _tween: Tween = null

var ball_stopped : bool = false
var follow_in_process : bool = false
var follow_speed : float = 0.5

var _ball : RigidBody3D = null

func _ready() -> void:
	main_cam.global_position = mainPos
	main_cam.rotation_degrees = mainRot
	GameManager.connect("return_camera",on_ball_stopped)

func _process(delta: float) -> void:
	if follow_in_process:
		main_cam.global_position.x = lerp(main_cam.global_position.x, _ball.global_position.x, follow_speed * delta)

func start_follow(ball: RigidBody3D) -> void:
	if _tween:
		_tween.kill()
	_ball = ball
	var pushback_pos = Vector3(mainPos.x - pushback_distance, mainPos.y, mainPos.z)
	var follow_pos = Vector3(ball.global_position.x+followOffset, follow_height, mainPos.z)

	_tween = create_tween()
	_tween.tween_property(main_cam, "global_position", pushback_pos, pushback_duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.set_parallel(true)
	_tween.tween_property(main_cam, "global_position", follow_pos, rise_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(main_cam, "rotation_degrees", followRot, rise_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _tween.finished
	if !ball_stopped:
		follow_in_process = true

func on_ball_stopped() -> void: #
	follow_in_process = false
	ball_stopped = true
	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(main_cam, "global_position", mainPos, return_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(main_cam, "rotation_degrees", mainRot, return_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _tween.finished
	_ball = null
	ball_stopped = false
