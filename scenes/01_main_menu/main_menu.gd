extends Node
## enums
## consts
## exports
## public vars
var button_type = null
## private vars
## onready vars
@onready var choose_opp: ColorRect = $ChooseOpp
@onready var sub_v1: SubViewportContainer = $SubViewportContainer
@onready var sub_v2: SubViewportContainer = $SubViewportContainer2
@onready var creditos: TextureRect = $CreditosRect

#@onready var fade_transition: ColorRect = $fade_transition
#@onready var creditos_png: TextureRect = $creditosPNG

# "obj_" for node references;
## built-in override methods

func _ready() -> void:
	choose_opp.hide()
	sub_v1.visible = false
	sub_v2.visible = false
	creditos.hide()
	Audio.menu_theme()
	Audio.preloaded_sound("Bochazo_Menu" , -19)
	$FadeTransition/ColorRect/FadeRect.play("fade_out")
	pass

func _process(_delta: float) -> void:
	pass

## public methods

## private methods

func _on_creditos_pressed() -> void:
	#Audio.click()
	button_type = "credits"
	creditos_show()

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_play_pressed() -> void:
	choose_opp.show()
	sub_v1.visible = true
	sub_v2.visible = true
	##Audio.click()
	pass

func creditos_show() -> void:
	creditos.show()

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
	sub_v1.visible = false
	sub_v2.visible = false

func _on_timer_timeout() -> void:
	match button_type:
		"start": 
			get_tree().change_scene_to_file("res://scenes/03_character_select/character_select.tscn")
			print("Cargando selección de personajes")

func _on_exit_2_pressed() -> void:
	creditos.hide()
