extends Node3D

var current_player : bool = false
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var marker: Marker3D = $Armature_001/Skeleton3D/BoneAttachment3D/BallPos

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.connect("idle", play_idle_anim)
	GameManager.connect("charge_throw", play_charge_throw_anim)
	GameManager.connect("throw", play_throw_anim)
	GameManager.connect("win", play_win_anim)
	GameManager.connect("lose", play_lose_anim)
	GameManager.current_player = self

func _process(_delta: float) -> void:
	pass

func play_idle_anim() -> void:
	anim.play("idle")
func play_charge_throw_anim() -> void:
	anim.play("throw_1")
func play_throw_anim() -> void:
	anim.play("throw_2")
func play_win_anim() -> void:
	anim.play("win")
func play_lose_anim() -> void:
	anim.play("lose")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "throw_2":
		GameManager.throw_for_real = true
