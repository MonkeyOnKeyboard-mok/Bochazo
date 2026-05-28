extends Node3D
class_name AITrainingController

@export var ball_scene: PackedScene
@export var stats: PlayerThrowStats

@onready var train_btn: Button = $CanvasLayer/TrainBtn
@onready var cancel_btn: Button = $CanvasLayer/CancelBtn
@onready var save_btn: Button = $CanvasLayer/SaveBtn
@onready var diff_opt: OptionButton = $CanvasLayer/DiffOpt
@onready var runner: AITrainingRunner = $Runner
@onready var status_lbl: Label = $CanvasLayer/StatusLbl
@onready var progress_lbl: Label = $CanvasLayer/ProgressLbl
@onready var params_lbl: Label = $CanvasLayer/ParamsLbl
@onready var bochin_marker: Node3D = $BochinMarker

var _training: bool = false

const ITERATIONS = [10, 200, 500, 1000, 2000, 4000]
const SPAWN_POS: Vector3 = Vector3(-25, 1, 0)

func _ready():
	train_btn.pressed.connect(_on_train)
	cancel_btn.pressed.connect(_on_cancel)
	save_btn.pressed.connect(_on_save)
	_populate_difficulties()
	runner.iteration_completed.connect(_on_iteration)
	runner.training_complete.connect(_on_done)
	runner.progress_update.connect(_on_progress)
	runner.bochin_spawned.connect(_on_bochin_spawned)
	runner.court_changed.connect(_on_court_changed)

func _populate_difficulties():
	diff_opt.add_item("QuickTest (10)", 0)
	diff_opt.add_item("Quick (200)", 1)
	diff_opt.add_item("Normal (500)", 2)
	diff_opt.add_item("Good (1000)", 3)
	diff_opt.add_item("Deep (2000)", 4)
	diff_opt.add_item("Full (4000)", 5)

func _on_train():
	if _training: return
	_training = true
	train_btn.disabled = true
	var idx = diff_opt.get_selected_id()
	runner.ball_scene = ball_scene
	runner.spawn_pos = SPAWN_POS
	runner.stats = stats
	runner.ball_parent = self
	status_lbl.text = "Training... (%d iterations)" % ITERATIONS[idx]
	runner.start_training(ITERATIONS[idx])

func _on_iteration(iteration: int, throws: int, buckets: int):
	progress_lbl.text = "Iter %d | throws=%d | buckets=%d" % [iteration + 1, throws, buckets]

func _on_progress(msg: String):
	params_lbl.text = msg

func _on_bochin_spawned(pos: Vector3):
	bochin_marker.global_position = pos

func _on_court_changed(court_type: int, court_name: String):
	status_lbl.text = "Court: %s" % court_name

func _on_done():
	_training = false
	train_btn.disabled = false
	status_lbl.text = "Done! %d throws in %d buckets. Click Save." % [runner.total_throws, runner.db.bucket_count()]

func _on_cancel():
	_training = false
	train_btn.disabled = false

func _on_save():
	if not runner.db or runner.db.bucket_count() == 0:
		status_lbl.text = "No data to save!"
		return
	var idx = diff_opt.get_selected_id()
	var path = "res://resources/ai_config/spatial_db_diff_%d.json" % idx
	runner.db.sort_buckets()
	if runner.db.save_to_json(path):
		status_lbl.text = "Saved: %s" % path
	else:
		status_lbl.text = "Error saving!"
