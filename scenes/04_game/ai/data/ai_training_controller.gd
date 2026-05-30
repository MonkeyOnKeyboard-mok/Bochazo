class_name AITrainingController
extends Node3D

@export var ball_scene: PackedScene
@export var stats: PlayerThrowStats

@onready var load_btn: Button = $CanvasLayer/LoadBtn
@onready var save_btn: Button = $CanvasLayer/SaveBtn
@onready var status_lbl: Label = $CanvasLayer/StatusLbl
@onready var stats_lbl: Label = $CanvasLayer/StatsLbl

const COURT_NAMES: Array[String] = ["Flat", "Dirty", "Grass", "Pro", "Sand"]

var model: AIInverseModel

func _ready():
	load_btn.pressed.connect(_on_load)
	save_btn.pressed.connect(_on_save)
	model = AIInverseModel.new()

func _on_load():
	var ok = model.load_all()
	if not ok:
		status_lbl.text = "ERROR: No data files found. Run simulation first!"
		return
	var total = 0
	var court_lines = ""
	for cn in COURT_NAMES:
		var count = model.get_throw_count(COURT_NAMES.find(cn))
		total += count
		court_lines += "%s: %d throws\n" % [cn, count]
	stats_lbl.text = court_lines
	status_lbl.text = "Data loaded! %d total throws across 5 courts." % total

func _on_save():
	if model.throws_by_court.size() == 0:
		status_lbl.text = "No data loaded! Load first."
		return
	var path = "res://resources/ai_data/inverse_model.tres"
	var res = AIInverseModelResource.new()
	res.model_data = model.throws_by_court
	var err = ResourceSaver.save(res, path)
	if err == OK:
		status_lbl.text = "Model saved to %s" % path
	else:
		status_lbl.text = "Error saving model: %d" % err
