# VisualEffects.gd
extends Node3D

var trail_particles: GPUParticles3D
var power_indicator: MeshInstance3D

func _ready() -> void:
	trail_particles = $TrailParticles
	if trail_particles:
		trail_particles.emitting = false

func show_power_indicator() -> void:
	# Se puede implementar con un ProgressBar 2D o un mesh 3D
	# Por ahora, solo activamos un flag
	pass

func hide_power_indicator() -> void:
	pass

func update_power_indicator(progress: float) -> void:
	# progress va de 0.0 a 1.0
	# Se puede usar para actualizar una barra de potencia
	pass

func play_throw_effect() -> void:
	if trail_particles:
		trail_particles.emitting = true

func update_trail(speed: float) -> void:
	if trail_particles and trail_particles.emitting:
		trail_particles.speed_scale = speed / 5.0
