extends Node2D

const SOURCE_ID: StringName = &"orbital_marker"
const SPLASH_SOURCE_ID: StringName = &"orbital_splash"
const TARGETING := preload("res://weapon_targeting.gd")
const IMPACT_DURATION := 0.30
const MARKER_SEGMENTS := 40

enum State { TELEGRAPH, IMPACT, RETIRED }

var game: Node
var target_ref: WeakRef
var locked_position := Vector2.ZERO
var telegraph_duration := 0.86
var strike_radius := 54.0
var max_targets := 2
var weapon_level := 1
var elapsed := 0.0
var state := State.TELEGRAPH
var damage_applied := false
var beam_origin_world_y := 0.0

func configure_strike(game_node: Node, target: Node2D, telegraph_time: float, radius: float, target_cap: int, level: int) -> void:
	game = game_node
	target_ref = weakref(target) if is_instance_valid(target) else null
	locked_position = target.global_position if is_instance_valid(target) else global_position
	global_position = locked_position
	telegraph_duration = maxf(telegraph_time, 0.10)
	strike_radius = maxf(radius, 1.0)
	max_targets = maxi(target_cap, 1)
	weapon_level = clampi(level, 1, 3)
	var gameplay_rect := GameManager.get_gameplay_rect(game.get_viewport_rect().size)
	beam_origin_world_y = gameplay_rect.position.y
	add_to_group("orbital_marker_strike")
	queue_redraw()

func _process(delta: float) -> void:
	if state == State.RETIRED:
		return
	if not is_instance_valid(game) or game.get("game_over") == true or GameManager.get_weapon_level(GameManager.WEAPON_ORBITAL_MARKER) <= 0:
		retire()
		return
	if game.get("choosing_card") == true:
		return
	if state == State.TELEGRAPH:
		var tracked_target := _get_primary_target()
		if TARGETING.is_valid_brick(tracked_target):
			locked_position = tracked_target.global_position
			global_position = locked_position
	elapsed += delta
	if state == State.TELEGRAPH and elapsed >= telegraph_duration:
		state = State.IMPACT
		elapsed = 0.0
		_apply_damage_once()
	elif state == State.IMPACT and elapsed >= IMPACT_DURATION:
		retire()
	queue_redraw()

func _draw() -> void:
	if state == State.TELEGRAPH:
		var progress := clampf(elapsed / telegraph_duration, 0.0, 1.0)
		var pulse := 0.55 + 0.45 * sin(elapsed * 11.0)
		var marker_radius := strike_radius * (0.48 - progress * 0.12)
		var marker_color := Color(0.55, 0.86, 1.0, 0.55 + pulse * 0.32)
		draw_arc(Vector2.ZERO, marker_radius, 0.0, TAU, MARKER_SEGMENTS, marker_color, 2.4, true)
		draw_arc(Vector2.ZERO, marker_radius * 0.62, -PI * 0.32, PI * 0.32, 18, Color(0.82, 0.96, 1.0, 0.70), 1.6, true)
		draw_line(Vector2(-marker_radius, 0), Vector2(-marker_radius * 0.45, 0), marker_color, 1.8, true)
		draw_line(Vector2(marker_radius * 0.45, 0), Vector2(marker_radius, 0), marker_color, 1.8, true)
		draw_line(Vector2(0, -marker_radius), Vector2(0, -marker_radius * 0.45), marker_color, 1.8, true)
		draw_circle(Vector2.ZERO, 2.5 + pulse * 1.5, Color(0.88, 0.98, 1.0, 0.65))
	else:
		var progress := clampf(elapsed / IMPACT_DURATION, 0.0, 1.0)
		var beam_alpha := 1.0 - progress
		draw_line(Vector2(0.0, beam_origin_world_y - global_position.y), Vector2.ZERO, Color(0.58, 0.90, 1.0, beam_alpha * 0.30), 18.0 - progress * 8.0, true)
		draw_line(Vector2(0.0, beam_origin_world_y - global_position.y), Vector2.ZERO, Color(0.90, 0.99, 1.0, beam_alpha), 5.0, true)
		draw_circle(Vector2.ZERO, strike_radius * progress, Color(0.28, 0.72, 1.0, (1.0 - progress) * 0.20))
		draw_arc(Vector2.ZERO, strike_radius * progress, 0.0, TAU, MARKER_SEGMENTS, Color(0.70, 0.94, 1.0, 1.0 - progress), 3.0, true)

func _apply_damage_once() -> int:
	if damage_applied:
		return 0
	damage_applied = true
	var hit_ids: Dictionary = {}
	var hit_count := 0
	var primary := _get_primary_target()
	if TARGETING.is_valid_brick(primary):
		primary.call("hit", SOURCE_ID)
		hit_ids[primary.get_instance_id()] = true
		hit_count += 1
	var candidates := TARGETING.get_active_bricks(get_tree())
	candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return locked_position.distance_squared_to(a.global_position) < locked_position.distance_squared_to(b.global_position))
	for brick in candidates:
		if hit_count >= max_targets:
			break
		if locked_position.distance_to(brick.global_position) > strike_radius:
			break
		var instance_id := brick.get_instance_id()
		if hit_ids.has(instance_id) or not TARGETING.is_valid_brick(brick):
			continue
		brick.call("hit", SPLASH_SOURCE_ID)
		hit_ids[instance_id] = true
		hit_count += 1
	return hit_count

func _get_primary_target() -> Node2D:
	if target_ref == null:
		return null
	return target_ref.get_ref() as Node2D

func retire() -> void:
	if state == State.RETIRED:
		return
	state = State.RETIRED
	queue_free()
