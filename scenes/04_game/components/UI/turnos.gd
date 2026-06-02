extends Control

const AZUL = preload("uid://cia10v6ul850a")
const ROJA = preload("uid://wpqu8kkku4tv")

@onready var h_box1: HBoxContainer = $HBoxPlayer1
@onready var h_box2: HBoxContainer = $HBoxPlayer2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_ui_balls()
	GameManager.connect("spawn_bocha", update_UI)
	GameManager.connect("soft_reset_end", add_ui_balls)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func add_ui_balls() -> void:
	for i in GameManager.p1_turns:
		var bocha = AZUL.instantiate()
		h_box1.add_child(bocha)
	for i in GameManager.p2_turns:
		var bocha = ROJA.instantiate()
		h_box2.add_child(bocha)

func update_UI() -> void:
	var balls1 = h_box1.get_children()
	if balls1.size() == GameManager.p1_turns:
		pass
	else:
		if balls1.size() <= 0: pass
		else: balls1[-1].queue_free()
	var balls2 = h_box2.get_children()
	if balls2.size() == GameManager.p2_turns:
		pass
	else: 
		if balls2.size() <= 0: pass
		else: balls2[-1].queue_free()
