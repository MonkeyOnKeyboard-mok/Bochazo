# StateMachine.gd -- Version Opcion A (sin .tres, funciona YA)
extends Node

signal state_changed(new_state: String)

enum BochaState {
	POSITIONING,
	AIMING,
	THROWING,
	ROLLING
}

var current_state: BochaState = BochaState.POSITIONING

# Los estados se crean en codigo, NO desde el inspector
var states: Dictionary = {}

var initialized: bool = false

func _ready() -> void:
	print("[StateMachine] _ready() - programando init diferido")
	# Usar call_deferred para que se ejecute DESPUES de que Bocha._ready()
	# haya cacheado todas las referencias (physics_body, etc.)
	call_deferred("_init_states")

func _init_states() -> void:
	if initialized:
		return
	initialized = true

	print("[StateMachine] Inicializando estados...")

	# Crear los estados directamente con .new()
	states[BochaState.POSITIONING] = PositioningState.new()
	states[BochaState.AIMING] = AimingState.new()
	states[BochaState.THROWING] = ThrowingState.new()
	states[BochaState.ROLLING] = RollingState.new()

	print("[StateMachine] 4 estados creados")

	# Inicializar cada estado con referencia al padre
	for state in states.values():
		state.init(get_parent())

	print("[StateMachine] Estados inicializados")

	# Entrar al estado inicial
	states[current_state].enter()
	print("[StateMachine] Estado inicial POSITIONING activado")

func _process(delta: float) -> void:
	if not initialized:
		return
	states[current_state].update(delta)

func _physics_process(delta: float) -> void:
	if not initialized:
		return
	states[current_state].physics_update(delta)

func _input(event: InputEvent) -> void:
	if not initialized:
		return
	# Debug: mostrar que input se recibe
	if event is InputEventMouseButton:
		print("[StateMachine] Input recibido: ", "pressed=" if event.pressed else "released=", " button=", event.button_index)
	states[current_state].handle_input(event)

func transition_to(new_state: BochaState) -> void:
	if not initialized:
		return
	if new_state == current_state:
		return

	print("[StateMachine] Transicion: ", BochaState.keys()[current_state], " -> ", BochaState.keys()[new_state])

	states[current_state].exit()
	current_state = new_state
	states[current_state].enter()
	state_changed.emit(BochaState.keys()[current_state])
