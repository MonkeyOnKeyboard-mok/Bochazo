class_name AIPlayer
extends Node3D

@export var stats: PlayerThrowStats
@export var ball: RigidBody3D
@export var weights_path: String = ""
@export var difficulty: int = 0

@onready var brain: AIThrowBrain = $AIThrowBrain

signal throw_completed()

func _ready():
	if brain and weights_path != "":
		brain.load_weights(weights_path)
	if brain:
		brain.set_difficulty(difficulty)

func take_turn(bochin_pos: Vector3, court_type: int, bochas: Array):
	if not ball or not brain:
		return

	if not brain.policies[0]:
		brain.load_weights(weights_path)

	var ball_pos = ball.global_position

	brain.stats = stats
	brain.ball = ball
	brain.flight = _get_flight()
	brain.execute_throw(ball_pos, bochin_pos, court_type, bochas)

	if ball.has_signal("stopped_moving"):
		ball.stopped_moving.connect(_on_ball_stopped, CONNECT_ONE_SHOT)

func _on_ball_stopped(_ball_ref):
	throw_completed.emit()

func _get_flight() -> ThrowFlight:
	var throw_system = get_parent().find_child("ThrowSystem", true, false) as ThrowSystem
	if throw_system and throw_system.flight:
		return throw_system.flight
	var flight_node = ThrowFlight.new()
	add_child(flight_node)
	return flight_node