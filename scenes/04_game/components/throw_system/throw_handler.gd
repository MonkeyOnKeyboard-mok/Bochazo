extends Node
class_name ThrowHandler

@export var tracker: GestureTracker
@export var power_bar: ProgressBar
@export var dir_module: GestureDirection
@export var spin_module: GestureSpin
@export var ball: RigidBody3D

@export_group("GameSense 3D")

## Velocidad base del impulso inicial. Controla la distancia máxima del tiro recto.
@export var max_force: float = 75.0
## Intensidad de la curva lateral por frame. Más alto = giro más cerrado. Más bajo = efecto sutil tipo Magnus.
@export var steer_strength: float = 3.0
## Frecuencia (Hz) de aplicación del perfil de dibujo. Menor = curva suave/progresiva. Mayor = respuesta inmediata al trazo.
@export var spin_hz: float = 8.0
## Ángulo máximo (°) del cono de tiro. Limita la dispersión lateral para evitar que la bocha se escape de la pista.
@export var max_spread_deg: float = 5.0
## Umbral mínimo de desviación lateral para activar el spin. Filtra micro-temblores y gestos puramente verticales.
@export var min_curve_threshold: float = 0.08

var dir: Vector3 = Vector3(1.0, 0.0, 0.0) # ← Default seguro: X+ = adelante
var max_tangent: float
var spin_profile: PackedFloat32Array = []
var is_applying_spin: bool = false
var spin_idx: int = 0
var spin_timer: float = 0.0
var initial_speed: float = 0.0

func _ready():
	max_tangent = tan(deg_to_rad(max_spread_deg))
	if not tracker or not ball: return
	tracker.gesture_ended.connect(_on_throw)
	if dir_module: dir_module.direction_calculated.connect(_on_dir)
	if spin_module: spin_module.spin_profile_calculated.connect(_on_spin)

func _on_dir(d: Vector2): 
	var raw = Vector3(-d.y, 0.0, d.x)
	raw.x = max(raw.x, 0.01)
	var limit_z = raw.x * max_tangent
	raw.z = clamp(raw.z, -limit_z, limit_z)
	dir = raw.normalized()

func _on_spin(s): spin_profile = s

func _physics_process(delta):
	if not is_applying_spin or spin_profile.is_empty(): return

	spin_timer += delta
	if spin_timer >= 1.0 / spin_hz:
		spin_timer = 0.0
		if spin_idx < spin_profile.size():
			var curve = spin_profile[spin_idx] # -1.0 a 1.0
			var steer_angle = curve * steer_strength * delta

			var vel = ball.linear_velocity
			if vel.length() > 0.1:
				# 🔹 Rotar velocidad sin agregar energía
				ball.linear_velocity = vel.rotated(Vector3.UP, steer_angle)

			spin_idx += 1
		else:
			is_applying_spin = false

func _on_throw(_pts):
	if not power_bar: return
	var power = clamp(power_bar.value / 100.0, 0.0, 1.0)
	if power < 0.05: return

	ball.apply_central_impulse(dir * power * max_force)

	# 🔒 Solo aplica spin si el dibujo tiene curvatura REAL
	if not spin_profile.is_empty():
		var avg_dev = 0.0
		for v in spin_profile: avg_dev += abs(v)
		if (avg_dev / spin_profile.size()) > min_curve_threshold:
			is_applying_spin = true
			spin_idx = 0
			spin_timer = 0.0
		else:
			is_applying_spin = false
	else:
		is_applying_spin = false
