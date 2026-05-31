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
	if !moving:
		move_left()
		move_right()
		choose()
	if current_character.my_name:
		nombre.text = current_character.my_name

func move_left() -> void:
	if Input.is_action_just_pressed("move_right"):
		if index+1 >= player_list.size(): return
		if moving == true: return
		_handle_movement(Vector3(-2,0,0),Vector3(0, deg_to_rad(-450), 0),"left")

func move_right() -> void:
	if Input.is_action_just_pressed("move_left"):
		if index-1 <= -1: return
		if moving == true: return
		_handle_movement(Vector3(2,0,0),Vector3(0, deg_to_rad(450), 0),"right")

func choose() -> void:
	if Input.is_action_just_pressed("choose"):
		if court_chose: return
		if !court_chose:
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

func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://scenes/04_game/components/GameCourt/game_court.tscn")
	print("Cargando partida")
