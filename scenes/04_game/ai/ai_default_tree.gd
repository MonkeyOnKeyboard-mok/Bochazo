class_name AIDefaultTree
extends RefCounted

static func build() -> AITreeNode:
	var root = AITreeNode.new()
	root.feature = "offense_need"
	root.threshold = 1.0
	root.is_leaf = false

	var close_curve = _make_curve(0.55, 0.08, 0.5)
	var mid_curve = _make_curve(0.7, 0.12, 0.65)
	var far_curve = _make_curve(0.85, 0.15, 0.8)
	var secure_straight = _make_straight(0.4, 0.02)

	var winning_root = AITreeNode.new()
	winning_root.feature = "bochin_dist_norm"
	winning_root.threshold = 0.35
	winning_root.is_leaf = false
	winning_root.left = close_curve
	winning_root.right = secure_straight

	var losing_root = AITreeNode.new()
	losing_root.feature = "bochin_dist_norm"
	losing_root.threshold = 0.5
	losing_root.is_leaf = false
	losing_root.left = mid_curve
	losing_root.right = far_curve

	root.left = winning_root
	root.right = losing_root

	return root

static func _make_straight(power: float, angle: float) -> AITreeNode:
	var leaf = AITreeNode.new()
	leaf.is_leaf = true
	leaf.params = AIThrowParams.new()
	leaf.params.power = power
	leaf.params.angle_offset = angle
	leaf.params.curve_intensity = 0.0
	leaf.params.is_straight = true
	return leaf

static func _make_curve(power: float, angle: float, curve: float) -> AITreeNode:
	var leaf = AITreeNode.new()
	leaf.is_leaf = true
	leaf.params = AIThrowParams.new()
	leaf.params.power = power
	leaf.params.angle_offset = angle
	leaf.params.curve_intensity = curve
	leaf.params.curve_side = 1.0 if randi() % 2 == 0 else -1.0
	leaf.params.is_straight = false
	return leaf