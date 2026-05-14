extends Node

var player_list : Array = []
var moving : bool = false
var p1_chose : bool = false
var current_character = null
var index : int = 0

@onready var players: Node3D = $Players


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for character in players.get_children():
		player_list.append(character)
	print(player_list)
	# current_character = player_list [index]
	#player_list[0].play("idle") // Jugador 1 hace su animación idle
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if !moving:
		move_left()
		move_right()
		choose()

func move_left() -> void:
	if Input.is_action_just_pressed("move_left"):
		if index+1 >= player_list.size(): return
		moving = true
		for i in player_list:
			var tween = create_tween()
			# Rotate and move simultaneously at the start
			tween.parallel().tween_property(i, "rotation", Vector3(0, deg_to_rad(90), 0), 0.25)
			tween.parallel().tween_property(i, "position", i.position - Vector3(2, 0, 0), 1.5)
			# Wait, then rotate again
			tween.tween_interval(0.1)
			tween.tween_property(i, "rotation", Vector3(0, deg_to_rad(180), 0), 0.25)
		moving = false
		index += 1
		current_character = player_list[index]

func move_right() -> void:
	if Input.is_action_just_pressed("move_right"):
		if index-1 <= -1: return
		moving = true
		for i in player_list:
			var tween = create_tween()
			# Rotate and move simultaneously at the start
			tween.parallel().tween_property(i, "rotation", Vector3(0, deg_to_rad(-90), 0), 0.25)
			tween.parallel().tween_property(i, "position", i.position + Vector3(2, 0, 0), 1.5)
			# Wait, then rotate again
			tween.tween_interval(0.1)
			tween.tween_property(i, "rotation", Vector3(0, deg_to_rad(180), 0), 0.25)
		moving = false
		index -= 1
		current_character = player_list[index]

func choose() -> void:
	if Input.is_action_just_pressed("choose"):
		if !p1_chose:
			GameManager.player1_char = current_character
			p1_chose = true
		else:
			GameManager.player2_char = current_character
