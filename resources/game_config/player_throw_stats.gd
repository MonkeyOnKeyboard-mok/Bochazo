class_name PlayerThrowStats
extends Resource

@export_group("Personaje")
@export var player_name: String = "Player"

@export_group("Potencia")
@export var potencia: float = 35.0
@export var min_power: float = 0.05

@export_group("Efecto")
@export var efecto: float = 0.5

@export_group("Precision")
@export var precision: float = 0.95

@export_group("Control")
@export var control: float = 0.85

@export_group("Dibujo")
@export var max_aim_points: int = 60
@export var min_charge_distance: float = 50.0
@export var max_charge_distance: float = 300.0
