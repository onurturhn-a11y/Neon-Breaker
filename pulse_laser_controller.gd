extends Node

const TARGETING := preload("res://weapon_targeting.gd")
const VISUAL_SCRIPT := preload("res://pulse_laser_visual.gd")
const DAMAGE_TICK := 0.20
const LEVEL_CONFIG := {
	1: {"cooldown": 4.0, "duration": 0.8, "half_width": 5.0},
	2: {"cooldown": 3.7, "duration": 1.0, "half_width": 6.0},
	3: {"cooldown": 3.5, "duration": 1.2, "half_width": 7.0},
}
enum State { COOLDOWN, FIRING }

var game: Node
var paddle: Node2D
var state := State.COOLDOWN
var cooldown_left := 0.0
var firing_left := 0.0
var tick_left := 0.0
var active_level := 0
var tick_count := 0
var max_damage_ticks := 0
var overload_applied := false
var beam_visual: Node2D

func configure(game_node: Node, paddle_node: Node2D) -> void:
	game = game_node
	paddle = paddle_node

func _process(delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(paddle): return
	var level := GameManager.get_weapon_level(GameManager.WEAPON_PULSE_LASER)
	if level <= 0:
		_reset_runtime_state()
		return
	if game.get("game_over") == true or game.get("choosing_card") == true: return
	if state == State.COOLDOWN:
		cooldown_left = maxf(cooldown_left - delta, 0.0)
		if cooldown_left <= 0.0: _start_firing(level)
		return
	_update_visual()
	firing_left = maxf(firing_left - delta, 0.0)
	tick_left -= delta
	while tick_left <= 0.0 and firing_left > 0.0 and tick_count < max_damage_ticks:
		_apply_damage_tick()
		tick_left += DAMAGE_TICK
	if firing_left <= 0.0: _finish_firing()

func _start_firing(level: int) -> void:
	TARGETING.apply_boss_cycle_hit(get_tree(), &"pulse_laser", get_instance_id() ^ Time.get_ticks_msec())
	active_level = clampi(level, 1, 3)
	var config: Dictionary = LEVEL_CONFIG[active_level]
	state = State.FIRING
	firing_left = float(config["duration"])
	tick_left = 0.0
	tick_count = 0
	max_damage_ticks = ceili(firing_left / DAMAGE_TICK)
	overload_applied = false
	beam_visual = Node2D.new()
	beam_visual.set_script(VISUAL_SCRIPT)
	game.add_child(beam_visual)
	beam_visual.configure(float(config["half_width"]) * 2.0)
	_update_visual()
	if OS.is_debug_build(): print("PULSE LV%d START" % active_level)

func _apply_damage_tick() -> int:
	var targets := _get_current_corridor_targets()
	var hit_count := 0
	for brick in targets:
		if not TARGETING.is_valid_brick(brick): continue
		brick.hit("pulse_laser")
		hit_count += 1
	tick_count += 1
	return hit_count

func _finish_firing() -> void:
	var overload_hits := 0
	if active_level >= 3 and not overload_applied:
		overload_applied = true
		overload_hits = _apply_overload()
		if is_instance_valid(beam_visual): beam_visual.play_overload()
	if is_instance_valid(beam_visual): beam_visual.finish()
	beam_visual = null
	state = State.COOLDOWN
	cooldown_left = float(LEVEL_CONFIG[active_level]["cooldown"])
	if OS.is_debug_build():
		if active_level >= 3: print("PULSE LV3 END | OVERLOAD HIT %d" % overload_hits)
		else: print("PULSE LV%d END | TICKS %d" % [active_level, tick_count])

func _apply_overload() -> int:
	var hit_count := 0
	for brick in _get_current_corridor_targets():
		if not TARGETING.is_valid_brick(brick): continue
		brick.hit("pulse_overload")
		hit_count += 1
	return hit_count

func _get_current_corridor_targets() -> Array[Node2D]:
	var half_width := float(LEVEL_CONFIG[clampi(active_level, 1, 3)]["half_width"])
	return TARGETING.get_vertical_corridor_targets(get_tree(), paddle.global_position.x, half_width, paddle.global_position.y)

func _update_visual() -> void:
	if not is_instance_valid(beam_visual): return
	var rect := GameManager.get_gameplay_rect(game.get_viewport_rect().size)
	beam_visual.update_beam(Vector2(paddle.global_position.x, paddle.global_position.y - 18.0), Vector2(paddle.global_position.x, rect.position.y))

func _reset_runtime_state() -> void:
	state = State.COOLDOWN
	cooldown_left = 0.0
	firing_left = 0.0
	tick_left = 0.0
	active_level = 0
	tick_count = 0
	max_damage_ticks = ceili(firing_left / DAMAGE_TICK)
	overload_applied = false
	if is_instance_valid(beam_visual): beam_visual.queue_free()
	beam_visual = null
