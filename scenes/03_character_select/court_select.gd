extends Node

var player_list : Array = []
var moving : bool = false
var court_chose : bool = false
var current_character = null
var index : int = 0


@onready var players: Node3D = $Players
@onready var hud: Node3D = $Hud
@onready var flecha: Sprite3D = $Hud/Flecha
@onready var label_player: Label3D = $Hud/Flecha/Label3D
@onready var nombre: Label3D = $Hud/Nombre
@onready var flecha_der_2: TextureButton = $Flechas/FlechaDer2
@onready var flecha_izq_2: TextureButton = $Flechas/FlechaIzq2



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for character in players.get_children():
		player_list.append(character)
	current_character = player_list [index]
	label_player.text = "Player 1"
	$FadeTransition/ColorRect/FadeRect.play("fade_out")
	#player_list[0].play("idle") // Jugador 1 hace su animación idle
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	disable_arrows()
	if !moving:
		handle_input()
	if current_character.my_name:
		nombre.text = current_character.my_name

func handle_input() -> void:
	if Input.is_action_just_pressed("move_right"):
		move_left()
	if Input.is_action_just_pressed("move_left"):
		move_right()
	if Input.is_action_just_pressed("choose"):
		choose()

func disable_arrows() -> void:
	if index+1 >= player_list.size(): 
		flecha_der_2.disabled = true
	else: flecha_der_2.disabled = false
	if index-1 <= -1:
		flecha_izq_2.disabled = true
	else: flecha_izq_2.disabled = false

func move_left() -> void:
	if index+1 >= player_list.size(): return
	if moving == true: return
	Audio.preloaded_sound("Paso_Select", -5)
	_handle_movement(Vector3(-2,0,0),Vector3(0, deg_to_rad(-450), 0),"left")

func move_right() -> void:
	if index-1 <= -1: return
	if moving == true: return
	Audio.preloaded_sound("Paso_Select", -5)
	_handle_movement(Vector3(2,0,0),Vector3(0, deg_to_rad(450), 0),"right")

func choose() -> void:
	if moving == true: return
	if court_chose: return
	if !court_chose:
		Audio.preloaded_sound("Select", -5)
		GameManager.court = current_character.my_name
		court_chose = true
		trans()

func _handle_movement(mov: Vector3, _rot: Vector3, side: String) -> void:
	hud.visible = false
	moving = true
	var last_tween: Tween
	for i in player_list:
		var tween = create_tween()
		# Rotate and move simultaneously at the start
		tween.parallel().tween_property(i, "position", i.position + mov, 0.25)
		# Wait, then rotate again
		tween.tween_interval(0.1)
		tween.tween_callback(func(): hud.visible = true)
		last_tween = tween
	await last_tween.finished
	moving = false
	match side:
		"left":
			index += 1
		"right":
			index -= 1
	current_character = player_list[index]

func trans() -> void: 
	$FadeTransition.show()
	##Audio.menu_out()
	$FadeTransition/Timer.start()
	$FadeTransition/ColorRect/FadeRect.play("fade_in")
	Audio.menu_theme_out()

func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/04_game/components/GameCourt/game_court.tscn")
	print("Cargando partida")

func _on_flecha_der_pressed() -> void:
	print("Sprite clicked!")
	move_left()

func _on_flecha_izq_pressed() -> void:
	print("Sprite clicked!")
	move_right()

func _on_space_2_pressed() -> void:
	print("Sprite clicked!")
	choose()
