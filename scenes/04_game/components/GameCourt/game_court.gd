extends Node3D

@onready var bocha_spawner: Node3D = $BochaSpawner
@onready var sub_view_balls: TextureRect = $TextureRect
@onready var rtm: Node3D = $RoundTransitionManager
@onready var court_setter: Node3D = $CourtSetter

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$FadeTransition/ColorRect/FadeRect.play("fade_out")
	GameManager.connect("soft_reset", soft_reset)
	GameManager.connect("victory", victory)
	rtm.sub_view = sub_view_balls
	rtm.court = court_setter

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func soft_reset() -> void:
	for b in bocha_spawner.get_children():
		if b is RigidBody3D:
			b.queue_free()

func victory() -> void:
	pass

func trans() -> void: 
	$FadeTransition.show()
	##Audio.menu_out()
	$FadeTransition/Timer.start()
	$FadeTransition/ColorRect/FadeRect.play("fade_in")

func _on_timer_timeout() -> void:
	pass
