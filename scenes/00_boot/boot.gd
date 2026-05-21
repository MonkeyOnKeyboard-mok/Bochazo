extends Node

@export_file("*.tscn") var next_scene: String = "res://scenes/01_main_menu/main_menu.tscn"
@onready var anim : AnimationPlayer = $FadeTransition/ColorRect/FadeRect
var button_type = null

func _ready():
	await get_tree().process_frame # Dar tiempo a Autoloads
	$FadeTransition/Timer.start()
	$FadeTransition/ColorRect/FadeRect.play("fade_out")

func _on_timer_timeout() -> void:
	$FadeTransition/ColorRect/FadeRect.play("fade_in")
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file(next_scene)
