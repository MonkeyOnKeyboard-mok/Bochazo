extends Node
class_name GestureTracker

enum Phase { CHARGE, AIM }

@export var debug_enabled: bool = true
@export var max_aim_points: int = 60
@export var min_charge_distance: float = 50.0
@export var max_charge_distance: float = 300.0
@export var min_aim_movement: float = 15.0

@onready var charge_line: Line2D = $ChargeLine
@onready var aim_line: Line2D = $AimLine

var start_pos: Vector2
var aim_points: PackedVector2Array = []
var is_tracking: bool = false
var phase: Phase = Phase.CHARGE
var charge_distance: float = 0.0
var prev_pos: Vector2 = Vector2.ZERO
var aim_start_pos: Vector2 = Vector2.ZERO
var aim_movement_total: float = 0.0

signal gesture_started(start_pos: Vector2)
signal gesture_dragging(current: Vector2, start: Vector2)
signal gesture_phase_changed(phase: int)
signal gesture_ended(aim_points: PackedVector2Array, was_straight: bool)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_tracking = event.pressed
		if is_tracking:
			start_pos = event.position
			aim_points.clear()
			charge_distance = 0.0
			phase = Phase.CHARGE
			prev_pos = start_pos
			aim_movement_total = 0.0
			if charge_line: charge_line.clear_points()
			if aim_line: aim_line.clear_points()
			_add_charge_point(start_pos)
			gesture_started.emit(start_pos)
		else:
			var was_straight = (phase == Phase.CHARGE) or (aim_movement_total < min_aim_movement)
			gesture_ended.emit(aim_points, was_straight)

	elif is_tracking and event is InputEventMouseMotion:
		var pos = event.position
		var dy = pos.y - prev_pos.y

		if phase == Phase.CHARGE:
			_add_charge_point(pos)
			charge_distance += maxf(dy, 0.0)

			if (dy <= 0.0 and charge_distance >= min_charge_distance) or charge_distance >= max_charge_distance:
				phase = Phase.AIM
				aim_start_pos = pos
				if aim_line: aim_line.clear_points()
				aim_points.clear()
				aim_points.append(pos)
				if aim_line: aim_line.add_point(pos)
				gesture_phase_changed.emit(Phase.AIM)

		elif phase == Phase.AIM:
			var dx = pos.x - prev_pos.x
			var moved_enough = absf(dx) > 1.0 or dy < -1.0

			if moved_enough:
				aim_movement_total += Vector2(dx, dy).length()

				if max_aim_points > 0 and aim_points.size() >= max_aim_points:
					is_tracking = false
					gesture_ended.emit(aim_points, false)
				else:
					aim_points.append(pos)
					if debug_enabled and aim_line:
						aim_line.add_point(pos)

		gesture_dragging.emit(pos, start_pos)
		prev_pos = pos

func _add_charge_point(pos: Vector2):
	var vertical_pos = Vector2(start_pos.x, pos.y)
	if debug_enabled and charge_line:
		charge_line.add_point(vertical_pos)
