extends Node

@export_file("*.tscn") var next_scene: String = "res://scenes/01_main_menu/main_menu.tscn"
@export var transition_duration: float = 3
@export var debug_verbose: bool = false

@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
@onready var anim_player: AnimationPlayer = $CanvasLayer/AnimPlayer

# Eliminá el AnimationPlayer de la escena y usá esto en boot.gd:
func _ready():
	if debug_verbose: print("[Boot] Iniciando carga...")
	await get_tree().process_frame
	
	# Fade a negro usando Tween (Godot 4 standard)
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0,0,0,1), transition_duration)
	await tween.finished
	
	if next_scene.is_empty() or not FileAccess.file_exists(next_scene):
		push_error("[Boot] Escena destino no existe: %s" % next_scene)
		return
		
	get_tree().change_scene_to_file(next_scene)
