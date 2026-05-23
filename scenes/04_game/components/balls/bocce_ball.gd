extends RigidBody3D
class_name BocceBall

signal stopped_moving(ball_ref: BocceBall)
signal collision_occurred(impulse: Vector3)

@export_group("Configuración")
@export var physics_config: PhysicsConfig
@export var stop_velocity_threshold: float = 0.1
@export var debug_verbose: bool = false

@onready var ball_collision: CollisionShape3D = $BallCollision

var rojo = load("res://assets/textures/texture_bocha_rosa.png")
var azul = load("res://assets/textures/texture_bocha_blue.png")

var _is_stopped: bool = false
var player : String = ""
var settings_set : bool = false

var distance_to_bochin 

func _ready():
	_apply_physics()
	body_entered.connect(_on_body_entered)
	_define_settings()

func _physics_process(_delta):
	calc_distance_to_bochin()
	if _is_stopped: return
	if linear_velocity.length() < stop_velocity_threshold:
		_is_stopped = true
		freeze = true
		stopped_moving.emit(self)
		print("me frene")
		GameManager.deduct_turn(player)
		if debug_verbose: print("[BocceBall] Se detuvo")
		freeze = false
		GameManager.bochas_thrown.append(self)
		if GameManager.first_turn == false and GameManager.bochin: return
		else: 
			GameManager.first_bocha(self.global_position.distance_to(GameManager.bochin.global_position))
			GameManager.first_turn = false

func calc_distance_to_bochin() -> void:
	distance_to_bochin = self.global_position.distance_to(GameManager.bochin.global_position)

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
		push_warning("[BocceBall] physics_config no asignado.")

func _on_body_entered(body: Node):
	collision_occurred.emit(linear_velocity)
	if debug_verbose and linear_velocity.length() > 0.5:
		print("[BocceBall] Colisión con %s" % body.name)
		
func _define_settings() -> void:
	if !$BochaMesh : return
	if settings_set : return
	var mat = $BochaMesh.material_override as StandardMaterial3D
	if mat:
		if GameManager.p1_turn:
			mat.albedo_texture = rojo
			player = "player1"
		else: 
			mat.albedo_texture = azul
			player = "player2"
	settings_set = true
