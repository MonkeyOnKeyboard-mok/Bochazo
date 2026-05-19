extends StaticBody3D
class_name Court

@export var court_config: CourtConfig

func _ready():
	_apply_config()

func _apply_config():
	if not court_config: return
	var mat = PhysicsMaterial.new()
	mat.friction = court_config.court_friction
	mat.bounce = court_config.court_bounce
	
	# Aplicar a todas las CollisionShape3D hijas
	for child in get_children():
		if child is CollisionShape3D:
			# El shape hereda el material del StaticBody
			pass
	
	physics_material_override = mat
