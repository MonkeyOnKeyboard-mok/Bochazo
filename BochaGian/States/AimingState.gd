extends RefCounted
class_name AimingState

@export_group("Configuracion")
@export var show_power_indicator: bool = true

var bocha: Node3D

func init(root: Node3D) -> void:
	bocha = root

func enter() -> void:
	#print("[AimingState] enter()")
	bocha.physics_body.freeze = true
	bocha.throw_controller.start_aiming()
	if show_power_indicator:
		bocha.visual_effects.show_power_indicator()

func exit() -> void:
	#print("[AimingState] exit()")
	bocha.visual_effects.hide_power_indicator()
	if bocha.bocha_animator != null:
		bocha.bocha_animator.reset_visual()

func update(_delta: float) -> void:
	bocha.throw_controller.update_aim()

	# Feedback visual: mover la bocha segun la fase del gesto
	var progress = bocha.throw_controller.get_drag_progress()
	if bocha.bocha_animator != null:
		bocha.bocha_animator.update_visual_feedback(progress)

	# Solo transicionar a THROWING si el gesto llego a RELEASED
	# (el usuario solto durante la fase de PUSH_FORWARD)
	if bocha.throw_controller.gesture_phase == bocha.throw_controller.GesturePhase.RELEASED:
		var throw_data = bocha.throw_controller.get_throw_data()
	#	print("[AimingState] Gesto RELEASED. Power: ", throw_data.power, " Direction: ", throw_data.direction)
		if throw_data.power >= bocha.min_throw_power:
		#	print("[AimingState] Transicion a THROWING")
			bocha.state_machine.transition_to(
				bocha.state_machine.BochaState.THROWING
			)
		else:
			# Power insuficiente, reiniciar para intentar de nuevo
		#	print("[AimingState] Power insuficiente, reiniciando")
			bocha.throw_controller.start_aiming()
			if bocha.bocha_animator != null:
				bocha.bocha_animator.reset_visual()

func physics_update(_delta: float) -> void:
	pass

func handle_input(event: InputEvent) -> void:
	bocha.throw_controller.handle_input(event)
