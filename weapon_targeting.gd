extends RefCounted

static func get_active_bricks(tree: SceneTree, excluded: Array[Node2D] = []) -> Array[Node2D]:
	var bricks: Array[Node2D] = []
	for node in tree.get_nodes_in_group("game_brick"):
		if not node is Node2D:
			continue
		var brick := node as Node2D
		if brick in excluded or not is_valid_brick(brick):
			continue
		bricks.append(brick)
	return bricks

static func sort_by_danger(bricks: Array[Node2D], paddle_position: Vector2) -> void:
	bricks.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		if not is_equal_approx(a.global_position.y, b.global_position.y):
			return a.global_position.y > b.global_position.y
		return absf(a.global_position.x - paddle_position.x) < absf(b.global_position.x - paddle_position.x))

static func select_danger_targets(tree: SceneTree, paddle_position: Vector2, count: int, excluded: Array[Node2D] = []) -> Array[Node2D]:
	var candidates := get_active_bricks(tree, excluded)
	sort_by_danger(candidates, paddle_position)
	return candidates.slice(0, mini(maxi(count, 0), candidates.size()))

static func is_valid_brick(brick: Node) -> bool:
	return is_instance_valid(brick) and not brick.is_queued_for_deletion() and brick.is_in_group("game_brick") and brick.get("is_destroyed") != true and brick.has_method("hit")
static func get_vertical_corridor_targets(
	tree: SceneTree,
	center_x: float,
	half_width: float,
	max_y: float = INF
) -> Array[Node2D]:
	var candidates: Array[Node2D] = []
	for brick in get_active_bricks(tree):
		if brick.global_position.y >= max_y:
			continue
		var brick_half_width := get_brick_half_width(brick)
		if absf(brick.global_position.x - center_x) <= half_width + brick_half_width:
			candidates.append(brick)
	candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.global_position.y > b.global_position.y)
	return candidates

static func get_brick_half_width(brick: Node2D) -> float:
	var collision := brick.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if is_instance_valid(collision) and collision.shape is RectangleShape2D:
		return (collision.shape as RectangleShape2D).size.x * 0.5 * absf(collision.global_scale.x)
	return 0.0
