extends Node

## Vs AI flag
var vsAI : bool = false

var player1_char = null
var player2_char = null


## Match Variables 
var p1_turn = true  ## If false, it's P2 or CPU turn

var p1_turns : int = 6
var p2_turns : int = 6

## Bochas Variables
var bochin_thrown : bool = false
var bochas_thrown : Array = []
var bochas_distance : Array = []

func deduct_turn(player: String) -> void:
	match player:
		"player1":
			p1_turns -= 1
		"player2":
			p2_turns -= 1

func who_is_closer() -> void:
	if bochas_distance[0].size() == 0 : return
	for bocha in bochas_thrown:
		if bocha.distance_to_bochin < bochas_distance[0]:
			bochas_distance.push_front(bocha.distance_to_bochin)
	if bochas_thrown[0].team_tag == "player1":
		p1_turn = true
	else: p1_turn = false

func first_bocha(distance: float) -> void:
	bochas_distance.append(distance)

func reset_all() -> void:
	p1_turn = true  
	p1_turns = 6
	p2_turns = 6
	bochin_thrown = false
	bochas_thrown  = []
	bochas_distance  = []
