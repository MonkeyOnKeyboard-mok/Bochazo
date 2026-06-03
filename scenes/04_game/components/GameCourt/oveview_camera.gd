extends Camera3D

var follow_speed: float = 0.5

var max_pos_x : float = 26.706

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if GameManager.bochin_thrown:
		follow_bochin(_delta)

func follow_bochin(delta: float)-> void:
	if global_position.x >= max_pos_x and GameManager.bochin.global_position.x >= max_pos_x: return
	global_position.x = lerp(global_position.x, GameManager.bochin.global_position.x, follow_speed * delta)
