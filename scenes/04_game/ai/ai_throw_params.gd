class_name AIThrowParams
extends Resource

@export var power: float = 0.5
@export var angle_offset: float = 0.0
@export var curve_intensity: float = 0.0
@export var curve_side: float = 1.0
@export var is_straight: bool = false

var direction: Vector3 = Vector3.FORWARD
var waypoints: PackedVector3Array = []

func compute_direction(ball_pos: Vector3, bochin_pos: Vector3) -> Vector3:
	var to_bochin = (bochin_pos - ball_pos)
	to_bochin.y = 0
	if to_bochin.length() < 0.1:
		return Vector3.FORWARD
	return to_bochin.normalized().rotated(Vector3.UP, angle_offset)

func compute_waypoints(ball_pos: Vector3, bochin_pos: Vector3) -> PackedVector3Array:
	if is_straight or curve_intensity < 0.05:
		waypoints.clear()
		return waypoints

	direction = compute_direction(ball_pos, bochin_pos)
	var dist = ball_pos.distance_to(bochin_pos)
	var right = direction.cross(Vector3.UP).normalized()
	var wp_count = int(3 + curve_intensity * 8)
	wp_count = clampi(wp_count, 4, 12)

	waypoints.clear()
	for i in range(wp_count):
		var t = float(i) / float(wp_count - 1)
		var pos = ball_pos + direction * dist * t * 1.1
		var lateral = sin(t * PI) * curve_intensity * curve_side * dist * 0.3
		pos += right * lateral
		pos.y = ball_pos.y
		waypoints.append(pos)

	return waypoints