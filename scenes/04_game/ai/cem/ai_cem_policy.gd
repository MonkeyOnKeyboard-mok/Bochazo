class_name AICEMPolicy
extends RefCounted

const STATE_SIZE: int = 10
const ACTION_SIZE: int = 4

var W: Array = []
var b: Array = []

func _init():
	W = _zeros_2d(ACTION_SIZE, STATE_SIZE)
	b = _zeros_1d(ACTION_SIZE)

func compute_action(state: Array) -> Array:
	var action = _zeros_1d(ACTION_SIZE)
	for i in range(ACTION_SIZE):
		var sum_val = b[i]
		for j in range(STATE_SIZE):
			sum_val += W[i][j] * state[j]
		action[i] = sum_val
	return action

func add_noise(action: Array, sigma: float, rng: RandomNumberGenerator) -> Array:
	var noisy = _zeros_1d(ACTION_SIZE)
	for i in range(ACTION_SIZE):
		noisy[i] = action[i] + rng.randfn(0.0, sigma)
	return noisy

const MIN_POWER: float = 0.4

static func map_action_to_params(action: Array) -> AIThrowParams:
	var p = AIThrowParams.new()
	p.power = MIN_POWER + clampf(action[0], 0.0, 1.0) * (1.0 - MIN_POWER)
	p.angle_offset = clampf(action[1], -1.0, 1.0) * 0.3
	var curve_mag = clampf(action[2], 0.0, 1.0)
	var curve_dir = clampf(action[3], -1.0, 1.0)
	p.curve_intensity = curve_mag
	p.curve_side = curve_dir
	p.is_straight = curve_mag < 0.05
	return p

static func map_action_to_throw_data(action: Array) -> Dictionary:
	return {
		"power": MIN_POWER + clampf(action[0], 0.0, 1.0) * (1.0 - MIN_POWER),
		"angle_offset": clampf(action[1], -1.0, 1.0) * 0.3,
		"curve_magnitude": clampf(action[2], 0.0, 1.0),
		"curve_direction": clampf(action[3], -1.0, 1.0),
		"is_straight": clampf(action[2], 0.0, 1.0) < 0.05
	}

func copy_from(other: AICEMPolicy):
	for i in range(ACTION_SIZE):
		for j in range(STATE_SIZE):
			W[i][j] = other.W[i][j]
		b[i] = other.b[i]

func to_dict() -> Dictionary:
	var w_data = []
	for i in range(ACTION_SIZE):
		w_data.append(W[i].duplicate())
	return {"W": w_data, "b": b.duplicate()}

static func from_dict(d: Dictionary) -> AICEMPolicy:
	var p = AICEMPolicy.new()
	var w_data = d["W"]
	for i in range(ACTION_SIZE):
		for j in range(STATE_SIZE):
			p.W[i][j] = float(w_data[i][j])
	var b_data = d["b"]
	for i in range(ACTION_SIZE):
		p.b[i] = float(b_data[i])
	return p

func save_to_json(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("AICEMPolicy: Cannot write %s" % path)
		return false
	file.store_string(JSON.stringify(to_dict(), "\t"))
	file.close()
	return true

static func load_from_json(path: String) -> AICEMPolicy:
	if not FileAccess.file_exists(path):
		push_error("AICEMPolicy: File not found: %s" % path)
		return null
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_error("AICEMPolicy: JSON parse error in %s" % path)
		return null
	return from_dict(json.data)

func _zeros_2d(rows: int, cols: int) -> Array:
	var result = []
	for _i in range(rows):
		var row = []
		for _j in range(cols):
			row.append(0.0)
		result.append(row)
	return result

func _zeros_1d(size: int) -> Array:
	var result = []
	for _i in range(size):
		result.append(0.0)
	return result