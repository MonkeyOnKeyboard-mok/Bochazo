extends RefCounted
class_name PositioningState

@export_group("Configuracion")
@export var freeze_on_enter: bool = true
@export var reset_velocity_on_enter: bool = true

var bocha: Node3D

func init(root: Node3D) -> void:
	bocha = root

func enter() -> void:
	print("[PositioningState] enter()")
	if freeze_on_enter:
		bocha.physics_body.freeze = true
		print("[PositioningState] PhysicsBody freezeado")
	if reset_velocity_on_enter:
		bocha.physics_body.linear_velocity = Vector3.ZERO

func exit() -> void:
	print("[PositioningState] exit()")
	# NO unfreezar. El siguiente estado (AimingState) maneja su propio freeze.

func update(_delta: float) -> void:
	bocha.position_controller.update_position()

func physics_update(_delta: float) -> void:
	pass

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("[PositioningState] Click izquierdo detectado -> transicion a AIMING")
			# Transicionar a AIMING primero
			bocha.state_machine.transition_to(
				bocha.state_machine.BochaState.AIMING
			)
			# Pasar el mismo evento al ThrowController para que inicie el arrastre inmediatamente
			# Esto permite que el click que inicia AIMING tambien inicie el pull-back
			if bocha.throw_controller != null:
				bocha.throw_controller.handle_input(event)
