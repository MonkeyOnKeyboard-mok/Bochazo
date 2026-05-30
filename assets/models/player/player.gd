extends Node3D

var current_player : bool = false
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var marker: Marker3D = $Armature_001/Skeleton3D/BoneAttachment3D/BallPos

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	make_model_transparent(self, 0.2)
	#enable_shadows(self) ### Not working
	GameManager.connect("idle", play_idle_anim)
	GameManager.connect("charge_throw", play_charge_throw_anim)
	GameManager.connect("throw", play_throw_anim)
	GameManager.connect("win", play_win_anim)
	GameManager.connect("lose", play_lose_anim)
	#GameManager.connect("recover_alpha", recover_alpha)
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

func recover_alpha() -> void:
	make_model_transparent(self, 1.0) ## Le devuelve la transparencia, pero creo que está duplicando todos
	# los meshes

func make_model_transparent(node: Node, alpha: float):
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var mat = node.get_active_material(i)

			if mat:
				mat = mat.duplicate()
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.albedo_color.a = alpha

				node.set_surface_override_material(i, mat)

	for child in node.get_children():
		make_model_transparent(child, alpha)

func enable_shadows(node: Node):
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		
	for child in node.get_children():
		enable_shadows(child)
