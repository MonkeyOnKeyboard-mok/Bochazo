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

var phase: Phase = Phase.IDLE
var charge_start: Vector2 = Vector2.ZERO
var aim_points: PackedVector2Array = []
var aim_start_y: float = 0.0

@onready var charge_line: Line2D = $ChargeLine
@onready var aim_line: Line2D = $AimLine

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_on_click(event)
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
	phase = Phase.CHARGE
	charge_start = pos
	aim_points.clear()
	if charge_line: charge_line.clear_points(); charge_line.add_point(pos)
	if aim_line: aim_line.clear_points()
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
	if aim_line: aim_line.clear_points(); aim_line.add_point(pos)
	aim_started.emit(pos)

func _on_motion(event: InputEventMouseMotion):
	var pos = event.position
	if phase == Phase.CHARGE:
		if charge_line: charge_line.add_point(Vector2(charge_start.x, pos.y))
		charge_dragging.emit(pos, charge_start)
	elif phase == Phase.AIM:
		var clamped = Vector2(pos.x, minf(pos.y, aim_start_y))
		if aim_points.size() < max_aim_points:
			aim_points.append(clamped)
			if debug_enabled and aim_line: aim_line.add_point(clamped)
			aim_drawing.emit(aim_points)

func _end_aim():
	phase = Phase.IDLE
	aim_ended.emit(aim_points)

func reset():
	phase = Phase.IDLE
	aim_points.clear()
	if charge_line: charge_line.clear_points()
	if aim_line: aim_line.clear_points()
