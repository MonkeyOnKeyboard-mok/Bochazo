extends Resource
class_name PhysicsConfig

@export_group("Ball Physics")
@export var ball_mass: float = 1.0
@export var ball_friction: float = 0.5
@export var ball_bounce: float = 0.3
@export var linear_damping: float = 0.8
@export var angular_damping: float = 0.9

@export_group("Throw Mechanics")
@export var min_throw_power: float = 5.0
@export var max_throw_power: float = 25.0
@export var power_multiplier: float = 1.5
@export var spin_multiplier: float = 2.0
@export var curve_sensitivity: float = 1.2
