## AIThrowBrain — IA de Tiro para Bochazo v2 (Data-Driven)
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
##        brain.setup_for_throw(stats, ball, flight)
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
##   find_function() — Busca los 5 tiros más cercanos al objetivo y promedia
##                     sus parámetros con peso inverso a la distancia² × curva.
##                     Prioriza tiros vistosos según curve_preference.
##   find_nearest()  — Busca el tiro más cercano directamente (sin promediar).
##
class_name AIThrowBrain
extends Node

signal throw_ready(params: AIThrowParams)

var model: AIInverseModel
var rng: RandomNumberGenerator
var _loaded: bool = false

const COURT_FRICTIONS: Array[float] = [1.0, 0.8, 0.9, 1.1, 0.6]
const MIN_POWER: float = 0.4

var court_type: int = 0
var curve_preference: float = 0.5
var noise_radius: float = 0.0
var difficulty_sigma: float = 0.0

var stats: PlayerThrowStats
var flight: ThrowFlight
var ball: RigidBody3D

func _ready():
	rng = RandomNumberGenerator.new()
	rng.randomize()
	model = AIInverseModel.new()
	load_data()

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

	var params_dict = model.find_function(target_x, target_z, court_type)
	if params_dict.is_empty():
		params_dict = model.find_nearest(target_x, target_z, court_type)
	if params_dict.is_empty():
		return _fallback_throw(ball_pos, bochin_pos)

	var p = AIThrowParams.new()
	p.power = MIN_POWER + clampf(float(params_dict.get("pw", 0.5)), 0.0, 1.0) * (1.0 - MIN_POWER)
	p.angle_offset = clampf(float(params_dict.get("ang", 0.0)), -0.3, 0.3)
	p.curve_intensity = clampf(float(params_dict.get("ci", 0.0)), 0.0, 1.0)
	p.curve_side = clampf(float(params_dict.get("cs", 1.0)), -1.0, 1.0)
	p.is_straight = p.curve_intensity < 0.05

	if difficulty_sigma > 0.001:
		p.power = clampf(p.power + rng.randfn(0, difficulty_sigma * 0.1), MIN_POWER, 1.0)
		p.angle_offset = clampf(p.angle_offset + rng.randfn(0, difficulty_sigma * 0.1), -0.5, 0.5)
		p.curve_intensity = clampf(p.curve_intensity + rng.randfn(0, difficulty_sigma * 0.05), 0.0, 1.0)

	p.compute_direction(ball_pos, bochin_pos)
	p.compute_waypoints(ball_pos, bochin_pos)
	return p

## Ejecuta un tiro completo: decide parámetros y lanza la bocha.
## Requiere haber llamado setup_for_throw() antes.
## Emite la señal throw_ready con los parámetros usados.
func execute_throw(ball_pos: Vector3, bochin_pos: Vector3):
	var p = decide(ball_pos, bochin_pos)
	if not flight or not ball:
		return
	_setup_flight()
	if p.is_straight or p.waypoints.size() < 2:
		flight.launch_straight(p.power, p.direction)
	else:
		flight.launch(p.power, p.direction, p.waypoints)
	throw_ready.emit(p)

## Configura referencias antes de tirar.
## stats_res: PlayerThrowStats del jugador (potencia, efecto, etc.)
## ball_ref: RigidBody3D de la bocha que se va a lanzar
## flight_ref: ThrowFlight que maneja el vuelo de la bocha
func setup_for_throw(stats_res: PlayerThrowStats, ball_ref: RigidBody3D, flight_ref: ThrowFlight):
	stats = stats_res
	ball = ball_ref
	flight = flight_ref

## Configura la dificultad de la IA (ruido en los parámetros).
## level: 0=muy fácil (mucho error), 4=muy difícil (casi perfecto)
func set_difficulty(level: int):
	match level:
		0: difficulty_sigma = 0.4
		1: difficulty_sigma = 0.25
		2: difficulty_sigma = 0.15
		3: difficulty_sigma = 0.08
		4: difficulty_sigma = 0.02
		_: difficulty_sigma = 0.15

## Configura ThrowFlight con los stats del jugador y la fricción de la cancha.
func _setup_flight():
	if not flight or not stats:
		return
	flight.efecto = stats.efecto * COURT_FRICTIONS[clampi(court_type, 0, 4)]
	flight.precision = stats.precision
	flight.control = stats.control
	flight.max_force = stats.potencia
	flight.min_power = stats.min_power
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