extends Node


@export_range(320.0, 520.0, 5.0) var projectile_speed = 365.0
@export_range(5.0, 7.0, 0.1) var initial_delay_min = 5.0
@export_range(5.0, 7.0, 0.1) var initial_delay_max = 7.0

const ATTACKER_SCENE = preload("res://side_attacker.tscn")
const MOBILE_INTERVAL_MULTIPLIER := 0.89

var time_until_spawn = 6.0
var active_attacker: Node
var current_interval_multiplier := 1.0
@onready var game = get_parent()


func _ready() -> void:
	current_interval_multiplier = _get_interval_multiplier(GameManager.run_depth)
	time_until_spawn = randf_range(initial_delay_min, initial_delay_max) * current_interval_multiplier


func _process(delta: float) -> void:
	if game.game_over or game.choosing_card or game.main_menu.visible or game.boss_active or game.boss_pending:
		return
	if is_instance_valid(active_attacker):
		return
	time_until_spawn -= delta
	if time_until_spawn <= 0.0:
		spawn_attacker()


func spawn_attacker() -> void:
	active_attacker = ATTACKER_SCENE.instantiate()
	game.add_child(active_attacker)
	active_attacker.finished.connect(_on_attacker_finished)
	active_attacker.setup(game, -1 if randf() < 0.5 else 1, projectile_speed)


func _on_attacker_finished() -> void:
	active_attacker = null
	var interval := get_interval_for_depth(GameManager.run_depth)
	time_until_spawn = randf_range(interval.x, interval.y)


func get_interval_for_depth(depth: int) -> Vector2:
	var base_interval: Vector2
	if depth <= 2:
		base_interval = Vector2(10.0, 14.0)
	elif depth <= 5:
		base_interval = Vector2(8.0, 12.0)
	else:
		base_interval = Vector2(6.0, 10.0)
	return base_interval * _get_interval_multiplier(depth)


func refresh_build_modifier() -> void:
	var next_multiplier := _get_interval_multiplier(GameManager.run_depth)
	if is_equal_approx(next_multiplier, current_interval_multiplier):
		return
	if time_until_spawn > 0.0 and current_interval_multiplier > 0.0:
		time_until_spawn *= next_multiplier / current_interval_multiplier
	current_interval_multiplier = next_multiplier


func _get_interval_multiplier(depth: int) -> float:
	var threat_multiplier := 0.85 if GameManager.get_build_threat() == 3 else 1.0
	var mobile_multiplier := MOBILE_INTERVAL_MULTIPLIER if OS.has_feature("mobile") else 1.0
	return (
		threat_multiplier
		* GameManager.get_late_game_side_attacker_multiplier(depth)
		* mobile_multiplier
	)
