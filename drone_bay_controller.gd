extends Node

const DRONE_SCENE: PackedScene = preload("res://drone_bay_drone.tscn")
const TARGETING := preload("res://weapon_targeting.gd")
const LEVEL_CONFIG := {
	1: {"drone_count": 1, "fire_interval": 1.35, "projectile_speed": 540.0, "overload_every": 0},
	2: {"drone_count": 2, "fire_interval": 1.25, "projectile_speed": 560.0, "overload_every": 0},
	3: {"drone_count": 2, "fire_interval": 0.92, "projectile_speed": 590.0, "overload_every": 3},
}
var game: Node
var paddle: Node2D
var active_drones: Array[Node] = []
var applied_level := 0
var boss_hit_cooldown := 0.0

func configure(game_node: Node, paddle_node: Node2D) -> void:
	game = game_node
	paddle = paddle_node

func _process(delta: float) -> void:
	_prune_drones()
	if not is_instance_valid(game) or not is_instance_valid(paddle):
		_clear_drones()
		return
	var level := GameManager.get_weapon_level(GameManager.WEAPON_DRONE_BAY)
	if level <= 0 or game.get("game_over") == true:
		if applied_level > 0 or not active_drones.is_empty():
			_reset_runtime_state()
		return
	var safe_level := clampi(level, 1, 3)
	if safe_level != applied_level or active_drones.size() != int(LEVEL_CONFIG[safe_level]["drone_count"]):
		_apply_level(safe_level)
	boss_hit_cooldown = maxf(boss_hit_cooldown - delta, 0.0)
	if boss_hit_cooldown <= 0.0 and game.get("choosing_card") != true:
		if TARGETING.apply_boss_cycle_hit(get_tree(), &"drone_bay", get_instance_id() ^ Time.get_ticks_msec()):
			boss_hit_cooldown = float(LEVEL_CONFIG[safe_level]["fire_interval"])

func _apply_level(level: int) -> void:
	var config: Dictionary = LEVEL_CONFIG[level]
	var desired_count := int(config["drone_count"])
	while active_drones.size() < desired_count:
		var drone := DRONE_SCENE.instantiate()
		game.add_child(drone)
		drone.global_position = paddle.global_position + Vector2(0.0, -30.0)
		active_drones.append(drone)
		drone.tree_exiting.connect(_on_drone_tree_exiting.bind(drone), CONNECT_ONE_SHOT)
	while active_drones.size() > desired_count:
		var retired: Node = active_drones.pop_back()
		if is_instance_valid(retired):
			retired.queue_free()
	for index in active_drones.size():
		active_drones[index].call("configure_drone", game, paddle, index, desired_count, level, config)
	applied_level = level

func _on_drone_tree_exiting(drone: Node) -> void:
	active_drones.erase(drone)

func _prune_drones() -> void:
	for index in range(active_drones.size() - 1, -1, -1):
		if not is_instance_valid(active_drones[index]) or active_drones[index].is_queued_for_deletion():
			active_drones.remove_at(index)

func _clear_drones() -> void:
	for drone in active_drones.duplicate():
		if is_instance_valid(drone):
			drone.queue_free()
	active_drones.clear()

func _reset_runtime_state() -> void:
	_clear_drones()
	applied_level = 0
	boss_hit_cooldown = 0.0
