extends RigidBody3D
class_name BocceBall

signal stopped_moving(ball_ref: BocceBall)
signal collision_occurred(impulse: Vector3)

@export_group("Configuración")
@export var physics_config: PhysicsConfig
@export var stop_velocity_threshold: float = 0.1
@export var debug_verbose: bool = false

# Referencias a nodos ya configurados en el editor
@onready var ball_mesh: MeshInstance3D = $BallMesh
@onready var ball_collision: CollisionShape3D = $BallCollision

var _is_stopped: bool = false

func _ready():
	_apply_physics()
	body_entered.connect(_on_body_entered)

func _physics_process(_delta):
	if _is_stopped: return
	
	if linear_velocity.length() < stop_velocity_threshold:
		_is_stopped = true
		freeze = true
		stopped_moving.emit(self)
		if debug_verbose: print("[BocceBall] 🛑 Se detuvo")
		freeze = false

func _apply_physics():
	if physics_config:
		mass = physics_config.ball_mass
		linear_damp = physics_config.linear_damping
		angular_damp = physics_config.angular_damping
		
		var phys_mat = PhysicsMaterial.new()
		phys_mat.friction = physics_config.ball_friction
		phys_mat.bounce = physics_config.ball_bounce
		physics_material_override = phys_mat
	else:
		push_warning("[BocceBall] ⚠️ physics_config no asignado.")

func _on_body_entered(body: Node):
	collision_occurred.emit(linear_velocity)
	if debug_verbose and linear_velocity.length() > 0.5:
		print("[BocceBall] 💥 Colisión con %s" % body.name)
