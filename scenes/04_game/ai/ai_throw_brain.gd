## AIThrowBrain — IA de Tiro para Bochazo v3 (Data-Driven, Multi-Candidato)
##
## COMO USAR:
##   1. Agregar este nodo como hijo de cualquier nodo de la escena
##   2. En _ready() o antes de usar, llamar:
##        brain.load_data()
##   3. Configurar cancha y dificultad:
##        brain.court_type = 2          # 0=Flat,1=Dirty,2=Grass,3=Pro,4=Sand
##        brain.set_difficulty(2)       # 0=facil, 4=dificil
##        brain.curve_preference = 0.5  # 0=sin preferencia, 2=max curva
##   4. Para que la IA tire:
##        brain.setup_for_throw(ball, flight)
##        brain.execute_throw(ball_pos, bochin_pos)
##      O bien, solo obtener parametros sin ejecutar:
##        var params = brain.decide(ball_pos, bochin_pos)
##        params.power       # float [0.4, 1.0]
##        params.angle_offset # float [-0.3, 0.3] radianes
##        params.curve_intensity # float [0, 1]
##        params.curve_side  # float [-1, 1]
##        params.is_straight # bool
##        params.direction   # Vector3 (se computa con compute_direction)
##        params.waypoints   # PackedVector3Array (se computa con compute_waypoints)
##
## SEÑALES:
##   throw_ready(params: AIThrowParams) — se emite al ejecutar un tiro
##
## VARIABLES EXPORT/MODIFICABLES:
##   court_type: int        — Índice de cancha (0-4)
##   curve_preference: float — Cuánto priorizar tiros con curva (0=sin preferencia, 2=max)
##   noise_radius: float    — Radio de incertidumbre en el objetivo (0=exacto, 1=metro)
##   difficulty_sigma: float — Ruido gaussiano en parámetros (0=exacto, mayor=más impreciso)
##
## ARCHIVOS DE DATOS:
##   Los datos provienen de simulaciones previas guardadas en:
##     res://resources/ai_data/throws_flat.json
##     res://resources/ai_data/throws_dirty.json
##     res://resources/ai_data/throws_grass.json
##     res://resources/ai_data/throws_pro.json
##     res://resources/ai_data/throws_sand.json
##   Cada archivo contiene ~5000 tiros con: posición inicio, parámetros, posición final.
##   Generarlos con la escena tests/simulation_AI.tscn
##
## MÉTODO DE BÚSQUEDA:
##   Busca los K=8 tiros más cercanos al objetivo y elige uno aleatoriamente
##   con peso inversamente proporcional a la distancia al target.
##   Esto da variedad natural sin promediar parámetros contradictorios.
##

class_name AIThrowBrain
extends Node

signal throw_ready(params: AIThrowParams)

var model: AIInverseModel
var rng: RandomNumberGenerator
var _loaded: bool = false

const COURT_FRICTIONS: Array[float] = [1.0, 0.8, 0.9, 1.1, 0.6]
const MIN_POWER: float = 0.4
const K_CANDIDATES: int = 8

## Stats propios de la IA — independientes de cualquier personaje
const AI_MAX_FORCE: float = 45.0
const AI_EFECTO: float = 1.0
const AI_PRECISION: float = 1.0
const AI_CONTROL: float = 1.0
const AI_MIN_POWER: float = 0.05

var court_type: int = 0
var courts_array : Dictionary
var curve_preference: float = 0.5
var noise_radius: float = 0.0
var difficulty_sigma: float = 0.0

var flight: ThrowFlight
var ball: RigidBody3D

var _selected_throw: Dictionary = {}

func _ready():
	courts_array = {
		"Flat" : 0,
		"Dirty" : 1,
		"Grass" : 2,
		"Pro" : 3,
		"Sand" : 4,
	}
	GameManager.connect("bocha_spawned", update_bocha)
	rng = RandomNumberGenerator.new()
	rng.randomize()
	model = AIInverseModel.new()
	load_data()
	court_type = courts_array[GameManager.court] # 0=Flat,1=Dirty,2=Grass,3=Pro,4=Sand
	print("LA IA ESTA EN LA CANCHA: ", court_type)
	## Temporal:
	set_difficulty(4)       # 0=facil, 4=dificil
	curve_preference = 1.0

## Carga los archivos JSON de datos de simulación.
## data_path: carpeta donde están los throws_*.json
## Retorna true si se cargó al menos una cancha.
func load_data(data_path: String = "res://resources/ai_data/") -> bool:
	var ok = model.load_all(data_path)
	if ok:
		_loaded = true
	return ok

## Retorna true si los datos están cargados y listos para usar.
func is_loaded() -> bool:
	return _loaded and model.throws_by_court.size() > 0

## Decide los parámetros de tiro para llegar al bochin.
## ball_pos: posición de la bocha que va a tirar
## bochin_pos: posición del objetivo (bochin)
## Retorna AIThrowParams con todos los parámetros listos para ThrowFlight.
func decide(ball_pos: Vector3, bochin_pos: Vector3) -> AIThrowParams:
	if not _loaded:
		return _fallback_throw(ball_pos, bochin_pos)

	var target_x = bochin_pos.x + rng.randf_range(-noise_radius, noise_radius)
	var target_z = bochin_pos.z + rng.randf_range(-noise_radius, noise_radius)
	model.curve_preference = curve_preference

	## Buscar los K candidatos más cercanos y elegir uno (ponderado por distancia)
	var candidates = model.find_nearest_k(target_x, target_z, court_type, K_CANDIDATES)
	if candidates.is_empty():
		return _fallback_throw(ball_pos, bochin_pos)

	var params_dict = _weighted_random_pick(candidates, target_x, target_z)

	## DEBUG: Imprimir tiro elegido y proximidad al objetivo
	_debug_print_selection(params_dict, bochin_pos, candidates)

	_selected_throw = params_dict

	var p = AIThrowParams.new()
	p.power = clampf(float(params_dict.get("pw", 0.5)), 0.0, 1.0)
	p.angle_offset = float(params_dict.get("ang", 0.0))
	p.curve_intensity = clampf(float(params_dict.get("ci", 0.0)), 0.0, 1.0)
	p.curve_side = clampf(float(params_dict.get("cs", 1.0)), -1.0, 1.0)
	p.is_straight = bool(params_dict.get("str", false))

	if difficulty_sigma > 0.001:
		p.power = clampf(p.power + rng.randfn(0, difficulty_sigma * 0.1), MIN_POWER, 1.0)
		p.angle_offset = clampf(p.angle_offset + rng.randfn(0, difficulty_sigma * 0.1), -0.5, 0.5)
		p.curve_intensity = clampf(p.curve_intensity + rng.randfn(0, difficulty_sigma * 0.05), 0.0, 1.0)

	var sim_target_pos = Vector3(float(params_dict.get("tx", bochin_pos.x)), ball_pos.y, float(params_dict.get("tz", bochin_pos.z)))
	p.compute_direction(ball_pos, sim_target_pos)
	p.compute_waypoints(ball_pos, sim_target_pos)
	return p

## Ejecuta un tiro completo: decide parámetros y lanza la bocha.
## Requiere haber llamado setup_for_throw() antes.
## Emite la señal throw_ready con los parámetros usados.
func execute_throw(ball_pos: Vector3, bochin_pos: Vector3):
	var p = decide(ball_pos, bochin_pos)
	if not flight or not ball:
		print("returned")
		return
	_setup_flight()
	if p.is_straight or p.waypoints.size() < 2:
		flight.launch_straight(p.power, p.direction)
	else:
		flight.launch(p.power, p.direction, p.waypoints)
	throw_ready.emit(p)

## Configura referencias antes de tirar (sin stats de personaje).
## ball_ref: RigidBody3D de la bocha que se va a lanzar
## flight_ref: ThrowFlight que maneja el vuelo de la bocha
func setup_for_throw(ball_ref: RigidBody3D, flight_ref: ThrowFlight):
	ball = ball_ref
	flight = flight_ref
	if not flight:
		print("no flight")
	var start_pos = GameManager.global_ball_pos
	var bochin_pos = GameManager.bochin.global_position if GameManager.bochin else Vector3(15, 0.438, 0)
	execute_throw(start_pos, bochin_pos)

## Configura la dificultad de la IA (ruido en los parámetros).
## level: 0=muy fácil (mucho error), 4=muy difícil (casi perfecto)
func set_difficulty(level: int):
	match level:
		0: difficulty_sigma = 0.4
		1: difficulty_sigma = 0.25
		2: difficulty_sigma = 0.15
		3: difficulty_sigma = 0.08
		4: difficulty_sigma = 0.00
		_: difficulty_sigma = 0.15

## Configura ThrowFlight con stats propios de la IA y la fricción de la cancha.
## Usa mf/ef del tiro seleccionado si están disponibles, sino defaults de IA.
func _setup_flight():
	if not flight:
		return
	var mf = float(_selected_throw.get("mf", AI_MAX_FORCE))
	var ef = float(_selected_throw.get("ef", AI_EFECTO))
	flight.efecto = ef * COURT_FRICTIONS[clampi(court_type, 0, 4)]
	flight.precision = AI_PRECISION
	flight.control = AI_CONTROL
	flight.max_force = mf
	flight.min_power = AI_MIN_POWER
	flight.ball = ball

## Tiro de emergencia cuando no hay datos cargados.
## Va recto al bochin con potencia proporcional a la distancia.
func _fallback_throw(ball_pos: Vector3, bochin_pos: Vector3) -> AIThrowParams:
	var p = AIThrowParams.new()
	var dist = ball_pos.distance_to(bochin_pos)
	p.power = clampf(dist / 30.0, MIN_POWER, 1.0)
	p.angle_offset = 0.0
	p.is_straight = true
	p.curve_intensity = 0.0
	p.curve_side = 1.0
	p.compute_direction(ball_pos, bochin_pos)
	return p

## Selección aleatoria ponderada: elige un tiro de los candidatos
## con probabilidad inversamente proporcional a su distancia al target.
func _weighted_random_pick(candidates: Array, tx: float, tz: float) -> Dictionary:
	var weights: Array[float] = []
	var total: float = 0.0
	for t in candidates:
		var dx = float(t["fx"]) - tx
		var dz = float(t["fz"]) - tz
		var d2 = dx * dx + dz * dz
		var w = 1.0 / maxf(sqrt(d2), 0.01)
		weights.append(w)
		total += w

	var roll = rng.randf() * total
	var acc = 0.0
	for i in range(candidates.size()):
		acc += weights[i]
		if roll <= acc:
			return candidates[i]
	return candidates[candidates.size() - 1]

## DEBUG: Imprime en consola el tiro elegido, la posición objetivo, y las distancias.
func _debug_print_selection(selected: Dictionary, bochin_pos: Vector3, all_candidates: Array):
	var fx = float(selected.get("fx", 0))
	var fz = float(selected.get("fz", 0))
	var tx = float(selected.get("tx", 0))
	var tz = float(selected.get("tz", 0))
	var dist = sqrt(pow(fx - bochin_pos.x, 2) + pow(fz - bochin_pos.z, 2))
	print("=== AI THROW DEBUG ===")
	print("  Court: %s (idx=%d)" % [model.COURT_NAMES[clampi(court_type, 0, 4)], court_type])
	print("  Target (bochin): x=%.2f z=%.2f" % [bochin_pos.x, bochin_pos.z])
	print("  Sim aim target (tx/tz): x=%.2f z=%.2f" % [tx, tz])
	print("  Selected throw lands at: x=%.2f z=%.2f" % [fx, fz])
	print("  Distance to target: %.2f m" % dist)
	print("  Params: pw=%.3f ang=%.3f ci=%.3f cs=%.3f str=%s" % [
		float(selected.get("pw", 0)), float(selected.get("ang", 0)),
		float(selected.get("ci", 0)), float(selected.get("cs", 0)),
		str(selected.get("str", false))
	])
	print("  All %d candidates distances:" % all_candidates.size())
	for i in range(all_candidates.size()):
		var c = all_candidates[i]
		var cd = sqrt(pow(float(c["fx"]) - bochin_pos.x, 2) + pow(float(c["fz"]) - bochin_pos.z, 2))
		print("    [%d] lands=(%.2f, %.2f) aim=(%.2f, %.2f) dist=%.2f ci=%.3f" % [i, float(c["fx"]), float(c["fz"]), float(c.get("tx", 0)), float(c.get("tz", 0)), cd, float(c["ci"])])
	print("======================")

func update_bocha(bocha : RigidBody3D) -> void:
	ball = bocha
	if !GameManager.p1_turn and GameManager.vsAI:
		await get_tree().create_timer(3).timeout
		setup_for_throw(ball, flight)
		print("playing vs ai ... computer throwing")
	else:
		print("not playing against ai")

func _on_button_pressed() -> void:
	setup_for_throw(ball, flight)
