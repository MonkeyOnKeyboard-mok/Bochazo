extends Node3D

const RAUL = preload("uid://foi2dahuh4rr")
const JORGE = preload("uid://dwbsw52v2sis3")
const BETO = preload("uid://dl76ybg055mod")


var characters : Dictionary
var current_player : Node3D = null
var player_pos : Vector3 = Vector3(-29.149, 0.42,-0.968)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.connect("respawn", spawn_character)
	GameManager.connect("soft_reset", _on_soft_reset)
	characters = {
		"Raul" : RAUL,
		"Jorge" : JORGE,
		"Beto" : BETO,
	}
	GameManager.current_player = current_player
	spawn_character(GameManager.player1_char)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_soft_reset()-> void:
	await get_tree().create_timer(1.5).timeout
	spawn_character(GameManager.player1_char)

func spawn_character(char_name : String) -> void:
	if current_player:
		current_player.queue_free()
	await get_tree().process_frame
	print("spawneando pj")
	var scene = characters[char_name]
	print(scene)
	var character = scene.instantiate()
	print(character)
	current_player = character
	GameManager.current_player = current_player
	add_child(character)
	character.global_position = player_pos
	character.rotation_degrees  = Vector3(0,90,0)
	print("finished spawning")
