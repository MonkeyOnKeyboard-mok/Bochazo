# Bocha.gd - Nodo Raiz
extends Node3D

# Senales para comunicacion externa
signal bocha_thrown(power: float, direction: Vector3)
signal bocha_stopped
signal state_changed(new_state: String)

# Referencias a componentes hijos (asignadas en _ready)
var physics_body: RigidBody3D
var state_machine: Node
var position_controller: Node
var throw_controller: Node
var input_handler: Node
var visual_effects: Node3D
var bocha_animator: Node

# Configuracion exportable
@export_group("Configuracion")
@export var lateral_speed: float = 3.0
@export var lateral_bounds: Vector2 = Vector2(-2.0, 2.0)
@export var max_throw_power: float = 15.0
@export var min_throw_power: float = 3.0
@export var throw_sensitivity: float = 1.0

func _ready() -> void:
	print("[Bocha] _ready() iniciado")

	# Cache de referencias a hijos
	physics_body = $PhysicsBody
	state_machine = $StateMachine
	position_controller = $PositionController
	throw_controller = $ThrowController
	input_handler = $InputHandler
	visual_effects = $VisualEffects
	bocha_animator = $BochaAnimator

	print("[Bocha] physics_body: ", physics_body)
	print("[Bocha] state_machine: ", state_machine)
	print("[Bocha] position_controller: ", position_controller)
	print("[Bocha] throw_controller: ", throw_controller)
	print("[Bocha] input_handler: ", input_handler)
	print("[Bocha] visual_effects: ", visual_effects)
	print("[Bocha] bocha_animator: ", bocha_animator)

	# Inicializar componentes con referencias cruzadas
	position_controller.bocha_root = self
	throw_controller.bocha_root = self
	input_handler.bocha_root = self
	bocha_animator.bocha_root = self

	# Conectar senales internas
	state_machine.state_changed.connect(_on_state_changed)

	print("[Bocha] _ready() completado. Estado inicial: POSITIONING")

func _on_state_changed(new_state: String) -> void:
	print("[Bocha] Estado cambiado a: ", new_state)
	state_changed.emit(new_state)
