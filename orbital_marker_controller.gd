extends Node

const STRIKE_SCENE: PackedScene = preload("res://orbital_strike.tscn")
const TARGETING := preload("res://weapon_targeting.gd")
const LEVEL_CONFIG := {
	1: {"cooldown": 4.8, "telegraph": 0.86, "radius": 54.0, "max_targets": 2, "strike_count": 1},
	2: {"cooldown": 4.2, "telegraph": 0.78, "radius": 68.0, "max_targets": 3, "strike_count": 1},
	3: {"cooldown": 3.9, "telegraph": 0.72, "radius": 68.0, "max_targets": 3, "strike_count": 2},
}
const SECOND_STRIKE_DELAY := 0.18

var game: Node
var paddle: Node2D
var cooldown_left := 0.30
var queued_targets: Array[Node2D] = []
var queued_level := 0
var queued_config: Dictionary = {}
var strike_delay_left := 0.0
var active_strikes: Array[Node] = []
var runtime_active := false

func configure(game_node: Node, paddle_node: Node2D) -> void:
	game = game_node
	paddle = paddle_node

func _process(delta: float) -> void:
	_prune_strikes()
	if not is_instance_valid(game) or not is_instance_valid(paddle):
		_reset_runtime_state()
		return
	var level := GameManager.get_weapon_level(GameManager.WEAPON_ORBITAL_MARKER)
	if level <= 0 or game.get("game_over") == true:
		if runtime_active or not active_strikes.is_empty() or not queued_targets.is_empty():
			_reset_runtime_state()
		return
	runtime_active = true
	if game.get("choosing_card") == true:
		return
	if not queued_targets.is_empty():
		strike_delay_left = maxf(strike_delay_left - delta, 0.0)
		if strike_delay_left <= 0.0:
			_launch_queued_strike()
		return
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	if cooldown_left > 0.0:
		return
	var safe_level := clampi(level, 1, 3)
	var config: Dictionary = LEVEL_CONFIG[safe_level]
	var boss_hit := TARGETING.apply_boss_cycle_hit(get_tree(), &"orbital_marker", get_instance_id() ^ Time.get_ticks_msec())
	var targets := TARGETING.select_danger_targets(get_tree(), paddle.global_position, int(config["strike_count"]))
	if targets.is_empty():
		cooldown_left = float(config["cooldown"]) if boss_hit else 0.35
		return
	queued_targets = targets
	queued_level = safe_level
	queued_config = config
	cooldown_left = float(config["cooldown"])
	_launch_queued_strike()

func _launch_queued_strike() -> void:
	if queued_targets.is_empty() or not is_instance_valid(game):
		queued_targets.clear()
		return
	var target: Node2D = queued_targets.pop_front()
	if not TARGETING.is_valid_brick(target):
		if not queued_targets.is_empty():
			strike_delay_left = 0.0
			return
		queued_level = 0
		queued_config = {}
		return
	var strike := STRIKE_SCENE.instantiate()
	game.add_child(strike)
	strike.call("configure_strike", game, target, float(queued_config["telegraph"]), float(queued_config["radius"]), int(queued_config["max_targets"]), queued_level)
	active_strikes.append(strike)
	strike.tree_exiting.connect(_on_strike_tree_exiting.bind(strike), CONNECT_ONE_SHOT)
	strike_delay_left = SECOND_STRIKE_DELAY if not queued_targets.is_empty() else 0.0
	if queued_targets.is_empty():
		queued_level = 0
		queued_config = {}

func _on_strike_tree_exiting(strike: Node) -> void:
	active_strikes.erase(strike)

func _prune_strikes() -> void:
	for index in range(active_strikes.size() - 1, -1, -1):
		if not is_instance_valid(active_strikes[index]) or active_strikes[index].is_queued_for_deletion():
			active_strikes.remove_at(index)

func _clear_strikes() -> void:
	for strike in active_strikes.duplicate():
		if is_instance_valid(strike):
			if strike.has_method("retire"):
				strike.call("retire")
			else:
				strike.queue_free()
	active_strikes.clear()

func _reset_runtime_state() -> void:
	_clear_strikes()
	queued_targets.clear()
	queued_level = 0
	queued_config = {}
	strike_delay_left = 0.0
	cooldown_left = 0.30
	runtime_active = false
