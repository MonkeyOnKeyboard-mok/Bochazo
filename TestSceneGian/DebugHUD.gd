# DebugHUD.gd
# Muestra informacion de debug en pantalla: estado, velocidad, potencia, posicion
extends CanvasLayer

var labels: Array[Label] = []
var lbl_state: Label
var lbl_velocity: Label
var lbl_speed: Label
var lbl_position: Label
var lbl_power: Label
var lbl_curve: Label
var lbl_gesture: Label
var lbl_drag: Label

var bocha: Node3D
var throw_controller: Node
var physics_body: RigidBody3D

func _ready() -> void:
	_build_ui()

	# Buscar la bocha recorriendo recursivamente
	await get_tree().process_frame
	bocha = _find_node_by_name(get_tree().root, "Bocha")

	if bocha == null:
		push_error("DebugHUD: No se encontro el nodo Bocha")
		# Fallback: intentar por path directo
		if get_tree().root.has_node("TestGian/Bocha"):
			bocha = get_tree().root.get_node("TestGian/Bocha")
			print("[DebugHUD] Bocha encontrada por path directo")
		return

	print("[DebugHUD] Bocha encontrada: ", bocha.name, " (", bocha.get_path(), ")")

	throw_controller = bocha.get_node_or_null("ThrowController")
	physics_body = bocha.get_node_or_null("PhysicsBody")

	print("[DebugHUD] throw_controller: ", throw_controller)
	print("[DebugHUD] physics_body: ", physics_body)

	# Conectar senales
	if bocha.has_signal("state_changed"):
		bocha.state_changed.connect(_on_state_changed)
	if bocha.has_signal("bocha_thrown"):
		bocha.bocha_thrown.connect(_on_bocha_thrown)

func _find_node_by_name(parent: Node, name: String) -> Node:
	if parent.name == name:
		return parent
	for child in parent.get_children():
		var result = _find_node_by_name(child, name)
		if result != null:
			return result
	return null

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.offset_left = 20
	margin.offset_top = 20
	margin.offset_right = 450
	margin.offset_bottom = 350
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(vbox)

	var defaults = [
		"Estado: POSITIONING",
		"Velocidad: (0.00, 0.00, 0.00)",
		"Rapidez: 0.000 m/s",
		"Posicion: (0.00, 0.00, 0.00)",
		"Potencia: -",
		"Curva: -",
		"Fase gesto: IDLE",
		"Progreso arrastre: 0%",
	]

	for i in range(defaults.size()):
		var lbl = Label.new()
		lbl.text = defaults[i]
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(lbl)
		labels.append(lbl)

	lbl_state = labels[0]
	lbl_velocity = labels[1]
	lbl_speed = labels[2]
	lbl_position = labels[3]
	lbl_power = labels[4]
	lbl_curve = labels[5]
	lbl_gesture = labels[6]
	lbl_drag = labels[7]

func _process(_delta: float) -> void:
	if physics_body == null:
		return

	var vel = physics_body.linear_velocity
	var speed = vel.length()

	lbl_velocity.text = "Velocidad: (%.2f, %.2f, %.2f)" % [vel.x, vel.y, vel.z]
	lbl_speed.text = "Rapidez: %.3f m/s" % speed
	lbl_position.text = "Posicion: (%.2f, %.2f, %.2f)" % [physics_body.position.x, physics_body.position.y, physics_body.position.z]

	if throw_controller != null:
		var progress = throw_controller.get_drag_progress()
		lbl_drag.text = "Progreso arrastre: %.0f%%" % (progress * 100.0)

	# Mostrar fase actual del gesto
	if throw_controller != null:
		var phase_names = ["IDLE", "PULL_BACK", "PUSH_FORWARD", "RELEASED"]
		lbl_gesture.text = "Fase gesto: %s" % phase_names[throw_controller.gesture_phase]

		if throw_controller.gesture_phase == throw_controller.GesturePhase.RELEASED:
			var data = throw_controller.get_throw_data()
			lbl_power.text = "Potencia lanzamiento: %.2f / 15.0" % data.power
			lbl_curve.text = "Curva: %.2f" % data.curve
		elif throw_controller.gesture_phase == throw_controller.GesturePhase.PUSH_FORWARD:
			lbl_power.text = "Potencia: cargando (%.2fm)" % throw_controller.push_distance
			lbl_curve.text = "Curva: calculando..."
		elif throw_controller.gesture_phase == throw_controller.GesturePhase.PULL_BACK:
			lbl_power.text = "Potencia: tomando carrera..."
			lbl_curve.text = "Curva: -"
		else:
			lbl_power.text = "Potencia: -"
			lbl_curve.text = "Curva: -"

func _on_state_changed(new_state: String) -> void:
	lbl_state.text = "Estado: %s" % new_state

func _on_bocha_thrown(power: float, direction: Vector3) -> void:
	lbl_power.text = "ULTIMO LANZAMIENTO - Potencia: %.2f | Dir: (%.1f, %.1f, %.1f)" % [power, direction.x, direction.y, direction.z]
