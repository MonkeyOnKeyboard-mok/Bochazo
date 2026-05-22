extends Node
class_name ThrowAim

var efecto: float = 0.5

var waypoints: PackedVector3Array = []
var _simplify_dist: float = 0.5

func build_path(aim_points: PackedVector2Array, ball_pos: Vector3) -> PackedVector3Array:
	var camera = get_viewport().get_camera_3d()
	if not camera or aim_points.size() < 2:
		waypoints.clear()
		return waypoints

	var ground_pts = PackedVector3Array()
	for pt in aim_points:
		var gpt = _screen_to_ground(pt, camera, ball_pos.y)
		ground_pts.append(gpt)

	var offset = ball_pos - ground_pts[0]
	waypoints.clear()
	var smoothed = _smooth_3d(ground_pts, 2)
	for pt in smoothed:
		waypoints.append(pt + offset)

	waypoints = _simplify(waypoints, _simplify_dist)
	return waypoints

func _screen_to_ground(pos: Vector2, camera: Camera3D, ground_y: float) -> Vector3:
	var from = camera.project_ray_origin(pos)
	var dir = camera.project_ray_normal(pos)
	if absf(dir.y) < 0.001:
		return Vector3(from.x, ground_y, from.z)
	var t = (ground_y - from.y) / dir.y
	return from + dir * t

func _smooth_3d(pts: PackedVector3Array, passes: int) -> PackedVector3Array:
	var result = pts.duplicate()
	for _p in passes:
		if result.size() < 3: break
		var next = PackedVector3Array()
		next.append(result[0])
		for i in range(1, result.size() - 1):
			next.append(result[i - 1] * 0.25 + result[i] * 0.5 + result[i + 1] * 0.25)
		next.append(result[result.size() - 1])
		result = next
	return result

func _simplify(pts: PackedVector3Array, min_dist: float) -> PackedVector3Array:
	if pts.size() < 3: return pts
	var result = PackedVector3Array()
	result.append(pts[0])
	for i in range(1, pts.size() - 1):
		if (pts[i] - result[result.size() - 1]).length() >= min_dist:
			result.append(pts[i])
	result.append(pts[pts.size() - 1])
	return result