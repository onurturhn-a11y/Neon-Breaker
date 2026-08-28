extends Node

const MINE_SCENE: PackedScene = preload("res://mine_launcher_mine.tscn")
const LEVEL_CONFIG := {
	1: {"cooldown": 4.0, "max_mines": 2, "detection_radius": 58.0, "explosion_radius": 82.0, "chain": false},
	2: {"cooldown": 3.6, "max_mines": 3, "detection_radius": 58.0, "explosion_radius": 98.4, "chain": false},
	3: {"cooldown": 3.3, "max_mines": 3, "detection_radius": 58.0, "explosion_radius": 98.4, "chain": true},
}
const DEPLOY_HEIGHT_RATIO := 0.52
const PADDLE_CLEARANCE := 140.0

var game: Node
var paddle: Node2D
var cooldown_left := 0.0
var active_mines: Array[Node] = []
var runtime_active := false


func configure(game_node: Node, paddle_node: Node2D) -> void:
	game = game_node
	paddle = paddle_node



func _process(delta: float) -> void:
	_prune_mines()
	if not is_instance_valid(game) or not is_instance_valid(paddle):
		_clear_active_mines()
		return
	var level := GameManager.get_weapon_level(GameManager.WEAPON_MINE_LAUNCHER)
	if level <= 0:
		if runtime_active or not active_mines.is_empty():
			_reset_runtime_state()
		return
	runtime_active = true
	if game.get("game_over") == true:
		_clear_active_mines()
		return
	if game.get("choosing_card") == true:
		return
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	if cooldown_left > 0.0:
		return
	var safe_level := clampi(level, 1, 3)
	var config: Dictionary = LEVEL_CONFIG[safe_level]
	cooldown_left = float(config["cooldown"])
	_deploy_mine(safe_level, config)


func _deploy_mine(level: int, config: Dictionary) -> Node:
	_prune_mines()
	var max_mines := int(config["max_mines"])
	if active_mines.size() >= max_mines:
		var oldest: Node = active_mines.pop_front()
		if is_instance_valid(oldest) and oldest.has_method("retire"):
			oldest.call("retire")
	var mine := MINE_SCENE.instantiate()
	game.add_child(mine)
	mine.global_position = paddle.global_position + Vector2.UP * 24.0
	var gameplay_rect := GameManager.get_gameplay_rect(game.get_viewport_rect().size)
	var target_y := gameplay_rect.position.y + gameplay_rect.size.y * DEPLOY_HEIGHT_RATIO
	target_y = minf(target_y, paddle.global_position.y - PADDLE_CLEARANCE)
	var target := Vector2(paddle.global_position.x, target_y)
	mine.call("configure_mine", game, level, target, config)
	active_mines.append(mine)
	mine.tree_exiting.connect(_on_mine_tree_exiting.bind(mine), CONNECT_ONE_SHOT)
	if OS.is_debug_build():
		print("MINE LV%d DEPLOY | ACTIVE %d/%d" % [level, active_mines.size(), max_mines])
	return mine


func _on_mine_tree_exiting(mine: Node) -> void:
	active_mines.erase(mine)


func _prune_mines() -> void:
	for index in range(active_mines.size() - 1, -1, -1):
		if not is_instance_valid(active_mines[index]) or active_mines[index].is_queued_for_deletion():
			active_mines.remove_at(index)


func _clear_active_mines() -> void:
	for mine in active_mines.duplicate():
		if is_instance_valid(mine):
			if mine.has_method("retire"):
				mine.call("retire")
			else:
				mine.queue_free()
	active_mines.clear()


func _reset_runtime_state() -> void:
	_clear_active_mines()
	cooldown_left = 0.0
	runtime_active = false
