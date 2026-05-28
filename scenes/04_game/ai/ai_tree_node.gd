class_name AITreeNode
extends Resource

@export var feature: String = ""
@export var threshold: float = 0.0
@export var is_leaf: bool = false
@export var params: AIThrowParams
@export var left: AITreeNode
@export var right: AITreeNode

func decide(context: AIContext) -> AIThrowParams:
	if is_leaf:
		return params

	var value = context.feat(feature)
	if value < threshold:
		if left:
			return left.decide(context)
		return params
	else:
		if right:
			return right.decide(context)
		return params
