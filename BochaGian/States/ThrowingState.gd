extends RefCounted
class_name ThrowingState

@export_group("Configuracion")
@export var apply_curve: bool = true
@export var curve_multiplier: float = 2.0
@export var play_throw_effect: bool = true

var bocha: Node3D
var throw_applied: bool = false

func init(root: Node3D) -> void:
	bocha = root

func enter() -> void:
	#print("[ThrowingState] enter()")
	throw_applied = false

func exit() -> void:
	#print("[ThrowingState] exit()")
	# Limpiar datos del gesto despues de usarlos
	bocha.throw_controller.stop_aiming()

func update(_delta: float) -> void:
	if not throw_applied:
		if play_throw_effect:
			bocha.visual_effects.play_throw_effect()
		throw_applied = true

func physics_update(_delta: float) -> void:
	if not throw_applied:
		# Unfreezar PRIMERO
		bocha.physics_body.freeze = false
		#print("[ThrowingState] PhysicsBody unfreezeado")

		# Obtener datos del lanzamiento (ANTES de que se reseteen)
		var throw_data = bocha.throw_controller.get_throw_data()
		var impulse = throw_data.direction * throw_data.power
		#print("[ThrowingState] Aplicando impulso: ", impulse)
		bocha.physics_body.apply_central_impulse(impulse)

		if apply_curve and abs(throw_data.curve) > 0.01:
			bocha.physics_body.angular_velocity.y = throw_data.curve * curve_multiplier
			#print("[ThrowingState] Aplicando curva: ", throw_data.curve * curve_multiplier)

		bocha.bocha_thrown.emit(throw_data.power, throw_data.direction)

		throw_applied = true
	else:
		#print("[ThrowingState] Transicion a ROLLING")
		bocha.state_machine.transition_to(
			bocha.state_machine.BochaState.ROLLING
		)

func handle_input(_event: InputEvent) -> void:
	pass
