class_name AICEMMatrix
extends RefCounted

static func zeros(rows: int, cols: int) -> Array:
	var m = []
	for i in range(rows):
		var row = []
		for j in range(cols):
			row.append(0.0)
		m.append(row)
	return m

static func zeros_vec(size: int) -> Array:
	var v = []
	for i in range(size):
		v.append(0.0)
	return v

static func identity(size: int) -> Array:
	var m = zeros(size, size)
	for i in range(size):
		m[i][i] = 1.0
	return m

static func multiply(a: Array, b: Array) -> Array:
	var a_rows = a.size()
	var a_cols = a[0].size()
	var b_cols = b[0].size()
	var result = zeros(a_rows, b_cols)
	for i in range(a_rows):
		for j in range(b_cols):
			var sum = 0.0
			for k in range(a_cols):
				sum += a[i][k] * b[k][j]
			result[i][j] = sum
	return result

static func multiply_vec(mat: Array, vec: Array) -> Array:
	var rows = mat.size()
	var cols = mat[0].size()
	var result = zeros_vec(rows)
	for i in range(rows):
		var sum = 0.0
		for j in range(cols):
			sum += mat[i][j] * vec[j]
		result[i] = sum
	return result

static func transpose(m: Array) -> Array:
	var rows = m.size()
	var cols = m[0].size()
	var result = zeros(cols, rows)
	for i in range(rows):
		for j in range(cols):
			result[j][i] = m[i][j]
	return result

static func invert(m: Array) -> Array:
	var n = m.size()
	var aug = zeros(n, 2 * n)
	for i in range(n):
		for j in range(n):
			aug[i][j] = m[i][j]
		aug[i][n + i] = 1.0
	for col in range(n):
		var max_row = col
		for row in range(col + 1, n):
			if absf(aug[row][col]) > absf(aug[max_row][col]):
				max_row = row
		var temp = aug[col]
		aug[col] = aug[max_row]
		aug[max_row] = temp
		if absf(aug[col][col]) < 1e-10:
			return identity(n)
		var pivot = aug[col][col]
		for j in range(2 * n):
			aug[col][j] /= pivot
		for row in range(n):
			if row == col:
				continue
			var factor = aug[row][col]
			for j in range(2 * n):
				aug[row][j] -= factor * aug[col][j]
	var result = zeros(n, n)
	for i in range(n):
		for j in range(n):
			result[i][j] = aug[i][n + j]
	return result

static func solve_least_squares(s_mat: Array, a_mat: Array, ridge: float = 0.01) -> Array:
	var s_t = transpose(s_mat)
	var s_t_s = multiply(s_t, s_mat)
	var n = s_t_s.size()
	for i in range(n):
		s_t_s[i][i] += ridge
	var s_t_a = multiply(s_t, a_mat)
	var inv = invert(s_t_s)
	return multiply(inv, s_t_a)

static func ragged_to_augmented(states: Array, actions: Array) -> Dictionary:
	var n = states.size()
	if n == 0:
		return {"s_aug": [], "a": []}
	var s_dim = states[0].size() + 1
	var a_dim = actions[0].size()
	var s_aug = zeros(n, s_dim)
	var a = zeros(n, a_dim)
	for i in range(n):
		for j in range(states[0].size()):
			s_aug[i][j] = states[i][j]
		s_aug[i][states[0].size()] = 1.0
		for j in range(a_dim):
			a[i][j] = actions[i][j]
	return {"s_aug": s_aug, "a": a}