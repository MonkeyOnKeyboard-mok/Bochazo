extends Node

@export_file("*.tscn") var next_scene: String = "res://scenes/01_main_menu/main_menu.tscn"
@onready var fade: FadeTransition = $FadeTransition

func _ready():
	await get_tree().process_frame # Dar tiempo a Autoloads
	await fade.fade_out()
	get_tree().change_scene_to_file(next_scene)
