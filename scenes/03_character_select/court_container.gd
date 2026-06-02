extends Node3D

var courts : Array = [
	"Dirty",
	"Flat",
	"Grass",
	"Pro",
	"Sand",
	]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_players()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func set_players() -> void:
	for i in get_children().size():
		var child = get_child(i)
		child.my_name = courts[i]
