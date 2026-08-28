extends Node

const TELEGRAPH_DURATION := 0.24
const LEVEL_CONFIG := {
	1: {"cooldown": 3.0, "half_width": 8.0, "max_hits": 4},
	2: {"cooldown": 2.8, "half_width": 9.6, "max_hits": 7},
	3: {"cooldown": 2.6, "half_width": 10.5, "max_hits": 0},
}
const RAILGUN_VISUAL_SCRIPT := preload("res://railgun_visual.gd")

var game: Node
var paddle: Node2D
var cooldown_left := 0.0
var fire_in_progress := false


func configure(game_node: Node, paddle_node: Node2D) -> void:
	game = game_node
	paddle = paddle_node


func _process(delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(paddle):
		return
	var railgun_level := GameManager.get_weapon_level(GameManager.WEAPON_RAILGUN)
	if railgun_level <= 0:
		cooldown_left = 0.0
		fire_in_progress = false
		return
	if game.get("game_over") == true or game.get("choosing_card") == true or fire_in_progress:
		return
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	if cooldown_left > 0.0:
		return
	var config: Dictionary = LEVEL_CONFIG[clampi(railgun_level, 1, 3)]
	cooldown_left = float(config["cooldown"])
	_begin_fire(railgun_level)


func _begin_fire(level: int) -> void:
	fire_in_progress = true
	var rail_x := paddle.global_position.x
	var gameplay_rect := GameManager.get_gameplay_rect(game.get_viewport_rect().size)
	var start_position := Vector2(rail_x, paddle.global_position.y - 18.0)
	var end_position := Vector2(rail_x, gameplay_rect.position.y)
	_spawn_visual(start_position, end_position, true)
	await game.get_tree().create_timer(TELEGRAPH_DURATION).timeout
	if (
		is_instance_valid(game)
		and is_instance_valid(paddle)
		and GameManager.get_weapon_level(GameManager.WEAPON_RAILGUN) > 0
		and game.get("game_over") != true
		and game.get("choosing_card") != true
	):
		_fire(level, rail_x, start_position, end_position)
	fire_in_progress = false


func _fire(
	level: int,
	rail_x: float = NAN,
	start_position: Vector2 = Vector2.INF,
	end_position: Vector2 = Vector2.INF
) -> Array[Node2D]:
	var safe_level := clampi(level, 1, 3)
	var config: Dictionary = LEVEL_CONFIG[safe_level]
	if is_nan(rail_x):
		rail_x = paddle.global_position.x
	if not start_position.is_finite() or not end_position.is_finite():
		var gameplay_rect := GameManager.get_gameplay_rect(game.get_viewport_rect().size)
		start_position = Vector2(rail_x, paddle.global_position.y - 18.0)
		end_position = Vector2(rail_x, gameplay_rect.position.y)
	var candidates := _get_rail_candidates(rail_x, float(config["half_width"]))
	var max_hits := int(config["max_hits"])
	var hit_count := candidates.size() if max_hits <= 0 else mini(candidates.size(), max_hits)
	var hit_bricks: Array[Node2D] = []
	for index in range(hit_count):
		var brick := candidates[index]
		if not _is_valid_target(brick):
			continue
		hit_bricks.append(brick)
		brick.hit("railgun")
	_spawn_visual(start_position, end_position, false)
	if OS.is_debug_build():
		print("RAILGUN LV%d: HIT %d" % [safe_level, hit_bricks.size()])
	return hit_bricks


func _get_rail_candidates(rail_x: float, rail_half_width: float) -> Array[Node2D]:
	var candidates: Array[Node2D] = []
	for node in game.get_tree().get_nodes_in_group("game_brick"):
		if not node is Node2D:
			continue
		var brick := node as Node2D
		if not _is_valid_target(brick) or brick.global_position.y >= paddle.global_position.y:
			continue
		var hit_half_width := rail_half_width + _get_brick_half_width(brick)
		if absf(brick.global_position.x - rail_x) <= hit_half_width:
			candidates.append(brick)
	candidates.sort_custom(
		func(a: Node2D, b: Node2D) -> bool:
			return a.global_position.y > b.global_position.y
	)
	return candidates


func _get_brick_half_width(brick: Node2D) -> float:
	var collision := brick.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if is_instance_valid(collision) and collision.shape is RectangleShape2D:
		return (collision.shape as RectangleShape2D).size.x * 0.5 * absf(collision.global_scale.x)
	return 0.0


func _is_valid_target(brick: Node) -> bool:
	return is_instance_valid(brick) and brick.get("is_destroyed") != true and brick.has_method("hit")


func _spawn_visual(from_position: Vector2, to_position: Vector2, telegraph: bool) -> void:
	if not is_instance_valid(game):
		return
	var visual := Node2D.new()
	visual.set_script(RAILGUN_VISUAL_SCRIPT)
	game.add_child(visual)
	visual.setup(from_position, to_position, telegraph)