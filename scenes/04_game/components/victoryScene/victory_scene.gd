extends Node3D

const RAUL = preload("uid://q8voutlmwa4p")
const JORGE = preload("uid://efushocvm3e8")
const BETO = preload("uid://dit3ym5ot60fp")

@onready var marker_p_1: Marker3D = $p1/SubVP1/MarkerP1
@onready var marker_p_2: Marker3D = $p2/SubVP2/MarkerP2
@onready var menu_b: TextureButton = $Menu
@onready var rematch_b: TextureButton = $Rematch

signal rematch

var test = true

var chars : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = false
	menu_b.visible = false
	rematch_b.visible = false
	GameManager.connect("spawn_victory_anims", add_characters)
	chars = {
		"Raul" = RAUL,
		"Jorge" = JORGE,
		"Beto" = BETO,
	}
	#add_characters_test()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func add_characters() -> void:
	await get_tree().create_timer(1).timeout
	self.visible = true
	menu_b.visible = true
	rematch_b.visible = true
	var char1 = chars[GameManager.player1_char].instantiate()
	marker_p_1.add_child(char1)
	var char2 = chars[GameManager.player2_char].instantiate()
	marker_p_2.add_child(char2)
	if did_player1_win():
		char1.tag = "winner"
		char2.tag = "loser"
	else:
		char2.tag = "winner"
		char1.tag = "loser"
	char1.play_anim()
	char2.play_anim()

func add_characters_test() -> void:
	var char1 = RAUL.instantiate()
	marker_p_1.add_child(char1)
	var char2 = JORGE.instantiate()
	marker_p_2.add_child(char2)
	if did_player1_win():
		char1.tag = "winner"
		char2.tag = "loser"
	else:
		char2.tag = "winner"
		char1.tag = "loser"
	char1.play_anim()
	char2.play_anim()

func did_player1_win() -> bool:
	if GameManager.winner == "player1":
		return true
	else: return false

func _on_menu_pressed() -> void:
	emit_signal("rematch")
	Audio.main_loop_out()
	await get_tree().create_timer(1).timeout
	get_tree().change_scene_to_file("res://scenes/01_main_menu/main_menu.tscn")
	GameManager.run_full_reset()
	print("Cargando menu")

func _on_rematch_pressed() -> void:
	emit_signal("rematch")
	await get_tree().create_timer(1).timeout
	get_tree().change_scene_to_file("res://scenes/04_game/components/GameCourt/game_court.tscn")
	GameManager.is_rematch = true
	GameManager.run_full_reset()
	print("Cargando partida")
