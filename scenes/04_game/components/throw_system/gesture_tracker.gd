extends Node
class_name GestureTracker

enum Phase { IDLE, CHARGE, WAITING, AIM }

signal charge_started(pos: Vector2)
signal charge_dragging(current: Vector2, start: Vector2)
signal charge_ended(power_frac: float, lateral: float)
signal aim_started(pos: Vector2)
signal aim_drawing(points: PackedVector2Array)
signal aim_ended(points: PackedVector2Array)

@export var debug_enabled: bool = true
@export var max_aim_points: int = 60
@export var min_charge_distance: float = 50.0
@export var max_charge_distance: float = 300.0
@export var charge_visual_scale: float = 1.5

const VIEWPORT_CENTER := Vector2(960, 540)

var phase: Phase = Phase.IDLE
var charge_start: Vector2 = Vector2.ZERO
var aim_points: PackedVector2Array = []
var aim_start_y: float = 0.0

@onready var charge_line: Line2D = $DrawViewport/ChargeLine
@onready var charge_line_outline: Line2D = $DrawViewport/ChargeLineOutline
@onready var aim_line: Line2D = $DrawViewport/AimLine
@onready var aim_line_outline: Line2D = $DrawViewport/AimLineOutline
@onready var power_bar: ProgressBar = %PowerBar
@onready var draw_viewport: SubViewport = $DrawViewport
@onready var plane_drawing: MeshInstance3D = $PlaneDrawing

func _ready() -> void:
	GameManager.connect("throw", reset)
	_setup_plane_texture()

func _screen_to_draw_pos(screen_pos: Vector2) -> Variant:
	var camera := get_viewport().get_camera_3d()
	if not camera: return null
	
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	
	var normal := plane_drawing.global_transform.basis.y.normalized()
	var point := plane_drawing.global_transform.origin
	
	var denom := dir.dot(normal)
	if absf(denom) < 0.001: return null
	var t := (point - from).dot(normal) / denom
	if t < 0: return null
	
	var hit_world: Vector3 = from + dir * t
	var hit_local: Vector3 = plane_drawing.global_transform.affine_inverse() * hit_world
	
	var aabb := plane_drawing.mesh.get_aabb()
	var uv := Vector2(
		(hit_local.x - aabb.position.x) / aabb.size.x,
		(hit_local.z - aabb.position.z) / aabb.size.z
	)
	
	if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
		return null
	
	return Vector2(uv.x * draw_viewport.size.x, uv.y * draw_viewport.size.y)

func _setup_plane_texture() -> void:
	var mat := plane_drawing.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat.albedo_texture = draw_viewport.get_texture()

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if GameManager.permission_to_throw:
			print("You have permission to throw")
			_on_click(event)
		else: 
			print("You DON'T have permission to throw")
	elif event is InputEventMouseMotion and phase in [Phase.CHARGE, Phase.AIM]:
		_on_motion(event)

func _on_click(event: InputEventMouseButton):
	if event.pressed:
		match phase:
			Phase.IDLE: _start_charge(event.position)
			Phase.WAITING: _start_aim(event.position)
	else:
		match phase:
			Phase.CHARGE: _end_charge(event.position)
			Phase.AIM: _end_aim()

func _start_charge(pos: Vector2):
	GameManager.emit_signal("charge_throw")
	phase = Phase.CHARGE
	charge_start = pos
	aim_points.clear()
	if charge_line: charge_line.clear_points(); charge_line.add_point(VIEWPORT_CENTER)
	if charge_line_outline: charge_line_outline.clear_points(); charge_line_outline.add_point(VIEWPORT_CENTER)
	if aim_line: aim_line.clear_points()
	if aim_line_outline: aim_line_outline.clear_points()
	charge_started.emit(pos)

func _end_charge(pos: Vector2):
	var dist = absf(pos.y - charge_start.y)
	if dist < min_charge_distance:
		phase = Phase.IDLE
		charge_ended.emit(0.0, 0.0)
		return
	var frac = clampf(dist / max_charge_distance, 0.0, 1.0)
	var lateral = (pos.x - charge_start.x) / max_charge_distance
	phase = Phase.WAITING
	charge_ended.emit(frac, lateral)

func _start_aim(pos: Vector2):
	phase = Phase.AIM
	aim_start_y = pos.y
	aim_points = [pos]
	var draw_pos = _screen_to_draw_pos(pos)
	if draw_pos and aim_line: aim_line.clear_points(); aim_line.add_point(draw_pos)
	if draw_pos and aim_line_outline: aim_line_outline.clear_points(); aim_line_outline.add_point(draw_pos)
	aim_started.emit(pos)

func _on_motion(event: InputEventMouseMotion):
	var pos = event.position
	power_bar.show()
	if phase == Phase.CHARGE:
		if charge_line:
			var dist = absf(pos.y - charge_start.y)
			var frac = clampf(dist / max_charge_distance, 0.0, 1.0)
			var end_pt = VIEWPORT_CENTER - Vector2(0, frac * max_charge_distance * charge_visual_scale)
			charge_line.clear_points()
			charge_line.add_point(VIEWPORT_CENTER)
			charge_line.add_point(end_pt)
			charge_line.default_color = _power_color(frac)
			charge_line_outline.clear_points()
			charge_line_outline.add_point(VIEWPORT_CENTER)
			charge_line_outline.add_point(end_pt)
			charge_dragging.emit(pos, charge_start)
	elif phase == Phase.AIM:
		var clamped = Vector2(pos.x, minf(pos.y, aim_start_y))
		if aim_points.size() < max_aim_points:
			aim_points.append(clamped)
			var draw_pos = _screen_to_draw_pos(clamped)
			if draw_pos:
				if debug_enabled and aim_line: aim_line.add_point(draw_pos)
				if aim_line_outline: aim_line_outline.add_point(draw_pos)
			aim_drawing.emit(aim_points)

func _power_color(frac: float) -> Color:
	if frac < 0.5:
		return Color.GREEN.lerp(Color.YELLOW, frac * 2.0)
	else:
		return Color.YELLOW.lerp(Color.RED, (frac - 0.5) * 2.0)

func _end_aim():
	phase = Phase.IDLE
	aim_ended.emit(aim_points)

func reset():
	power_bar.hide()
	phase = Phase.IDLE
	aim_points.clear()
	if charge_line: charge_line.clear_points()
	if charge_line_outline: charge_line_outline.clear_points()
	if aim_line: aim_line.clear_points()
	if aim_line_outline: aim_line_outline.clear_points()
