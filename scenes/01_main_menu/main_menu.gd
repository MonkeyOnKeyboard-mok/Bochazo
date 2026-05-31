extends Node
## enums
## consts
## exports
## public vars
var button_type = null
## private vars
## onready vars
@onready var choose_opp: ColorRect = $ChooseOpp
#@onready var fade_transition: ColorRect = $fade_transition
#@onready var creditos_png: TextureRect = $creditosPNG

# "obj_" for node references;
## built-in override methods

func _ready() -> void:
	choose_opp.hide()
	#creditos_png.hide()
	Audio.main_theme()
	$FadeTransition/ColorRect/FadeRect.play("fade_out")
	pass
	
func _process(_delta: float) -> void:
	pass

## public methods

## private methods

func _on_creditos_pressed() -> void:
	#Audio.click()
	button_type = "credits"
	creditos()

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_play_pressed() -> void:
	choose_opp.show()
	##Audio.click()
	pass

func creditos() -> void:
	#creditos_png.show()
	pass

func _on_salir_creditos_pressed() -> void:
	#creditos_png.hide()
	pass

func _on_vs_player_pressed() -> void:
	button_type = "start"
	$FadeTransition.show()
	##Audio.menu_out()
	$FadeTransition/Timer.start()
	$FadeTransition/ColorRect/FadeRect.play("fade_in")
	
func _on_vs_cpu_pressed() -> void:
	GameManager.vsAI = true
	button_type = "start"
	$FadeTransition.show()
	##Audio.menu_out()
	$FadeTransition/Timer.start()
	$FadeTransition/ColorRect/FadeRect.play("fade_in")

func _on_back_pressed() -> void:
	choose_opp.hide()

func _on_timer_timeout() -> void:
	match button_type:
		"start": 
			get_tree().change_scene_to_file("res://scenes/03_character_select/character_select.tscn")
			print("Cargando selección de personajes")
