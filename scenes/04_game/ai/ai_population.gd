class_name AIPopulation
extends RefCounted

var individuals: Array[AIThrowParams] = []
var fitnesses: Array[float] = []
var population_size: int = 10
var elite_count: int = 5
var mutation_rate: float = 0.3
var mutation_power: float = 0.15

func initialize():
	individuals.clear()
	fitnesses.clear()
	for i in range(population_size):
		individuals.append(_random_individual())
		fitnesses.append(0.0)

func evolve():
	if individuals.size() < elite_count: return
	var sorted = _get_sorted_indices()
	var new_pop: Array[AIThrowParams] = []
	for i in range(elite_count):
		new_pop.append(individuals[sorted[i]].duplicate() as AIThrowParams)
	for i in range(elite_count, population_size):
		var parent_idx = sorted[randi() % elite_count]
		var child = individuals[parent_idx].duplicate() as AIThrowParams
		_mutate(child)
		new_pop.append(child)
	individuals = new_pop
	fitnesses.clear()
	for i in range(population_size):
		fitnesses.append(0.0)

func get_top_n(count: int) -> Array[AIThrowParams]:
	var sorted = _get_sorted_indices()
	var result: Array[AIThrowParams] = []
	var n = mini(count, sorted.size())
	for i in range(n):
		result.append(individuals[sorted[i]].duplicate() as AIThrowParams)
	return result

func get_best() -> AIThrowParams:
	if individuals.is_empty(): return _random_individual()
	var best_idx = 0
	var best_fit = fitnesses[0]
	for i in range(fitnesses.size()):
		if fitnesses[i] > best_fit:
			best_fit = fitnesses[i]
			best_idx = i
	return individuals[best_idx]

func get_best_fitness() -> float:
	var best = -999.0
	for f in fitnesses:
		if f > best: best = f
	return best

func get_avg_fitness() -> float:
	if fitnesses.is_empty(): return 0.0
	var total = 0.0
	for f in fitnesses: total += f
	return total / fitnesses.size()

func _random_individual() -> AIThrowParams:
	var p = AIThrowParams.new()
	var r = randf()
	if r < 0.3:
		p.power = randf_range(0.4, 0.65)
		p.angle_offset = randf_range(-0.05, 0.05)
		p.curve_intensity = randf_range(0.2, 0.5)
	elif r < 0.65:
		p.power = randf_range(0.55, 0.85)
		p.angle_offset = randf_range(-0.1, 0.1)
		p.curve_intensity = randf_range(0.15, 0.7)
	else:
		p.power = randf_range(0.75, 1.0)
		p.angle_offset = randf_range(-0.12, 0.12)
		p.curve_intensity = randf_range(0.3, 0.9)
	p.curve_side = 1.0 if randi() % 2 == 0 else -1.0
	p.is_straight = randf() < 0.15
	if p.is_straight: p.curve_intensity = 0.0
	return p

func _mutate(p: AIThrowParams):
	if randf() < mutation_rate:
		p.power = clampf(p.power + randf_range(-mutation_power, mutation_power), 0.3, 1.0)
	if randf() < mutation_rate:
		p.angle_offset = clampf(p.angle_offset + randf_range(-0.08, 0.08), -0.3, 0.3)
	if randf() < mutation_rate:
		p.curve_intensity = clampf(p.curve_intensity + randf_range(-0.2, 0.2), 0.0, 1.0)
	if randf() < 0.15:
		p.is_straight = not p.is_straight
		if p.is_straight: p.curve_intensity = 0.0
	if randf() < 0.2:
		p.curve_side = -p.curve_side

func _get_sorted_indices() -> Array[int]:
	var indices: Array[int] = []
	for i in range(fitnesses.size()):
		indices.append(i)
	indices.sort_custom(func(a, b): return fitnesses[a] > fitnesses[b])
	return indices