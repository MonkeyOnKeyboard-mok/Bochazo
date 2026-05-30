extends Node3D
class_name AITestController

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

var brain: AIThrowBrain
var _current_ball: RigidBody3D
var _extra_balls: Array = []
var _throw_count: int = 0
var _current_court: Node = null
var _auto_court: bool = false

const SPAWN_POS: Vector3 = Vector3(-25, 1, 0)
const COURT_LENGTH: float = 35.0
const COURT_WIDTH: float = 13.0
const BALL_Y: float = 1.0

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
	brain = AIThrowBrain.new()
	add_child(brain)
	_randomize_bochin()

func _populate_opts():
	diff_opt.add_item("QuickTest (10)", 0)
	diff_opt.add_item("Quick (200)", 1)
	diff_opt.add_item("Normal (500)", 2)
	diff_opt.add_item("Good (1000)", 3)
	diff_opt.add_item("Deep (2000)", 4)
	diff_opt.add_item("Full (4000)", 5)
	court_opt.add_item("Auto")
	for name in COURT_NAMES:
		court_opt.add_item(name)

func _randomize_bochin():
	var x = randf_range(0.0, COURT_LENGTH)
	var z = randf_range(-COURT_WIDTH / 2.0 + 0.5, COURT_WIDTH / 2.0 - 0.5)
	bochin_marker.global_position = Vector3(x, BALL_Y, z)

func _spawn_extra_balls():
	for b in _extra_balls:
		if is_instance_valid(b): b.queue_free()
	_extra_balls.clear()
	var count = randi() % 4
	for i in range(count):
		var b = ball_scene.instantiate() as RigidBody3D
		var bx = randf_range(2.0, COURT_LENGTH - 2.0)
		var bz = randf_range(-COURT_WIDTH / 2.0 + 0.5, COURT_WIDTH / 2.0 - 0.5)
		b.global_position = Vector3(bx, BALL_Y, bz)
		b.player = "player1" if i % 2 == 0 else "player2"
		add_child(b)
		_extra_balls.append(b)

func _on_throw():
	if _current_ball and is_instance_valid(_current_ball):
		return
	if not stats:
		status_lbl.text = "ERROR: No stats!"
		return
	var idx = diff_opt.get_selected_id()
	var court_idx = court_opt.get_selected_id()
	_auto_court = court_idx == 0
	if _auto_court:
		court_idx = randi() % COURT_NAMES.size() + 1
	court_idx -= 1

	var db_path = "res://resources/ai_config/spatial_db_diff_%d.json" % idx

	var loaded = brain.load_db(db_path)
	if not loaded or not brain.spatial_db or brain.spatial_db.bucket_count() == 0:
		status_lbl.text = "No DB for diff %d! Train first." % idx
		return

	brain.difficulty = idx
	brain.court_type = court_idx

	await _swap_court(court_idx)

	_current_ball = ball_scene.instantiate() as RigidBody3D
	add_child(_current_ball)
	await get_tree().process_frame
	_current_ball.global_position = SPAWN_POS
	_current_ball.freeze = false

	brain.setup_for_throw(stats, _current_ball, flight)
	_spawn_extra_balls()
	_randomize_bochin()
	var spawn_z = randf_range(-COURT_WIDTH / 2.0 + 0.5, COURT_WIDTH / 2.0 - 0.5)
	var throw_pos = Vector3(SPAWN_POS.x, BALL_Y, spawn_z)
	_current_ball.global_position = throw_pos

	var ctx = AIContext.gather(bochin_marker.global_position, court_idx, _extra_balls, stats, throw_pos)
	brain.execute_throw(ctx, throw_pos, bochin_marker.global_position)
	_throw_count += 1

	var p = brain.last_params
	var curve_txt = "STRAIGHT" if p.is_straight else "curve=%.0f%% %s" % [p.curve_intensity * 100, "R" if p.curve_side > 0 else "L"]
	status_lbl.text = "Throw #%d | %s | buckets=%d" % [_throw_count, COURT_NAMES[court_idx], brain.spatial_db.bucket_count()]
	params_lbl.text = "pwr=%.0f%% | ang=%.2f | %s" % [p.power * 100, p.angle_offset, curve_txt]

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

func _on_reset():
	if _current_ball and is_instance_valid(_current_ball):
		_current_ball.queue_free()
		_current_ball = null
	for b in _extra_balls:
		if is_instance_valid(b): b.queue_free()
	_extra_balls.clear()
	_throw_count = 0
	status_lbl.text = "Ready"
	params_lbl.text = ""
