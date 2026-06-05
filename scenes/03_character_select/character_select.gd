extends Node

var player_list : Array = []
var moving : bool = false
var p1_chose : bool = false
var p2_chose : bool = false
var current_character = null
var index : int = 0

const JUGADOR_1 = preload("uid://dq6jc4avxafho")
const JUGADOR_2 = preload("uid://c4us14of6ghtg")
const CPU = preload("uid://3uumt0ch54on")

@onready var players: Node3D = $Players
@onready var hud: Node3D = $Hud
@onready var flecha: Sprite3D = $Hud/Flecha
@onready var nombre: Label3D = $Hud/Nombre
@onready var flecha_der_2: TextureButton = $Flechas/FlechaDer2
@onready var flecha_izq_2: TextureButton = $Flechas/FlechaIzq2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for character in players.get_children():
		player_list.append(character)
	current_character = player_list [index]
	$FadeTransition/ColorRect/FadeRect.play("fade_out")
	#player_list[0].play("idle") // Jugador 1 hace su animación idle

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	disable_arrows()
	if !moving:
		handle_input()
	if current_character.data:
		nombre.text = current_character.data.name

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
	if p1_chose and p2_chose: return
	if !p1_chose:
		GameManager.player1_char = current_character.data.name
		Audio.preloaded_sound("Select", -5)
		Audio.preloaded_sound(current_character.data.name, -5)
		current_character.anim.play("Raul diva")
		p1_chose = true
		current_character.player_num = "player1"
		## Change Flecha to P2 instead of P1
		if !GameManager.vsAI:
			flecha.texture = JUGADOR_2
		else: 
			flecha.texture = CPU
	else:
		GameManager.player2_char = current_character.data.name
		Audio.preloaded_sound("Select", -5)
		Audio.preloaded_sound(current_character.data.name, -5)
		current_character.anim.play("Raul diva")
		p2_chose = true
		trans()

func _handle_movement(mov: Vector3, rot: Vector3, side: String) ->void:
	hud.visible = false
	moving = true
	var last_tween: Tween
	for i in player_list:
		var tween = create_tween()
		i.anim.play("walk")
		# Rotate and move simultaneously at the start
		tween.parallel().tween_property(i, "rotation", rot, 0.25)
		tween.parallel().tween_property(i, "position", i.position + mov, 0.5)
		# Wait, then rotate again
		tween.tween_interval(0.1)
		tween.tween_property(i, "rotation", Vector3(0, deg_to_rad(0), 0), 0.25)
		tween.tween_callback(func(): hud.visible = true)
		last_tween = tween
	await last_tween.finished
	for i in player_list:
		i.anim.play("idle")
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

func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/03_character_select/court_select.tscn")
	print("Cargando selección de cancha")

func _on_flecha_der_pressed() -> void:
	print("Sprite clicked!")
	move_left()

func _on_flecha_izq_pressed() -> void:
	print("Sprite clicked!")
	move_right()

func _on_space_2_pressed() -> void:
	print("Sprite clicked!")
	choose()
