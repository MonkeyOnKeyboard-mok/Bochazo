extends Node
class_name ThrowSpin

@export var ball: RigidBody3D
@export var spin_module: GestureSpin
@export var steer_force: float = 0.3
@export var min_curve_threshold: float = 0.2
@export var wobble_speed: float = 8.0
@export var wobble_force: float = 0.12

var spin_curve: float = 0.0
var active: bool = false
var is_wobble: bool = false
var wobble_time: float = 0.0
var wobble_phase: float = 0.0

func _ready():
	if spin_module:
		spin_module.spin_calculated.connect(_on_spin)

func _on_spin(curve: float):
	wobble_time = 0.0
	if absf(curve) >= min_curve_threshold:
		spin_curve = curve
		active = true
		is_wobble = false
	else:
		spin_curve = 0.0
		active = true
		is_wobble = true
		wobble_phase = randf_range(0.0, TAU)

func _physics_process(delta):
	if not active: return
	var vel = ball.linear_velocity
	if vel.length() < 0.1:
		active = false
		return

	if is_wobble:
		wobble_time += delta
		var angle = sin(wobble_time * wobble_speed + wobble_phase) * wobble_force * delta
		ball.linear_velocity = vel.rotated(Vector3.UP, angle)
	else:
		var angle = -spin_curve * steer_force * delta
		ball.linear_velocity = vel.rotated(Vector3.UP, angle)
