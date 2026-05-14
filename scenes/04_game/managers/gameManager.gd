extends Node

var vsAI : bool = false

var player1_char = null
var player2_char = null


## Match Variables 

var p1_turn = true

var p1_turns : int = 6
var p2_turns : int = 6

func deduct_turn(player: String) -> void:
	match player:
		"player1":
			p1_turns -= 1
		"player2":
			p2_turns -= 1
