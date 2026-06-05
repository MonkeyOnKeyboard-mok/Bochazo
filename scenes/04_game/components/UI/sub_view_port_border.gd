extends TextureRect

@onready var anim: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#anim.play("fade_out")
	GameManager.connect("soft_reset", start_reset)
	GameManager.connect("full_reset", start_reset)
	#GameManager.connect("soft_reset_end", end_reset)
	#GameManager.connect("rematch", end_reset)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func start_reset()-> void:
	anim.play("fade_in")

#func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	#if anim_name == "fade_in":
		#sub_view.hide()
		#court.visible = false
#
#func end_reset()-> void:
	#court.visible = true
	#sub_view.show()
	#anim.play("fade_out")
