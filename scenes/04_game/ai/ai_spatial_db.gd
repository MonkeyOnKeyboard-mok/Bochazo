class_name AISpatialDB
extends RefCounted

var buckets: Dictionary = {}
var bucket_size: float = 0.5
var total_recorded: int = 0

func add_throw(court_type: int, initial_distance: float, params: AIThrowParams, error: float) -> void:
	var key = _to_key(court_type, initial_distance)
	if not buckets.has(key):
		buckets[key] = []
	buckets[key].append(_pack(params, error))
	total_recorded += 1

func sort_buckets() -> void:
	for key in buckets:
		buckets[key].sort_custom(func(a, b): return a["error"] < b["error"])

func get_throw(court_type: int, initial_distance: float, difficulty: int = 0) -> AIThrowParams:
	var key = _to_key(court_type, initial_distance)
	if not buckets.has(key) or buckets[key].is_empty():
		key = _find_nearest_key(court_type, initial_distance)
	if not buckets.has(key) or buckets[key].is_empty():
		return null
	var list = buckets[key]
	if list.size() == 1:
		return _unpack(list[0])
	var max_idx = mini(list.size() - 1, difficulty * 2)
	var idx = randi() % (max_idx + 1)
	return _unpack(list[idx])

func bucket_count() -> int:
	return buckets.size()

func throws_in_bucket(key: String) -> int:
	if buckets.has(key):
		return buckets[key].size()
	return 0

func best_error_in_bucket(key: String) -> float:
	if buckets.has(key) and buckets[key].size() > 0:
		return buckets[key][0]["error"]
	return 999.0

func _to_key(court_type: int, dist: float) -> String:
	var rounded = roundf(dist / bucket_size) * bucket_size
	return "c%d_%.1f" % [court_type, rounded]

func _find_nearest_key(court_type: int, target_dist: float) -> String:
	var target_key = _to_key(court_type, target_dist)
	if buckets.has(target_key):
		return target_key
	var best_key = ""
	var best_diff = 999.0
	for key in buckets:
		if not key.begins_with("c%d_" % court_type):
			continue
		var key_dist = float(key.split("_")[1])
		var diff = absf(key_dist - target_dist)
		if diff < best_diff:
			best_diff = diff
			best_key = key
	if best_key == "":
		for key in buckets:
			var key_dist = float(key.split("_")[1])
			var diff = absf(key_dist - target_dist)
			if diff < best_diff:
				best_diff = diff
				best_key = key
	return best_key

func _pack(params: AIThrowParams, error: float) -> Dictionary:
	return {
		"power": params.power,
		"angle_offset": params.angle_offset,
		"curve_intensity": params.curve_intensity,
		"curve_side": params.curve_side,
		"is_straight": params.is_straight,
		"error": error
	}

func _unpack(record: Dictionary) -> AIThrowParams:
	var p = AIThrowParams.new()
	p.power = record["power"]
	p.angle_offset = record["angle_offset"]
	p.curve_intensity = record["curve_intensity"]
	p.curve_side = record["curve_side"]
	p.is_straight = record["is_straight"]
	return p

func save_to_json(path: String) -> bool:
	sort_buckets()
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("AISpatialDB: Cannot open %s for writing" % path)
		return false
	var data = {}
	data["bucket_size"] = bucket_size
	data["total_recorded"] = total_recorded
	var buckets_data = {}
	for key in buckets:
		var arr = []
		for record in buckets[key]:
			arr.append(record)
		buckets_data[key] = arr
	data["buckets"] = buckets_data
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

static func load_from_json(path: String) -> AISpatialDB:
	if not FileAccess.file_exists(path):
		push_error("AISpatialDB: File not found: %s" % path)
		return null
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("AISpatialDB: Cannot open: %s" % path)
		return null
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	var err = json.parse(json_text)
	if err != OK:
		push_error("AISpatialDB: JSON parse error %d in %s" % [err, path])
		return null
	var data = json.data as Dictionary
	if not data:
		push_error("AISpatialDB: Parsed data is not a Dictionary")
		return null
	var db = AISpatialDB.new()
	db.bucket_size = float(data.get("bucket_size", 0.5))
	db.total_recorded = int(data.get("total_recorded", 0))
	var buckets_data = data.get("buckets", {}) as Dictionary
	for key in buckets_data.keys():
		var arr = []
		var throws = buckets_data[key]
		if throws is Array:
			for record in throws:
				if record is Dictionary:
					arr.append(record)
		db.buckets[key] = arr
	return db
