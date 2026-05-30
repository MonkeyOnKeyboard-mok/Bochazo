extends Node3D
class_name AICEMTrainingController

@export var ball_scene: PackedScene
@export var stats: PlayerThrowStats

@onready var train_btn: Button = $CanvasLayer/TrainBtn
@onready var cancel_btn: Button = $CanvasLayer/CancelBtn
@onready var save_btn: Button = $CanvasLayer/SaveBtn
@onready var diff_opt: OptionButton = $CanvasLayer/DiffOpt
@onready var court_opt: OptionButton = $CanvasLayer/CourtOpt
@onready var status_lbl: Label = $CanvasLayer/StatusLbl
@onready var progress_lbl: Label = $CanvasLayer/ProgressLbl
@onready var params_lbl: Label = $CanvasLayer/ParamsLbl
@onready var bochin_marker: Node3D = $BochinMarker

var trainer: AICEMTrainer
var simulator: AICEMSimulator
var _training: bool = false
var _current_court: Node = null
var _current_court_idx: int = -1

const COURT_SCENES: Array[String] = [
	"res://scenes/04_game/components/court/flat_court.tscn",
	"res://scenes/04_game/components/court/dirty_court.tscn",
	"res://scenes/04_game/components/court/grass_court.tscn",
	"res://scenes/04_game/components/court/pro_court.tscn",
	"res://scenes/04_game/components/court/sand_court.tscn"
]
const COURT_FRICTIONS: Array[float] = [1.0, 0.8, 0.9, 1.1, 0.6]
const COURT_NAMES: Array[String] = ["Flat", "Dirty", "Grass", "Pro", "Sand"]

const ITER_CONFIGS: Array = [
	{"M": 15, "K": 50, "iters": 20, "sigma": 0.5},
	{"M": 25, "K": 50, "iters": 40, "sigma": 0.5},
	{"M": 40, "K": 50, "iters": 60, "sigma": 0.5},
	{"M": 50, "K": 50, "iters": 80, "sigma": 0.5},
	{"M": 60, "K": 50, "iters": 100, "sigma": 0.5},
]

func _ready():
	train_btn.pressed.connect(_on_train)
	cancel_btn.pressed.connect(_on_cancel)
	save_btn.pressed.connect(_on_save)
	_populate_difficulties()
	_populate_courts()

	trainer = AICEMTrainer.new()
	add_child(trainer)
	trainer.iteration_done.connect(_on_iteration)
	trainer.training_done.connect(_on_done)
	trainer.court_swap_requested.connect(_on_court_swap)
	trainer.scenario_started.connect(_on_scenario)

func _populate_difficulties():
	diff_opt.add_item("Quick (M=15 K=50 20iter)", 0)
	diff_opt.add_item("Normal (M=25 K=50 40iter)", 1)
	diff_opt.add_item("Good (M=40 K=50 60iter)", 2)
	diff_opt.add_item("Deep (M=50 K=50 80iter)", 3)
	diff_opt.add_item("Full (M=60 K=50 100iter)", 4)

func _populate_courts():
	court_opt.add_item("All Courts", -1)
	for cn in COURT_NAMES:
		court_opt.add_item(cn, COURT_NAMES.find(cn))

func _on_train():
	if _training:
		return
	if not ball_scene:
		status_lbl.text = "ERROR: No ball scene!"
		return

	_training = true
	train_btn.disabled = true

	if simulator and is_instance_valid(simulator):
		simulator.queue_free()
	simulator = AICEMSimulator.new()
	add_child(simulator)
	simulator.init_simulator(ball_scene)
	_current_court_idx = -1

	trainer.simulator = simulator
	trainer.target_court = court_opt.get_selected_id()

	var idx = diff_opt.get_selected_id()
	var config = ITER_CONFIGS[mini(idx, ITER_CONFIGS.size() - 1)]
	trainer.scenarios_per_iter = config["M"]
	trainer.samples_per_scenario = config["K"]
	trainer.max_iterations = config["iters"]
	trainer.sigma_decay = 0.92
	trainer.min_sigma = 0.02
	var start_sigma: float = config["sigma"]

	var court_name = "ALL" if trainer.target_court < 0 else COURT_NAMES[trainer.target_court]
	status_lbl.text = "Training %s... M=%d K=%d iters=%d" % [court_name, config["M"], config["K"], config["iters"]]
	await trainer.start_training(simulator, start_sigma)

func _on_iteration(iter: int, sigma: float, best_reward: float, avg_reward: float, best_dist: float, avg_dist: float, elite_count: int, court_stats: Dictionary):
	progress_lbl.text = "Iter %d/%d | throws=%d | best_d=%.2fm | avg_d=%.2fm | best_r=%.3f" % [
		iter + 1, trainer.max_iterations, trainer.total_throws, best_dist, avg_dist, best_reward
	]

	if trainer.simulator and is_instance_valid(trainer.simulator):
		bochin_marker.global_position = trainer.simulator._bochin_marker.global_position

	var court_lines = ""
	for cn in COURT_NAMES:
		if court_stats.has(cn):
			var cs = court_stats[cn]
			if cs["n"] > 0:
				court_lines += "%s: σ=%.3f best=%.2fm avg=%.2fm r=%.3f (n=%d)\n" % [
					cn, cs["sigma"], cs["best_d"], cs["avg_d"], cs["best_r"], cs["n"]
				]
			else:
				court_lines += "%s: (no data)\n" % cn

	var ci = maxi(trainer.target_court, 0)
	var p = trainer.policies[ci]
	params_lbl.text = "W[0]: %.3f %.3f %.3f\nb: %.3f %.3f %.3f\n%s" % [
		p.W[0][0], p.W[0][1], p.W[0][2],
		p.b[0], p.b[1], p.b[2],
		court_lines
	]

func _on_court_swap(court_idx: int):
	swap_court_for_training(court_idx)

func _on_scenario(bochin_pos: Vector3, ball_pos: Vector3, court_idx: int):
	bochin_marker.global_position = bochin_pos

func _on_done():
	_training = false
	train_btn.disabled = false
	status_lbl.text = "Done! %d throws in %d iters. Save weights." % [trainer.total_throws, trainer.current_iteration + 1]

func _on_cancel():
	if trainer and trainer.is_training:
		trainer.cancel_training()
	_training = false
	train_btn.disabled = false
	status_lbl.text = "Cancelled."

func _on_save():
	if not trainer or trainer.policies.size() == 0:
		status_lbl.text = "No policy to save!"
		return

	var idx = diff_opt.get_selected_id()
	var weights_res = AICEMWeights.new()
	weights_res.populate_from_policies(trainer.policies, trainer.sigmas, trainer.current_iteration + 1)

	var tres_path = "res://resources/ai_config/cem_weights_diff_%d.tres" % idx
	var err = ResourceSaver.save(weights_res, tres_path)

	for ci in range(5):
		var json_path = "res://resources/ai_config/cem_weights_%s.json" % COURT_NAMES[ci].to_lower()
		trainer.policies[ci].save_to_json(json_path)

	if err == OK:
		status_lbl.text = "Saved: %s\n+ 5 per-court JSONs" % tres_path
	else:
		status_lbl.text = "Error saving! err=%d" % err

func swap_court_for_training(court_idx: int):
	if court_idx == _current_court_idx:
		return
	if _current_court and is_instance_valid(_current_court):
		_current_court.queue_free()
		_current_court = null
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
	_current_court_idx = court_idx
