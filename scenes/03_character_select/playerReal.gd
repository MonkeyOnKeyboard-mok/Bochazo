extends PlayerCharSelect

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	data = chars.pick_random()
	mesh_instance.mesh = data.mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = data.texture
	mesh_instance.material_override = mat

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
