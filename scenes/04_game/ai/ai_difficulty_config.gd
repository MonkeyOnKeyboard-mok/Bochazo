class_name AIDifficultyConfig
extends Resource

@export var difficulty: int = 0
@export var difficulty_name: String = "Easy"
@export var sigma_juego: float = 0.35

const DIFFICULTY_SIGMAS: Array[float] = [0.35, 0.25, 0.15, 0.08, 0.02]

static func get_sigma(diff: int) -> float:
	return DIFFICULTY_SIGMAS[clampi(diff, 0, 4)]