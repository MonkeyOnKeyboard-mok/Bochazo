extends Node
class_name ThrowHandler

@export var tracker: GestureTracker
@export var power_bar: ProgressBar
@export var aim: ThrowAim
@export var spin: ThrowSpin
@export var ball: RigidBody3D
@export var power: GesturePower
@export var direction: GestureDirection
@export var spin_module_ref: GestureSpin
@export var config: ThrowConfig

@export var max_force: float = 35.0
@export var min_power: float = 0.05

func _ready():
	if not tracker: return
	tracker.gesture_ended.connect(_on_throw)
	_apply_config()

func _apply_config():
	if not config: return
	if tracker: tracker.max_draw_points = config.max_draw_points
	if power: power.max_drag_px = config.max_drag_px
	if direction: direction.aim_sensitivity = config.aim_sensitivity
	if aim:
		aim.max_spread_deg = config.max_spread_deg
		aim.launch_angle_rad = deg_to_rad(config.launch_angle_deg)
		aim._update_launch()
	if spin_module_ref: spin_module_ref.sensitivity = config.spin_sensitivity
	if spin:
		spin.steer_force = config.steer_force
		spin.min_curve_threshold = config.min_curve_threshold
		spin.wobble_speed = config.wobble_speed
		spin.wobble_force = config.wobble_force
	max_force = config.max_force
	min_power = config.min_power

func _on_throw(_pts):
	if not power_bar: return
	var p = clampf(power_bar.value / 100.0, 0.0, 1.0)
	if p < min_power: return
	var throw_type = _get_throw_type()
	print("[ThrowHandler] %s | power: %d%% | aim_x: %.2f | curve: %.2f" % [throw_type, int(p * 100), aim.dir.z, spin.spin_curve if spin else 0.0])
	ball.apply_central_impulse(aim.dir * p * max_force)

func _get_throw_type() -> String:
	if not spin: return "basic"
	if spin.is_wobble: return "knuckleball"
	var c = absf(spin.spin_curve)
	if c > 0.6: return "strong_curve"
	if c > 0.3: return "curve"
	return "gentle_curve"
