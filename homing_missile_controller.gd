extends Node

const HOMING_MISSILE_SCENE: PackedScene = preload("res://homing_missile.tscn")
const TARGETING := preload("res://weapon_targeting.gd")
const LEVEL_CONFIG := {
	1: {"cooldown": 2.2, "missiles": 1, "turn_speed": 220.0, "micro_blast": false},
	2: {"cooldown": 2.1, "missiles": 2, "turn_speed": 264.0, "micro_blast": false},
	3: {"cooldown": 2.1, "missiles": 2, "turn_speed": 290.0, "micro_blast": true},
}
var game: Node
var paddle: Node2D
var cooldown_left := 0.0

func configure(game_node: Node, paddle_node: Node2D) -> void:
	game = game_node
	paddle = paddle_node

func _process(delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(paddle): return
	var level := GameManager.get_weapon_level(GameManager.WEAPON_HOMING_MISSILE)
	if level <= 0:
		cooldown_left = 0.0
		return
	if game.get("game_over") == true or game.get("choosing_card") == true: return
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	if cooldown_left > 0.0: return
	var config: Dictionary = LEVEL_CONFIG[clampi(level, 1, 3)]
	cooldown_left = float(config["cooldown"])
	_fire(level, config)

func _fire(level: int, config: Dictionary = {}) -> Array[Node]:
	var safe_level := clampi(level, 1, 3)
	if config.is_empty(): config = LEVEL_CONFIG[safe_level]
	var missile_count := int(config["missiles"])
	var targets := TARGETING.select_danger_targets(game.get_tree(), paddle.global_position, missile_count)
	var spawned: Array[Node] = []
	for index in range(missile_count):
		var target: Node2D = targets[index] if index < targets.size() else (targets[0] if not targets.is_empty() else null)
		var missile := HOMING_MISSILE_SCENE.instantiate()
		game.add_child(missile)
		var offset := 7.0 * (float(index) - float(missile_count - 1) * 0.5)
		missile.global_position = paddle.global_position + Vector2(offset, -22.0)
		missile.configure(game, target, deg_to_rad(float(config["turn_speed"])), bool(config["micro_blast"]))
		spawned.append(missile)
	if OS.is_debug_build():
		if safe_level == 1: print("HOMING LV1: 1 MISSILE")
		elif safe_level == 2: print("HOMING LV2: 2 MISSILES | TARGETS %d" % targets.size())
		else: print("HOMING LV3: 2 MISSILES | PRIORITY LOCK")
	return spawned
