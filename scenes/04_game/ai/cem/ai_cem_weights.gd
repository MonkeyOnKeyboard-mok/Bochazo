class_name AICEMWeights
extends Resource

@export var weight_rows: int = 4
@export var weight_cols: int = 10
@export var weights_flat: PackedFloat64Array = []
@export var bias: PackedFloat64Array = []
@export var trained_sigma: float = 0.02
@export var trained_iterations: int = 0
@export var trained_timestamp: String = ""
@export var court_type: int = -1

@export var all_policies_weights: Array = []
@export var all_policies_bias: Array = []
@export var all_sigmas: PackedFloat64Array = []

func populate_from_policy(p: AICEMPolicy, iter_count: int = 0):
	weight_rows = AICEMPolicy.ACTION_SIZE
	weight_cols = AICEMPolicy.STATE_SIZE
	weights_flat = PackedFloat64Array()
	weights_flat.resize(weight_rows * weight_cols)
	for i in range(weight_rows):
		for j in range(weight_cols):
			weights_flat[i * weight_cols + j] = p.W[i][j]
	bias = PackedFloat64Array()
	bias.resize(weight_rows)
	for i in range(weight_rows):
		bias[i] = p.b[i]
	trained_iterations = iter_count
	trained_timestamp = Time.get_datetime_string_from_system()

func populate_from_policies(pols: Array, sigs: Array, iter_count: int = 0):
	all_policies_weights.clear()
	all_policies_bias.clear()
	all_sigmas = PackedFloat64Array()
	for i in range(pols.size()):
		var p = pols[i] as AICEMPolicy
		var w_flat = PackedFloat64Array()
		w_flat.resize(AICEMPolicy.ACTION_SIZE * AICEMPolicy.STATE_SIZE)
		for r in range(AICEMPolicy.ACTION_SIZE):
			for c in range(AICEMPolicy.STATE_SIZE):
				w_flat[r * AICEMPolicy.STATE_SIZE + c] = p.W[r][c]
		all_policies_weights.append(w_flat)
		var b_arr = PackedFloat64Array()
		b_arr.resize(AICEMPolicy.ACTION_SIZE)
		for r in range(AICEMPolicy.ACTION_SIZE):
			b_arr[r] = p.b[r]
		all_policies_bias.append(b_arr)
		all_sigmas.append(sigs[i])
	trained_iterations = iter_count
	trained_timestamp = Time.get_datetime_string_from_system()
	if pols.size() > 0:
		populate_from_policy(pols[0], iter_count)
		court_type = -1

func to_policy() -> AICEMPolicy:
	var p = AICEMPolicy.new()
	for i in range(weight_rows):
		for j in range(weight_cols):
			p.W[i][j] = weights_flat[i * weight_cols + j]
	for i in range(weight_rows):
		p.b[i] = bias[i]
	return p

func to_policies() -> Array:
	var result: Array = []
	for i in range(all_policies_weights.size()):
		var p = AICEMPolicy.new()
		var w_flat = all_policies_weights[i] as PackedFloat64Array
		var b_arr = all_policies_bias[i] as PackedFloat64Array
		for r in range(AICEMPolicy.ACTION_SIZE):
			for c in range(AICEMPolicy.STATE_SIZE):
				p.W[r][c] = w_flat[r * AICEMPolicy.STATE_SIZE + c]
		for r in range(AICEMPolicy.ACTION_SIZE):
			p.b[r] = b_arr[r]
		result.append(p)
	return result