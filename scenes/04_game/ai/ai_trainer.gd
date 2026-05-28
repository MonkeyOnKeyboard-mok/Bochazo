class_name AITrainer
extends RefCounted

var max_depth: int = 6
var min_samples: int = 5

func train(contexts: Array[AIContext], params_results: Array) -> AITreeNode:
	if contexts.size() < min_samples:
		return _make_leaf(params_results)

	var best_feature = ""
	var best_threshold = 0.0
	var best_score = -1.0

	for feature in AIContext.FEATURES:
		var values = []
		for ctx in contexts:
			values.append(ctx.feat(feature))
		values.sort()

		for i in range(values.size() - 1):
			var threshold = (values[i] + values[i + 1]) / 2.0
			var score = _evaluate_split(contexts, params_results, feature, threshold)
			if score > best_score:
				best_score = score
				best_feature = feature
				best_threshold = threshold

	if best_score <= 0.001:
		return _make_leaf(params_results)

	var left_ctx: Array[AIContext] = []
	var right_ctx: Array[AIContext] = []
	var left_results: Array = []
	var right_results: Array = []

	for i in range(contexts.size()):
		if contexts[i].get(best_feature) < best_threshold:
			left_ctx.append(contexts[i])
			left_results.append(params_results[i])
		else:
			right_ctx.append(contexts[i])
			right_results.append(params_results[i])

	var node = AITreeNode.new()
	node.feature = best_feature
	node.threshold = best_threshold
	node.is_leaf = false

	if left_ctx.size() >= min_samples and max_depth > 1:
		var sub_trainer = AITrainer.new()
		sub_trainer.max_depth = max_depth - 1
		sub_trainer.min_samples = min_samples
		node.left = sub_trainer.train(left_ctx, left_results)
	else:
		node.left = _make_leaf(left_results)

	if right_ctx.size() >= min_samples and max_depth > 1:
		var sub_trainer = AITrainer.new()
		sub_trainer.max_depth = max_depth - 1
		sub_trainer.min_samples = min_samples
		node.right = sub_trainer.train(right_ctx, right_results)
	else:
		node.right = _make_leaf(right_results)

	return node

func _evaluate_split(contexts: Array[AIContext], results: Array, feature: String, threshold: float) -> float:
	var left_rewards: Array[float] = []
	var right_rewards: Array[float] = []

	for i in range(contexts.size()):
		if contexts[i].get(feature) < threshold:
			left_rewards.append(results[i]["reward"])
		else:
			right_rewards.append(results[i]["reward"])

	if left_rewards.size() == 0 or right_rewards.size() == 0:
		return -1.0

	return _variance_reduction(left_rewards, right_rewards)

func _variance_reduction(left: Array[float], right: Array[float]) -> float:
	var all: Array[float] = []
	all.append_array(left)
	all.append_array(right)
	var total_var = _variance(all)
	var left_var = _variance(left)
	var right_var = _variance(right)
	var n_left = float(left.size())
	var n_right = float(right.size())
	var n_total = n_left + n_right
	return total_var - (n_left / n_total * left_var + n_right / n_total * right_var)

func _variance(values: Array[float]) -> float:
	if values.size() == 0: return 0.0
	var mean = 0.0
	for v in values: mean += v
	mean /= float(values.size())
	var sq_diff = 0.0
	for v in values: sq_diff += (v - mean) * (v - mean)
	return sq_diff / float(values.size())

func _make_leaf(results: Array) -> AITreeNode:
	var leaf = AITreeNode.new()
	leaf.is_leaf = true

	if results.size() == 0:
		leaf.params = AIThrowParams.new()
		return leaf

	var best = results[0]
	for r in results:
		if r["reward"] > best["reward"]:
			best = r

	leaf.params = best["params"]
	return leaf