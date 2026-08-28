extends Node

const FIRE_INTERVAL := 1.5
const LEVEL_CONFIG := {
	1: {"max_chain_jumps": 2, "chain_radius": 165.0, "terminal_radius": 0.0},
	2: {"max_chain_jumps": 3, "chain_radius": 198.0, "terminal_radius": 0.0},
	3: {"max_chain_jumps": 4, "chain_radius": 220.0, "terminal_radius": 72.0},
}

var game: Node
var paddle: Node2D
var chain_manager: Node
var cooldown_left := 0.0


func configure(game_node: Node, paddle_node: Node2D, lightning_manager: Node) -> void:
	game = game_node
	paddle = paddle_node
	chain_manager = lightning_manager


func _process(delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(paddle) or not is_instance_valid(chain_manager):
		return
	var arc_level := GameManager.get_weapon_level(GameManager.WEAPON_ARC_CANNON)
	if arc_level <= 0:
		cooldown_left = 0.0
		return
	if game.get("game_over") == true or game.get("choosing_card") == true:
		return
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	if cooldown_left > 0.0:
		return
	cooldown_left = FIRE_INTERVAL
	var active_bricks := _get_active_bricks()
	var primary := _select_primary_target(active_bricks)
	if primary == null:
		return
	var config: Dictionary = LEVEL_CONFIG.get(clampi(arc_level, 1, 3), LEVEL_CONFIG[1])
	chain_manager.trigger_arc(
		paddle.global_position,
		primary,
		int(config["max_chain_jumps"]),
		float(config["chain_radius"]),
		arc_level,
		float(config["terminal_radius"]),
		active_bricks
	)


func _get_active_bricks() -> Array[Node2D]:
	var active_bricks: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("game_brick"):
		if not node is Node2D:
			continue
		var brick := node as Node2D
		if not is_instance_valid(brick) or bool(brick.get("is_destroyed")) or not brick.has_method("hit"):
			continue
		active_bricks.append(brick)
	return active_bricks


func _select_primary_target(candidates: Array[Node2D]) -> Node2D:
	if candidates.is_empty():
		return null
	var paddle_position := paddle.global_position
	candidates.sort_custom(
		func(a: Node2D, b: Node2D) -> bool:
			var a_horizontal := absf(a.global_position.x - paddle_position.x)
			var b_horizontal := absf(b.global_position.x - paddle_position.x)
			if not is_equal_approx(a_horizontal, b_horizontal):
				return a_horizontal < b_horizontal
			return a.global_position.y > b.global_position.y
	)
	return candidates[0]