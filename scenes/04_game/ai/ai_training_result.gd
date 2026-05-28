class_name AITrainingResult
extends Resource

@export var difficulty: int = 0
@export var difficulty_name: String = "Easy"
@export var epochs: int = 0
@export var avg_reward: float = 0.0
@export var best_reward: float = 0.0
@export var best_dist: float = 999.0
@export var court_type: int = 0
@export var stats_name: String = ""
@export var trained_at: String = ""

@export var best_params: AIThrowParams
@export var top_params: Array[AIThrowParams] = []
