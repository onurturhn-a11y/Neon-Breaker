extends Node

const MORTAR_SHELL_SCENE: PackedScene = preload("res://mortar_shell.tscn")
const TARGETING := preload("res://weapon_targeting.gd")
const LEVEL_CONFIG := {
	1: {"cooldown": 4.5, "shells": 1, "radius": 78.0, "density_radius": 125.0, "travel_time": 0.82},
	2: {"cooldown": 4.1, "shells": 1, "radius": 97.5, "density_radius": 145.0, "travel_time": 0.80},
	3: {"cooldown": 3.8, "shells": 2, "radius": 97.5, "density_radius": 145.0, "travel_time": 0.76},
}
const UPPER_FIELD_RATIO := 0.48
const MAX_DENSITY_CANDIDATES := 18
const DOUBLE_SALVO_DELAY := 0.25
const SECOND_TARGET_MIN_SEPARATION_RATIO := 0.75

var game: Node
var paddle: Node2D
var cooldown_left := 0.0
var pending_targets: Array[Vector2] = []
var pending_level := 0
var pending_config: Dictionary = {}
var salvo_delay_left := 0.0
var active_shells: Array[Node] = []
var runtime_active := false


func configure(game_node: Node, paddle_node: Node2D) -> void:
	game = game_node
	paddle = paddle_node


func _process(delta: float) -> void:
	_prune_shells()
	if not is_instance_valid(game) or not is_instance_valid(paddle):
		_reset_runtime_state()
		return
	var level := GameManager.get_weapon_level(GameManager.WEAPON_MORTAR)
	if level <= 0:
		if runtime_active or not active_shells.is_empty() or not pending_targets.is_empty():
			_reset_runtime_state()
		return
	runtime_active = true
	if game.get("game_over") == true:
		_reset_runtime_state()
		return
	if game.get("choosing_card") == true:
		return
	if not pending_targets.is_empty():
		salvo_delay_left = maxf(salvo_delay_left - delta, 0.0)
		if salvo_delay_left <= 0.0:
			_fire_pending_shell()
		return
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	if cooldown_left > 0.0:
		return
	var safe_level := clampi(level, 1, 3)
	var config: Dictionary = LEVEL_CONFIG[safe_level]
	var boss_hit := TARGETING.apply_boss_cycle_hit(get_tree(), &"mortar", get_instance_id() ^ Time.get_ticks_msec())
	var targets := _select_impact_positions(safe_level, config)
	if targets.is_empty():
		cooldown_left = float(config["cooldown"]) if boss_hit else 0.35
		return
	cooldown_left = float(config["cooldown"])
	pending_level = safe_level
	pending_config = config
	pending_targets = targets
	_fire_pending_shell()
	if safe_level == 3 and OS.is_debug_build():
		print("MORTAR LV3 | DOUBLE SALVO")


func _fire_pending_shell() -> void:
	if pending_targets.is_empty() or not is_instance_valid(game) or not is_instance_valid(paddle):
		pending_targets.clear()
		return
	var target: Vector2 = pending_targets.pop_front()
	var shell: Node2D = MORTAR_SHELL_SCENE.instantiate() as Node2D
	game.add_child(shell)
	shell.global_position = paddle.global_position + Vector2(0.0, -24.0)
	shell.call(
		"configure_shell",
		game,
		target,
		float(pending_config["travel_time"]),
		float(pending_config["radius"]),
		pending_level
	)
	active_shells.append(shell)
	shell.tree_exiting.connect(_on_shell_tree_exiting.bind(shell), CONNECT_ONE_SHOT)
	salvo_delay_left = DOUBLE_SALVO_DELAY if not pending_targets.is_empty() else 0.0
	if pending_targets.is_empty():
		pending_level = 0
		pending_config = {}


func _select_impact_positions(level: int, config: Dictionary) -> Array[Vector2]:
	var bricks: Array[Node2D] = TARGETING.get_active_bricks(game.get_tree())
	if bricks.is_empty():
		return []
	var gameplay_rect := GameManager.get_gameplay_rect(game.get_viewport_rect().size)
	var upper_limit := gameplay_rect.position.y + gameplay_rect.size.y * UPPER_FIELD_RATIO
	var upper_bricks: Array[Node2D] = []
	for brick in bricks:
		if brick.global_position.y <= upper_limit:
			upper_bricks.append(brick)
	var candidates := upper_bricks if not upper_bricks.is_empty() else bricks
	candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.global_position.y < b.global_position.y)
	if candidates.size() > MAX_DENSITY_CANDIDATES:
		candidates.resize(MAX_DENSITY_CANDIDATES)
	var density_radius := float(config["density_radius"])
	var scored := _score_candidates(candidates, bricks, density_radius, gameplay_rect)
	if scored.is_empty():
		return []
	var targets: Array[Vector2] = [scored[0]["position"]]
	if level >= 3:
		var min_separation := density_radius * SECOND_TARGET_MIN_SEPARATION_RATIO
		for entry: Dictionary in scored:
			var candidate_position: Vector2 = entry["position"]
			if candidate_position.distance_to(targets[0]) >= min_separation:
				targets.append(candidate_position)
				break
		if targets.size() == 1:
			var direction := -1.0 if targets[0].x > gameplay_rect.get_center().x else 1.0
			var offset_target := targets[0] + Vector2(direction * 42.0, 12.0)
			offset_target.x = clampf(offset_target.x, gameplay_rect.position.x + 24.0, gameplay_rect.end.x - 24.0)
			offset_target.y = clampf(offset_target.y, gameplay_rect.position.y + 24.0, upper_limit)
			targets.append(offset_target)
	if OS.is_debug_build():
		print("MORTAR LV%d | TARGET DENSITY %d" % [level, int(scored[0]["density"])])
	return targets


func _score_candidates(
	candidates: Array[Node2D],
	all_bricks: Array[Node2D],
	radius: float,
	gameplay_rect: Rect2
) -> Array[Dictionary]:
	var cell_size := radius
	var buckets: Dictionary = {}
	for brick in all_bricks:
		var cell := Vector2i(floori(brick.global_position.x / cell_size), floori(brick.global_position.y / cell_size))
		if not buckets.has(cell):
			buckets[cell] = []
		(buckets[cell] as Array).append(brick)
	var scored: Array[Dictionary] = []
	var radius_squared := radius * radius
	for candidate in candidates:
		var center_cell := Vector2i(floori(candidate.global_position.x / cell_size), floori(candidate.global_position.y / cell_size))
		var density := 0
		for y_offset in range(-1, 2):
			for x_offset in range(-1, 2):
				var nearby: Array = buckets.get(center_cell + Vector2i(x_offset, y_offset), [])
				for brick: Node2D in nearby:
					if brick.global_position.distance_squared_to(candidate.global_position) <= radius_squared:
						density += 1
		var top_bias := 1.0 - clampf(
			(candidate.global_position.y - gameplay_rect.position.y) / maxf(gameplay_rect.size.y, 1.0),
			0.0,
			1.0
		)
		scored.append({
			"position": candidate.global_position,
			"density": density,
			"score": float(density) + top_bias * 1.5,
		})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))
	return scored


func _on_shell_tree_exiting(shell: Node) -> void:
	active_shells.erase(shell)


func _prune_shells() -> void:
	for index in range(active_shells.size() - 1, -1, -1):
		if not is_instance_valid(active_shells[index]) or active_shells[index].is_queued_for_deletion():
			active_shells.remove_at(index)


func _clear_shells() -> void:
	for shell in active_shells.duplicate():
		if is_instance_valid(shell):
			shell.queue_free()
	active_shells.clear()


func _reset_runtime_state() -> void:
	_clear_shells()
	pending_targets.clear()
	pending_level = 0
	pending_config = {}
	salvo_delay_left = 0.0
	cooldown_left = 0.0
	runtime_active = false
