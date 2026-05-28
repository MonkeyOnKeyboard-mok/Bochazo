class_name AIPlayer
extends Node3D

@export var stats: PlayerThrowStats
@export var ball: RigidBody3D

@onready var brain: AIThrowBrain = $AIThrowBrain

var _context: AIContext

signal throw_completed()

func take_turn(bochin_pos: Vector3, court_type: int, bochas: Array):
	if not ball or not brain:
		return

	_context = AIContext.gather(bochin_pos, court_type, bochas, stats, ball.global_position)
	var ball_pos = ball.global_position

	brain.flight = _get_flight()
	brain.ball = ball
	brain.stats = stats
	brain.execute_throw(_context, ball_pos, bochin_pos)

	if ball.has_signal("stopped_moving"):
		ball.stopped_moving.connect(_on_ball_stopped, CONNECT_ONE_SHOT)

func _on_ball_stopped(_ball_ref):
	throw_completed.emit()

func _get_flight() -> ThrowFlight:
	var throw_system = get_parent().find_child("ThrowSystem", true, false) as ThrowSystem
	if throw_system and throw_system.flight:
		return throw_system.flight
	var flight_node = ThrowFlight.new()
	return flight_node
