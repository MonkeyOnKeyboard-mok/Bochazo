class_name CourtConfig
extends Resource

@export_group("Surface")
@export var court_friction: float = 0.7
@export var court_bounce: float = 0.2

@export_group("Dimensions")
@export var court_length: float = 30.0
@export var court_width: float = 4.0

@export_group("Walls")
@export var wall_bounce: float = 0.5
