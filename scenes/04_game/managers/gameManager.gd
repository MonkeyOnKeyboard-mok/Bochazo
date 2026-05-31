extends Node

## Global Event Signals

## Bocha Signals
@warning_ignore("unused_signal")
signal spawn_bocha()
@warning_ignore("unused_signal")
signal bocha_spawned(bocha : RigidBody3D)

## Player Manager Signals
@warning_ignore("unused_signal")
signal despawn
@warning_ignore("unused_signal")
signal respawn (char_name : String)

## Player Animation Signals
@warning_ignore("unused_signal")
signal idle
@warning_ignore("unused_signal")
signal charge_throw
@warning_ignore("unused_signal")
signal throw
@warning_ignore("unused_signal")
signal win
@warning_ignore("unused_signal")
signal lose
@warning_ignore("unused_signal")
signal recover_alpha

## Game Signals
@warning_ignore("unused_signal")
signal update_scoreboard(score: int, inc_player: String)

## Vs AI flag
var vsAI : bool = false

var player1_char : String = "Raul"
var player2_char : String = "Jorge"

## Match Variables 
var first_turn : bool = true
var first_bocha_thrown : bool = false

var p1_turn = true  ## If false, it's P2 or CPU turn

var p1_turns : int = 6
var p2_turns : int = 6

var p1_score: int = 0
var p2_score : int = 0

var current_player : Node3D = null
var throw_for_real : bool = false ## Fix rústico para un problema con la animación

## Bochas Variables
var bochin : Bochin = null

var bochin_thrown : bool = false
var bochas_thrown : Array = []
var bochas_distance : Array = []

var speed_threshold : float = 0.2

func deduct_turn(player: String) -> void:
	match player:
		"player1":
			p1_turns -= 1
		"player2":
			p2_turns -= 1
	have_all_balls_stopped()
	#who_is_closer()

func have_all_balls_stopped()-> void:
	if bochas_thrown.size() == 0: return
	if !bochin: return
	var full_array : Array = bochas_thrown.duplicate()
	full_array.append(bochin)
	while true:
		await get_tree().process_frame
		var all_stopped = true
		for bocha in full_array:
			if bocha.linear_velocity.length() > speed_threshold:
				all_stopped = false
				print("Not all balls have stopped, trying again")
				break
		if all_stopped:
				print("All balls have stopped")
				break
	who_is_closer()

func who_is_closer() -> void:
	if bochas_thrown.size() == 0:
		return

	var closest_bocha = bochas_thrown[0]
	var closest_dist = closest_bocha.global_position.distance_to(bochin.global_position)

	for bocha in bochas_thrown:
		var distance = bocha.global_position.distance_to(bochin.global_position)
		print("Distancia de %s: %.2f" % [bocha.player, distance])
		if distance < closest_dist:
			closest_dist = distance
			closest_bocha = bocha

	p1_turn = closest_bocha.player == "player2" 
	if p1_turn and p1_turns <= 0:
		p1_turn = false
	elif not p1_turn and p2_turns <= 0:
		p1_turn = true

	if p1_turns <= 0 and p2_turns <= 0:
		who_won()
	if p1_turn:
		emit_signal("respawn", player1_char)
		print("Spawnear al player 1")
	else:
		emit_signal("respawn", player2_char)
		print("Spawnear al player 2")
	print("Más cerca: ", closest_bocha.player)
	print("Bochas en la cancha: ", bochas_thrown)
	if p1_turns != 0 or p2_turns != 0:
		GameManager.spawn_bocha.emit()
	else:
		#  Añadir Animacion de score  y reset de la cancha 
		print("Reset scene")
		pass

func who_won() -> void:
	var bochas_1 : Array = []
	var bochas_2 : Array = []
	var score : int = 0
	for bocha in bochas_thrown:
		var value = bocha.global_position.distance_to(bochin.global_position)
		if bocha.player == "player1":
			bochas_1.append(value)
		else: 
			bochas_2.append(value)
	if bochas_1.size() >0 and  bochas_2.size() > 0:
		print("BEEP BOOP ANALIZANDO DATOS")
		if bochas_1.min() < bochas_2.min():
			for bocha in bochas_1:
				if bocha < bochas_2.min():
					score+=1
			p1_score += score
			emit_signal("update_scoreboard", score, player1_char)
		else: 
			for bocha in bochas_2:
				if bocha < bochas_1.min():
					score+=1
			p2_score += score
			emit_signal("update_scoreboard", score, player2_char)
	

func first_bocha(distance: float) -> void:
	bochas_distance.append(distance)
	first_bocha_thrown = true
	p1_turn = false

func reset_all() -> void:
	p1_turn = true  
	p1_turns = 6
	p2_turns = 6
	bochin = null
	bochin_thrown = false
	bochas_thrown  = []
	bochas_distance  = []
