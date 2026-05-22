extends Node3D
class_name ThrowSystem

@export var ball: RigidBody3D
@export var stats: PlayerThrowStats

@onready var tracker: GestureTracker = %GestureTracker
@onready var power: GesturePower = %GesturePower
@onready var power_bar: ProgressBar = %PowerBar
@onready var aim: ThrowAim = %ThrowAim
@onready var flight: ThrowFlight = %ThrowFlight

var _stored_power: float = 0.0
var _stored_lateral: float = 0.0

func _ready():
	_wire()
	if stats: _apply_stats()

func _wire():
	power.tracker = tracker
	power.bar = power_bar
	flight.ball = ball

	tracker.charge_started.connect(power._reset)
	tracker.charge_dragging.connect(power._on_dragging)
	tracker.charge_ended.connect(_on_charge_ended)
	tracker.aim_ended.connect(_on_aim_ended)

func _apply_stats():
	tracker.max_aim_points = stats.max_aim_points
	tracker.min_charge_distance = stats.min_charge_distance
	tracker.max_charge_distance = stats.max_charge_distance
	power.max_drag_px = stats.max_charge_distance
	flight.efecto = stats.efecto
	flight.precision = stats.precision
	flight.control = stats.control
	flight.max_force = stats.potencia
	flight.min_power = stats.min_power
	aim.efecto = stats.efecto

func _on_charge_ended(frac: float, lateral: float):
	_stored_power = frac
	_stored_lateral = lateral

func _on_aim_ended(points: PackedVector2Array):
	if not flight or not flight.ball: return
	if _stored_power < flight.min_power: return

	var ball_pos = flight.ball.global_position
	var camera = get_viewport().get_camera_3d()
	var forward = _get_forward(camera)
	var direction = forward.rotated(Vector3.UP, _stored_lateral * 0.1)

	if points.size() < 3:
		flight.launch_straight(_stored_power, direction)
		return

	var path = aim.build_path(points, ball_pos)
	if path.size() < 2:
		flight.launch_straight(_stored_power, direction)
		return

	direction = (path[1] - ball_pos)
	direction.y = 0
	direction = direction.normalized()
	flight.launch(_stored_power, direction, path)

func _get_forward(camera: Camera3D) -> Vector3:
	if camera:
		var fwd = -camera.global_basis.z
		fwd.y = 0
		return fwd.normalized()
	return Vector3.FORWARD
