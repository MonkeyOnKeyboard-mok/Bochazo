extends Node

## Global Event Signals
signal spawn_bocha()
signal bocha_spawned(bocha : RigidBody3D)
## Vs AI flag
var vsAI : bool = false

var player1_char = null
var player2_char = null

## Match Variables 
var first_turn : bool = true
var first_bocha_thrown : bool = false

var p1_turn = true  ## If false, it's P2 or CPU turn

var p1_turns : int = 6
var p2_turns : int = 6

## Bochas Variables
var bochin : Bochin = null
var bochin_pos : Vector3 = Vector3.ZERO

var bochin_thrown : bool = false
var bochas_thrown : Array = []
var bochas_distance : Array = []

func deduct_turn(player: String) -> void:
	match player:
		"player1":
			p1_turns -= 1
		"player2":
			p2_turns -= 1
	who_is_closer()

func who_is_closer() -> void:
	if bochas_distance.size() == 0 : return
	bochin_pos = bochin.position
	for bocha in bochas_thrown:
		if bocha.distance_to_bochin < bochas_distance[0]:
			bochas_distance.push_front(bocha.distance_to_bochin)
	if bochas_thrown[0].player == "player1":
		p1_turn = true
	else: p1_turn = false

func first_bocha(distance: float) -> void:
	bochas_distance.append(distance)
	first_bocha_thrown = true
	p1_turn = false

func reset_all() -> void:
	p1_turn = true  
	p1_turns = 6
	p2_turns = 6
	bochin = null
	bochin.pos = Vector3.ZERO
	bochin_thrown = false
	bochas_thrown  = []
	bochas_distance  = []
