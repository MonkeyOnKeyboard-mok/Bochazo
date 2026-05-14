extends CanvasLayer
class_name FadeTransition

@export_group("Configuración")
@export var transition_duration: float = 1
@export var debug_verbose: bool = false

# ⚠️ NO usar @onready si vas a acceder en _enter_tree()
var fade_rect: ColorRect
var _active_tween: Tween

func _enter_tree():
	# 🔑 Los hijos ya existen en este punto. Usamos la ruta directa.
	fade_rect = $FadeRect
	if fade_rect == null:
		push_error("[FadeTransition] ❌ Nodo 'FadeRect' no encontrado. Verificá jerarquía.")
		queue_free()
		return
	
	# Forzar estado inicial ANTES de que Godot renderice el primer frame
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.visible = true
	layer = 100

func fade_out() -> void:
	fade_rect.color = Color(0, 0, 0, 0)
	await get_tree().process_frame # Sincronizar con el renderizador
	await _tween_to(Color(0, 0, 0, 1))

func fade_in() -> void:
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.visible = true
	# ⏳ Esperar a que la GPU dibuje el frame negro COMPLETO
	await RenderingServer.frame_post_draw
	await _tween_to(Color(0, 0, 0, 0))

func _tween_to(target_color: Color) -> void:
	if _active_tween and _active_tween.is_running():
		_active_tween.kill()
		
	_active_tween = create_tween()
	_active_tween.tween_property(fade_rect, "color", target_color, transition_duration)
	_active_tween.set_trans(Tween.TRANS_SINE)
	_active_tween.set_ease(Tween.EASE_IN_OUT)
	
	await _active_tween.finished
	if debug_verbose: print("[FadeTransition] Fade completado")
