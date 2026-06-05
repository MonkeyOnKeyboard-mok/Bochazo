extends RefCounted
class_name RollingState

@export_group("Configuracion")
@export var stop_threshold: float = 0.05
@export var required_stop_time: float = 0.5
@export var enable_trail_effect: bool = true
@export var trail_min_speed: float = 0.5

var bocha: Node3D
var time_below_threshold: float = 0.0

func init(root: Node3D) -> void:
	bocha = root

func enter() -> void:
	#print("[RollingState] enter()")
	time_below_threshold = 0.0
	bocha.physics_body.freeze = false

func exit() -> void:
	print("[RollingState] exit()")

func update(_delta: float) -> void:
	if not enable_trail_effect:
		return
	var speed = bocha.physics_body.linear_velocity.length()
	if speed > trail_min_speed:
		bocha.visual_effects.update_trail(speed)

func physics_update(delta: float) -> void:
	var speed = bocha.physics_body.linear_velocity.length()
	if speed < stop_threshold:
		time_below_threshold += delta
		if time_below_threshold >= required_stop_time:
			#print("[RollingState] Bocha detenida -> transicion a POSITIONING")
			bocha.physics_body.linear_velocity = Vector3.ZERO
			bocha.physics_body.angular_velocity = Vector3.ZERO
			bocha.bocha_stopped.emit()
			bocha.state_machine.transition_to(
				bocha.state_machine.BochaState.POSITIONING
			)
	else:
		time_below_threshold = 0.0

func handle_input(_event: InputEvent) -> void:
	pass
