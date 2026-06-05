extends Node

@onready var main_loop: AudioStreamPlayer = $main_loop
@onready var menu: AudioStreamPlayer = $menu
@onready var rodado: AudioStreamPlayer = $rodado

const LOSE = preload("uid://blnuv0cnxlras")
const WIN = preload("uid://cr7flxb1il8ls")
const LANZAMIENTO = preload("uid://6vohjpusqnxp")
const THUMP = preload("uid://dlsmmd3k7u5b")
const BOCHA_IMPACTO_BOCHA = preload("uid://lgg8emeyomum")
const BOCHA_IMPACTO_BOCHIN = preload("uid://c7xoxp8odfh7h")

const MAX_SPEED = 8.0  # tune this to your typical max ball speed
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

func start_rodando() -> void:
	rodado.volume_db = -20.0
	rodado.pitch_scale = 0.4
	rodado.play()

func update_rodando(speed: float) -> void:
	rodado.pitch_scale = lerp(0.4, 1.2, clampf(speed / MAX_SPEED, 0.0, 1.0))

func stop_rodando() -> void:
	var tween = create_tween()
	tween.tween_property(rodado, "volume_db", -50.0, 1.0)
	await tween.finished
	rodado.stop()
	rodado.volume_db = -20.0

func throw() -> void:
	var player = AudioStreamPlayer.new()
	player.stream = LANZAMIENTO
	add_child(player)
	player.pitch_scale = 0.65
	player.volume_db = -13.066
	player.play()
	player.finished.connect(player.queue_free)

func bocha_impact(ball_velocity: float, collider : Node3D)-> void:
	if collider is BocceBall:
		bocha_bocha_impact(ball_velocity)
		print("playing audio bocha on bocha")
	elif collider is Bochin:
		bocha_bochin_impact(ball_velocity)
		print("playing audio bocha on bochin")
	elif collider.is_in_group("walls"):
		bocha_wall_impact(ball_velocity)
		print("playing audio bocha on wall")

func bocha_bocha_impact(ball_velocity: float) -> void:
	if ball_velocity < 0.3: return
	var player = AudioStreamPlayer.new()
	player.stream = BOCHA_IMPACTO_BOCHA
	add_child(player)
	var t = clampf(ball_velocity / 8.0, 0.0, 1.0)
	player.volume_db = lerpf(-30.0, -15.0, t)   # was -5.0, now -15.0
	player.pitch_scale = lerpf(0.7, 1.0, t)
	player.play()
	player.finished.connect(player.queue_free)

func bocha_bochin_impact(ball_velocity: float) -> void:
	if ball_velocity < 0.3: return
	var player = AudioStreamPlayer.new()
	player.stream = BOCHA_IMPACTO_BOCHIN
	add_child(player)
	var t = clampf(ball_velocity / 8.0, 0.0, 1.0)
	player.volume_db = lerpf(-30.0, -15.0, t)
	player.pitch_scale = lerpf(0.7, 1.0, t)
	player.play()
	player.finished.connect(player.queue_free)

func bocha_wall_impact(ball_velocity: float) -> void:
	var player = AudioStreamPlayer.new()
	player.stream = THUMP
	add_child(player)
	player.volume_db = lerpf(-30.0, -5.0, clampf(ball_velocity / 8.0, 0.0, 1.0))
	player.play()
	player.finished.connect(player.queue_free)
