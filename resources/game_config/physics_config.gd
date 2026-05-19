class_name PhysicsConfig
extends Resource

@export_group("Ball Physics")
@export var ball_mass: float = 1.0
@export var ball_friction: float = 0.5
@export var ball_bounce: float = 0.3
@export var linear_damping: float = 0.2
@export var angular_damping: float = 0.3
@export var stop_velocity_threshold: float = 0.1
