class_name ThrowConfig
extends Resource

@export_group("Power")
@export var max_force: float = 35.0
@export var max_drag_px: float = 300.0
@export var min_power: float = 0.05

@export_group("Aim")
@export var max_spread_deg: float = 3.0
@export var aim_sensitivity: float = 300.0
@export var launch_angle_deg: float = 3.0

@export_group("Spin")
@export var steer_force: float = 0.3
@export var min_curve_threshold: float = 0.2
@export var spin_sensitivity: float = 100.0

@export_group("Wobble")
@export var wobble_speed: float = 8.0
@export var wobble_force: float = 0.12

@export_group("Drawing")
@export var max_draw_points: int = 60
