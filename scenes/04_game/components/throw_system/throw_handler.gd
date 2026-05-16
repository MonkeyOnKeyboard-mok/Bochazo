extends Node
class_name ThrowHandler

@export var tracker: GestureTracker
@export var power_bar: ProgressBar
@export var dir_module: GestureDirection
@export var spin_module: GestureSpin
@export var ball: RigidBody3D

@export_group("GameSense 3D")
@export var max_force: float = 50.0        # ⬆️ Aumentado para pruebas
@export var spin_strength: float = 10.0
@export var spin_hz: float = 8.0

var dir: Vector3 = Vector3.LEFT
var spin_profile: PackedFloat32Array = []
var is_applying_spin: bool = false
var spin_idx: int = 0
var spin_timer: float = 0.0

func _ready():
	if not tracker or not ball: 
		printerr("[Throw] ⚠️ Faltan referencias: tracker o ball")
		return
		
	tracker.gesture_ended.connect(_on_throw)
	if dir_module: dir_module.direction_calculated.connect(_on_dir)
	if spin_module: spin_module.spin_profile_calculated.connect(_on_spin)

func _on_dir(d: Vector2): 
	# Flick arriba (d.y < 0) → X+ | Flick derecha (d.x > 0) → Z+
	dir = Vector3(-d.y, 0.0, d.x).normalized()
	
	# 🧪 DEBUG RÁPIDO: Descomentá la línea de abajo 1 vez. 
	# Si la bola sale hacia ADELANTE, el problema es 100% matemático. 
	# Si sale hacia ATRÁS, tu escena tiene Scale X = -1 o la cámara mira a -X.
	#dir = Vector3(1.0, 0.0, 0.0) 

func _on_spin(s): 
	spin_profile = s

func _physics_process(delta):
	if not is_applying_spin or spin_profile.is_empty(): return
	spin_timer += delta
	if spin_timer >= 1.0 / spin_hz:
		spin_timer = 0.0
		if spin_idx < spin_profile.size():
			var lat = spin_profile[spin_idx] * spin_strength
			ball.apply_central_impulse(Vector3(-dir.z, 0.0, dir.x) * lat)
			spin_idx += 1
		else: is_applying_spin = false

func _on_throw(_pts):
	if not power_bar: return
	var raw = power_bar.value
	var power = clamp(raw / 100.0, 0.0, 1.0)
	
	print("[Throw] 🚀 Soltado. Barra: ", raw, " | Potencia: ", power)
	if power < 0.05: return
		
	var impulse = dir * power * max_force
	print("[Throw] 💥 Impulso: ", impulse)
	ball.apply_central_impulse(impulse)
	
	is_applying_spin = true
	spin_idx = 0
	spin_timer = 0.0
