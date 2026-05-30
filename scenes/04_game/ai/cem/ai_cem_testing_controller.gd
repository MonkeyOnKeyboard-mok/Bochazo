extends Node3D
class_name AICEMTestingController

@export var ball_scene: PackedScene
@export var stats: PlayerThrowStats

@onready var throw_btn: Button = $CanvasLayer/ThrowBtn
@onready var reset_btn: Button = $CanvasLayer/ResetBtn
@onready var diff_opt: OptionButton = $CanvasLayer/DiffOpt
@onready var court_opt: OptionButton = $CanvasLayer/CourtOpt
@onready var status_lbl: Label = $CanvasLayer/StatusLbl
@onready var params_lbl: Label = $CanvasLayer/ParamsLbl
@onready var flight: ThrowFlight = $ThrowFlight
@onready var bochin_marker: Node3D = $BochinMarker

var policies: Array = []
var rng: RandomNumberGenerator
var _current_ball: RigidBody3D
var _extra_balls: Array = []
var _throw_count: int = 0
var _current_court: Node = null

const SPAWN_X: float = -25.0
const COURT_LENGTH: float = 35.0
const COURT_WIDTH: float = 13.0
const BALL_Y: float = 1.0

const SIGMA_BY_DIFF: Array[float] = [0.35, 0.25, 0.15, 0.08, 0.02]
const COURT_NAMES: Array[String] = ["Flat", "Dirty", "Grass", "Pro", "Sand"]
const COURT_SCENES: Array[String] = [
	"res://scenes/04_game/components/court/flat_court.tscn",
	"res://scenes/04_game/components/court/dirty_court.tscn",
	"res://scenes/04_game/components/court/grass_court.tscn",
	"res://scenes/04_game/components/court/pro_court.tscn",
	"res://scenes/04_game/components/court/sand_court.tscn"
]
const COURT_FRICTIONS: Array[float] = [1.0, 0.8, 0.9, 1.1, 0.6]

func _ready():
	throw_btn.pressed.connect(_on_throw)
	reset_btn.pressed.connect(_on_reset)
	_populate_opts()
	for i in range(5):
		policies.append(AICEMPolicy.new())
	rng = RandomNumberGenerator.new()
	rng.randomize()

func _populate_opts():
	diff_opt.add_item("Easy (0)", 0)
	diff_opt.add_item("Medium-Easy (1)", 1)
	diff_opt.add_item("Medium (2)", 2)
	diff_opt.add_item("Medium-Hard (3)", 3)
	diff_opt.add_item("Hard (4)", 4)
	court_opt.add_item("Auto")
	for name in COURT_NAMES:
		court_opt.add_item(name)

func _load_policy() -> bool:
	var idx = diff_opt.get_selected_id()
	var tres_path = "res://resources/ai_config/cem_weights_diff_%d.tres" % idx
	if ResourceLoader.exists(tres_path):
		var weights_res = load(tres_path) as AICEMWeights
		if weights_res:
			if weights_res.all_policies_weights.size() >= 5:
				var loaded = weights_res.to_policies()
				for i in range(min(5, loaded.size())):
					policies[i] = loaded[i]
				return true
			else:
				policies[0] = weights_res.to_policy()
				for i in range(1, 5):
					policies[i] = policies[0]
				return true
	for ci in range(5):
		var json_path = "res://resources/ai_config/cem_weights_%s.json" % COURT_NAMES[ci].to_lower()
		var p = AICEMPolicy.load_from_json(json_path)
		if p:
			policies[ci] = p
	if policies.size() > 0 and policies[0] != null:
		return true
	status_lbl.text = "No weights for diff %d! Train first." % idx
	return false

func _on_throw():
	if _current_ball and is_instance_valid(_current_ball):
		return
	if not stats:
		status_lbl.text = "ERROR: No stats!"
		return
	if not _load_policy():
		return

	var court_idx = court_opt.get_selected_id()
	if court_idx == 0:
		court_idx = rng.randi() % 5
	else:
		court_idx -= 1

	await _swap_court(court_idx)

	_randomize_bochin()
	_spawn_extra_balls()

	var ball_z = rng.randf_range(-COURT_WIDTH / 2.0 + 0.5, COURT_WIDTH / 2.0 - 0.5)
	var throw_pos = Vector3(SPAWN_X, BALL_Y, ball_z)

	_current_ball = ball_scene.instantiate() as RigidBody3D
	if "training_mode" in _current_ball:
		_current_ball.training_mode = true
	add_child(_current_ball)
	await get_tree().process_frame
	_current_ball.global_position = throw_pos
	_current_ball.freeze = false
	if "_is_stopped" in _current_ball:
		_current_ball._is_stopped = false

	var bochin_pos = bochin_marker.global_position
	var obstacles: Array = []
	for b in _extra_balls:
		if is_instance_valid(b):
			obstacles.append(b.global_position)

	var state = AICEMState.encode_from_game(throw_pos, bochin_pos, court_idx, stats, _extra_balls)
	var policy = policies[clampi(court_idx, 0, 4)]
	var action = policy.compute_action(state)

	var sigma = SIGMA_BY_DIFF[mini(diff_opt.get_selected_id(), 4)]
	var noisy_action = policy.add_noise(action, sigma, rng)

	var p = AICEMPolicy.map_action_to_params(noisy_action)
	p.compute_direction(throw_pos, bochin_pos)
	p.compute_waypoints(throw_pos, bochin_pos)

	flight.efecto = stats.efecto
	flight.precision = stats.precision
	flight.control = stats.control
	flight.max_force = stats.potencia
	flight.min_power = stats.min_power
	flight.ball = _current_ball

	if p.is_straight or p.waypoints.size() < 2:
		flight.launch_straight(p.power, p.direction)
	else:
		flight.launch(p.power, p.direction, p.waypoints)

	_throw_count += 1

	var curve_txt = "STRAIGHT" if p.is_straight else "curve=%.0f%% dir=%.2f" % [p.curve_intensity * 100, p.curve_side]
	status_lbl.text = "Throw #%d | %s | sigma=%.2f" % [_throw_count, COURT_NAMES[court_idx], sigma]
	params_lbl.text = "pwr=%.0f%% | ang=%.2f | %s" % [p.power * 100, p.angle_offset, curve_txt]

	if _current_ball.has_signal("stopped_moving"):
		_current_ball.stopped_moving.connect(_on_ball_stopped, CONNECT_ONE_SHOT)

func _randomize_bochin():
	var x = rng.randf_range(2.0, COURT_LENGTH - 2.0)
	var z = rng.randf_range(-COURT_WIDTH / 2.0 + 0.5, COURT_WIDTH / 2.0 - 0.5)
	bochin_marker.global_position = Vector3(x, BALL_Y, z)

func _spawn_extra_balls():
	for b in _extra_balls:
		if is_instance_valid(b):
			b.queue_free()
	_extra_balls.clear()
	var count = rng.randi() % 5
	for i in range(count):
		var b = ball_scene.instantiate() as RigidBody3D
		var bx = rng.randf_range(2.0, COURT_LENGTH - 2.0)
		var bz = rng.randf_range(-COURT_WIDTH / 2.0 + 0.5, COURT_WIDTH / 2.0 - 0.5)
		b.global_position = Vector3(bx, BALL_Y, bz)
		if "player" in b:
			b.player = "player1" if i % 2 == 0 else "player2"
		if "training_mode" in b:
			b.training_mode = true
		b.freeze = true
		add_child(b)
		_extra_balls.append(b)

func _swap_court(court_idx: int):
	if _current_court and is_instance_valid(_current_court):
		_current_court.queue_free()
		_current_court = null
		await get_tree().process_frame
	var scene = load(COURT_SCENES[court_idx]) as PackedScene
	if scene:
		_current_court = scene.instantiate()
		add_child(_current_court)
		var court_node = _current_court as StaticBody3D
		if court_node:
			var mat = PhysicsMaterial.new()
			mat.friction = COURT_FRICTIONS[court_idx]
			mat.bounce = 0.3
			court_node.physics_material_override = mat
		await get_tree().process_frame

func _on_ball_stopped(_ball_ref):
	status_lbl.text += " | DONE"

func _on_reset():
	if _current_ball and is_instance_valid(_current_ball):
		_current_ball.queue_free()
		_current_ball = null
	for b in _extra_balls:
		if is_instance_valid(b):
			b.queue_free()
	_extra_balls.clear()
	_throw_count = 0
	status_lbl.text = "Ready"
	params_lbl.text = ""