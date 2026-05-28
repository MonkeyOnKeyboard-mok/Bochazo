class_name AIContext
extends RefCounted

var court_type: int = 0
var bochin_dist_norm: float = 0.5
var bochin_angle: float = 0.0
var nearest_ally_dist: float = 5.0
var nearest_enemy_dist: float = 5.0
var offense_need: int = 0
var stats_potencia: float = 35.0
var stats_efecto: float = 0.5
var stats_precision: float = 0.95
var stats_control: float = 0.85

const FEATURES = ["court_type", "bochin_dist_norm", "bochin_angle", "nearest_ally_dist", "nearest_enemy_dist", "offense_need", "stats_potencia", "stats_efecto", "stats_precision", "stats_control"]

func feat(name: String) -> float:
	match name:
		"court_type": return float(court_type)
		"bochin_dist_norm": return bochin_dist_norm
		"bochin_angle": return bochin_angle
		"nearest_ally_dist": return nearest_ally_dist
		"nearest_enemy_dist": return nearest_enemy_dist
		"offense_need": return float(offense_need)
		"stats_potencia": return stats_potencia
		"stats_efecto": return stats_efecto
		"stats_precision": return stats_precision
		"stats_control": return stats_control
	return 0.0

static func gather(bochin_pos: Vector3, court_type_val: int, bochas: Array, stats: PlayerThrowStats, ball_pos: Vector3) -> AIContext:
	var c = AIContext.new()
	c.court_type = court_type_val
	c.stats_potencia = stats.potencia
	c.stats_efecto = stats.efecto
	c.stats_precision = stats.precision
	c.stats_control = stats.control
	var d = bochin_pos - ball_pos
	d.y = 0
	c.bochin_dist_norm = clampf(d.length() / 30.0, 0.0, 1.0)
	if d.length() > 0.1:
		c.bochin_angle = atan2(d.x, d.z) / PI
	var ad: Array[float] = []
	var ed: Array[float] = []
	for b in bochas:
		if not b or not is_instance_valid(b): continue
		var dist = b.global_position.distance_to(bochin_pos)
		if b.player == "player2": ed.append(dist)
		else: ad.append(dist)
	c.nearest_ally_dist = ad.min() if ad.size() > 0 else 100.0
	c.nearest_enemy_dist = ed.min() if ed.size() > 0 else 100.0
	c.offense_need = 0 if c.nearest_ally_dist < c.nearest_enemy_dist else (1 if c.nearest_ally_dist < c.nearest_enemy_dist + 2.0 else 2)
	return c
