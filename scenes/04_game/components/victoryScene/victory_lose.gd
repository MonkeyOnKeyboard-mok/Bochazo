extends Node3D

var tag : String = ""
@onready var anim: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func play_anim() -> void:
	if tag == "winner":
		anim.play("win")
	else:
		anim.play("lose")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "lose":
		anim.play("lose_idle")
