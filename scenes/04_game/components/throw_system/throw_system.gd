extends Node3D
class_name ThrowSystem

@export var ball: RigidBody3D
@export var stats: PlayerThrowStats

@onready var tracker: GestureTracker = %GestureTracker
@onready var power: GesturePower = %GesturePower
@onready var direction: GestureDirection = %GestureDirection
@onready var power_bar: ProgressBar = %PowerBar
@onready var aim: ThrowAim = %ThrowHandler/ThrowAim
@onready var flight: ThrowFlight = %ThrowHandler/ThrowFlight
@onready var handler: ThrowHandler = %ThrowHandler
@onready var preview_line: Line2D = %GestureDirection/PreviewLine

func _ready():
	_wire()
	if stats:
		_apply_stats()

func _wire():
	power.tracker = tracker
	power.bar = power_bar
	direction.tracker = tracker
	direction.preview_line = preview_line
	aim.dir_module = direction
	flight.ball = ball

	power.connect_signals()
	direction.connect_signals()
	aim.connect_signals()
	handler.connect_signals()

func _apply_stats():
	if not stats:
		return

	tracker.max_aim_points = stats.max_aim_points
	tracker.min_charge_distance = stats.min_charge_distance
	tracker.max_charge_distance = stats.max_charge_distance
	tracker.min_aim_movement = stats.min_aim_movement
	power.max_drag_px = stats.max_charge_distance
	direction.aim_sensitivity = stats.aim_sensitivity
	aim.max_spread_deg = stats.max_spread_deg
	aim._update_launch()
	flight.curve_strength = stats.curve_strength
	flight.curve_duration = stats.curve_duration
	flight.wobble_speed = stats.wobble_speed
	flight.wobble_force = stats.wobble_force
	handler.set_max_force(stats.max_force)
	handler.set_min_power(stats.min_power)
