extends Node

@onready var main_loop: AudioStreamPlayer = $main_loop
@onready var menu: AudioStreamPlayer = $menu

const LOSE = preload("uid://blnuv0cnxlras")
const WIN = preload("uid://cr7flxb1il8ls")

#var preloaded_audios : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#preloaded_audios = {
		#"Lose" = LOSE, 
		#"Win" = WIN, 
	#} 
	pass

func menu_theme() -> void:
	menu.play()

func main_theme() -> void:
	main_loop.play()

func menu_theme_out() -> void:
	var tween = create_tween()
	tween.tween_property(menu, "volume_db", -45 , 2.0)
	tween.tween_callback(func ll(): 
		menu.stop() 
		menu.volume_db = -13)

func main_loop_out() -> void:
	var tween = create_tween()
	tween.tween_property(main_loop, "volume_db", -45 , 2.0)
	tween.tween_callback(func ll(): 
		main_loop.stop() 
		main_loop.volume_db = -13)

func win() -> void:
	var player = AudioStreamPlayer.new()
	player.stream = WIN
	add_child(player)
	player.volume_db = -13.066
	player.play()
	player.finished.connect(player.queue_free)

func lose() -> void:
	var player = AudioStreamPlayer.new()
	player.stream = LOSE
	add_child(player)
	player.volume_db = -13.066
	player.play()
	player.finished.connect(player.queue_free)
