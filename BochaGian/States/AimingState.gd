extends RefCounted
class_name AimingState

@export_group("Configuracion")
@export var show_power_indicator: bool = true
@export var min_power_to_throw: float = 0.1

var bocha: Node3D

func init(root: Node3D) -> void:
	bocha = root

func enter() -> void:
	print("[AimingState] enter()")
	bocha.physics_body.freeze = true
	bocha.throw_controller.start_aiming()
	if show_power_indicator:
		bocha.visual_effects.show_power_indicator()

func exit() -> void:
	print("[AimingState] exit()")
	# NO llamar a stop_aiming() aca! ThrowingState necesita los datos del gesto.
	# stop_aiming() se llama cuando ya no se necesitan los datos.
	bocha.visual_effects.hide_power_indicator()

func update(_delta: float) -> void:
	bocha.throw_controller.update_aim()

	if bocha.throw_controller.gesture_phase == bocha.throw_controller.GesturePhase.RELEASED:
		var throw_data = bocha.throw_controller.get_throw_data()
		print("[AimingState] Gesto RELEASED. Power: ", throw_data.power, " Direction: ", throw_data.direction)
		if throw_data.power >= min_power_to_throw:
			print("[AimingState] Transicion a THROWING")
			bocha.state_machine.transition_to(
				bocha.state_machine.BochaState.THROWING
			)
		else:
			print("[AimingState] Power insuficiente, reiniciando")
			bocha.throw_controller.start_aiming()

func physics_update(_delta: float) -> void:
	pass

func handle_input(event: InputEvent) -> void:
	bocha.throw_controller.handle_input(event)
