extends Node3D

const DIRTY_COURT = preload("uid://btroi2t6atcbl")
const FLAT_COURT = preload("uid://b6kn74l0pgn83")
const GRASS_COURT = preload("uid://b4bqnwgulw6e6")
const PRO_COURT = preload("uid://b4jiwlexyi4s2")
const SAND_COURT = preload("uid://ch5lpe2hjqysw")

const BRAIN = preload("uid://47q000na4tmm")

var courts : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	courts = {
		"Dirty" : DIRTY_COURT,
		"Flat" : FLAT_COURT,
		"Grass" : GRASS_COURT,
		"Pro" : PRO_COURT,
		"Sand" : SAND_COURT,
	}
	settings()
	if GameManager.vsAI:
		await get_tree().process_frame
		print("spawneando cerebro")
		var scene = BRAIN
		var brain = scene.instantiate()
		get_parent().add_child(brain)
		GameManager.emit_signal("brain_connect")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func settings() -> void:
	await get_tree().process_frame
	print("spawneando cancha")
	var scene = courts[GameManager.court]
	print(scene)
	var court = scene.instantiate()
	print(court)
	add_child(court)
