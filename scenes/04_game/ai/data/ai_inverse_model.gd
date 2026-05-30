class_name AIInverseModel
extends RefCounted

var throws_by_court: Dictionary = {}

var curve_preference: float = 0.5

const COURT_NAMES: Array[String] = ["Flat", "Dirty", "Grass", "Pro", "Sand"]

func load_all(data_path: String = "res://resources/ai_data/") -> bool:
	throws_by_court.clear()
	for cn in COURT_NAMES:
		var path = data_path + "throws_%s.json" % cn.to_lower()
		if not FileAccess.file_exists(path):
			push_error("AIInverseModel: Missing %s" % path)
			continue
		var file = FileAccess.open(path, FileAccess.READ)
		if not file:
			continue
		var json_text = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_text) != OK:
			continue
		var data = json.data
		var throws: Array = []
		for t in data["throws"]:
			throws.append({
				"sx": float(t["sx"]), "sz": float(t["sz"]),
				"pw": float(t["pw"]), "ang": float(t["ang"]),
				"ci": float(t["ci"]), "cs": float(t["cs"]), "str": bool(t["str"]),
				"mf": float(t["mf"]), "ef": float(t["ef"]),
				"fx": float(t["fx"]), "fz": float(t["fz"])
			})
		throws_by_court[cn] = throws
	return throws_by_court.size() > 0

func find_nearest(target_x: float, target_z: float, court_idx: int) -> Dictionary:
	var cn = COURT_NAMES[clampi(court_idx, 0, 4)]
	var throws = throws_by_court.get(cn, []) as Array
	if throws.size() == 0:
		return {}
	var best_throw = throws[0]
	var best_score = _score(target_x, target_z, best_throw)
	for i in range(1, throws.size()):
		var t = throws[i]
		var s = _score(target_x, target_z, t)
		if s < best_score:
			best_score = s
			best_throw = t
	return best_throw

func find_nearest_k(target_x: float, target_z: float, court_idx: int, k: int) -> Array:
	var cn = COURT_NAMES[clampi(court_idx, 0, 4)]
	var throws = throws_by_court.get(cn, []) as Array
	if throws.size() == 0:
		return []
	var scored: Array = []
	for t in throws:
		var s = _score(target_x, target_z, t)
		scored.append({"s": s, "t": t})
	scored.sort_custom(func(a, b): return a["s"] < b["s"])
	var result: Array = []
	for i in range(mini(k, scored.size())):
		result.append(scored[i]["t"])
	return result

func find_function(target_x: float, target_z: float, court_idx: int) -> Dictionary:
	var nearest_5 = find_nearest_k(target_x, target_z, court_idx, 5)
	if nearest_5.size() == 0:
		return {}
	if nearest_5.size() == 1:
		return nearest_5[0]
	var total_weight: float = 0.0
	var pw: float = 0.0
	var ang: float = 0.0
	var ci: float = 0.0
	var cs: float = 0.0
	for t in nearest_5:
		var d = sqrt(_dist2(target_x, target_z, t))
		var dist_w = 1.0 / maxf(d, 0.01)
		var curve_w = 1.0 + t["ci"] * curve_preference
		var w = dist_w * dist_w * curve_w
		total_weight += w
		pw += t["pw"] * w
		ang += t["ang"] * w
		ci += t["ci"] * w
		cs += t["cs"] * w
	if total_weight < 0.001:
		return nearest_5[0]
	return {
		"sx": nearest_5[0]["sx"], "sz": nearest_5[0]["sz"],
		"pw": pw / total_weight, "ang": ang / total_weight,
		"ci": ci / total_weight, "cs": cs / total_weight,
		"str": ci / total_weight < 0.05, "mf": nearest_5[0]["mf"],
		"ef": nearest_5[0]["ef"]
	}

func get_throw_count(court_idx: int) -> int:
	var cn = COURT_NAMES[clampi(court_idx, 0, 4)]
	var throws = throws_by_court.get(cn, []) as Array
	return throws.size()

func _dist2(target_x: float, target_z: float, t: Dictionary) -> float:
	var dx = t["fx"] - target_x
	var dz = t["fz"] - target_z
	return dx * dx + dz * dz

func _score(target_x: float, target_z: float, t: Dictionary) -> float:
	var d2 = _dist2(target_x, target_z, t)
	var curve_bonus = t["ci"] * curve_preference
	return d2 - curve_bonus