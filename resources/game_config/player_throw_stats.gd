class_name PlayerThrowStats
extends Resource

@export_group("General")
@export var player_name: String = "Player"
@export var max_force: float = 35.0
@export var min_power: float = 0.05

@export_group("Aim")
@export var max_spread_deg: float = 1.5
@export var aim_sensitivity: float = 300.0

@export_group("Curve")
@export var curve_strength: float = 0.5
@export var curve_duration: float = 3.0

@export_group("Knuckleball")
@export var wobble_speed: float = 8.0
@export var wobble_force: float = 0.15

@export_group("Drawing")
@export var max_aim_points: int = 60
@export var min_charge_distance: float = 50.0
@export var max_charge_distance: float = 300.0
@export var min_aim_movement: float = 15.0
