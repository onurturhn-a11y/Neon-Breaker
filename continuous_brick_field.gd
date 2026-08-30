extends Node2D


@export var initial_row_count = 3
@export var rows_per_depth = 8
@export var danger_line_y = 520.0
@export var brick_danger_gap := 80.0
@export var danger_damage_cooldown = 0.85
@export var row_step_interval = 1.50
@export var desktop_initial_row_step_interval := 2.05
@export var minimum_safe_step_interval = 0.45
@export var row_step_distance = 10.0
@export var row_step_tween_duration = 0.21
@export_range(0.75, 1.0, 0.01) var mobile_descent_multiplier := 0.82
@export var explosive_radius = 135.0
@export var explosive_chain_delay = 0.075
@export_range(0.0, 1.0, 0.01) var side_wave_occupancy_threshold := 0.25
@export var side_wave_cooldown := 7.0
@export var side_wave_entry_duration_min := 0.5
@export var side_wave_entry_duration_max := 0.8
@export var boss_side_wave_interval_min := 8.0
@export var boss_side_wave_interval_max := 12.0

var top_row_y = GameManager.PLAYFIELD_TOP + 22.0
const EXPLOSION_SFX = preload("res://assets/audio/sfx/bricks/explosive_brick.mp3")
const EXPLOSION_SFX_VOICE_COUNT = 2
const EXPLOSION_SFX_RETRIGGER_MSEC = 60

var level_generator = preload("res://level_generator.gd").new()
var step_timer = 0.0
var distance_since_row = 0.0
var step_tween: Tween
var rows_spawned_since_depth = 0
var danger_cooldown_left = 0.0
var debug_hud_timer = 0.0
var game: Node
var explosion_sfx_players: Array[AudioStreamPlayer] = []
var last_explosion_sfx_msec := -1000
var boss_paused := false
var boss_board_drain_pending := false
var interval_before_power_synergy: float = 1.50
var last_power_synergy_tier := -1
const SYNERGY_PRESSURE_HALF_DISTANCE := 220.0
const SYNERGY_PRESSURE_STOP_DISTANCE := 120.0
const NORMAL_SIDE_WAVE_BRICK_COUNT := 4
const CENTER_ZONE_HEIGHT_RATIO := 0.40
const CENTER_ZONE_LOW_BRICK_COUNT := 1
const CENTER_REFILL_SAFETY_DELAY := 1.25
const SIDE_WAVE_MIN_BRICKS := 2
const SIDE_WAVE_MAX_BRICKS := 4
const SIDE_WAVE_INITIAL_DELAY := 3.5
const SIDE_WAVE_ATTEMPT_INTERVAL := 0.5
const SIDE_WAVE_DANGER_DISTANCE := 120.0
const BOSS_EVENT_SEPARATION := 1.0
var side_wave_cooldown_left := SIDE_WAVE_INITIAL_DELAY
var side_wave_attempt_left := 0.0
var side_wave_in_progress := false
var side_wave_tween: Tween
var normal_side_wave_bricks: Array[Node2D] = []
var center_refill_safety_left := 0.0
var boss_side_wave_active := false
var boss_side_wave_timer := 0.0
var boss_side_wave_attempt_left := 0.0
var boss_projectile_separation_left := 0.0


func _ready() -> void:
	for voice_index in range(EXPLOSION_SFX_VOICE_COUNT):
		var player := AudioStreamPlayer.new()
		player.name = "ExplosionSFX%d" % (voice_index + 1)
		player.stream = EXPLOSION_SFX
		player.volume_db = -7.0
		player.bus = &"SFX"
		add_child(player)
		explosion_sfx_players.append(player)


func initialize(game_node):

	game = game_node
	var portrait_mobile := OS.has_feature("mobile")
	var layout_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	level_generator.configure_for_viewport(layout_rect, portrait_mobile)
	top_row_y = GameManager.PLAYFIELD_TOP + 22.0
	_refresh_danger_line_from_paddle()
	apply_depth_settings()

	var created = 0
	for row_index in range(initial_row_count):
		var row_created = level_generator.create_continuous_row(
			self,
			top_row_y + row_index * level_generator.gap_y,
			row_index
		)
		created += row_created
		print_difficulty_debug(row_created)

	game.register_spawned_bricks(created)


func refresh_desktop_layout() -> void:
	if OS.has_feature("mobile"):
		return
	var layout_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	level_generator.configure_for_viewport(layout_rect, false)

func refresh_safe_area_layout() -> void:
	if not OS.has_feature("mobile"):
		return
	var layout_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	var old_start_x: float = level_generator.start_x
	var old_top_row_y: float = top_row_y
	level_generator.configure_for_viewport(layout_rect, true)
	top_row_y = GameManager.PLAYFIELD_TOP + 22.0
	_refresh_danger_line_from_paddle()
	var layout_shift := Vector2(
		level_generator.start_x - old_start_x,
		top_row_y - old_top_row_y
	)
	if not layout_shift.is_zero_approx():
		for brick: Node2D in get_tree().get_nodes_in_group("game_brick"):
			if is_instance_valid(brick) and is_ancestor_of(brick):
				brick.position += layout_shift


func _process(delta):

	if not is_instance_valid(game) or game.game_over:
		return
	_refresh_danger_line_from_paddle()
	if boss_paused:
		_update_boss_side_wave(delta)
		return

	_refresh_mobile_power_synergy_pressure()
	_update_side_wave(delta)
	danger_cooldown_left = maxf(danger_cooldown_left - delta, 0.0)
	var active_interval := _get_active_step_interval()
	step_timer += delta
	debug_hud_timer -= delta
	if debug_hud_timer <= 0.0:
		debug_hud_timer = 0.05
		game.update_depth_debug_label(
			active_interval,
			maxf(active_interval - step_timer, 0.0)
		)

	if step_timer >= active_interval and not is_step_tween_running():
		step_timer -= active_interval
		start_row_step()

	check_danger_line()


func _update_boss_side_wave(delta: float) -> void:
	if not boss_side_wave_active:
		return
	boss_side_wave_timer = maxf(boss_side_wave_timer - delta, 0.0)
	boss_side_wave_attempt_left = maxf(boss_side_wave_attempt_left - delta, 0.0)
	boss_projectile_separation_left = maxf(boss_projectile_separation_left - delta, 0.0)
	if not _is_boss_side_wave_blocked():
		var active_interval := _get_active_step_interval()
		step_timer += delta
		if step_timer >= active_interval and not is_step_tween_running():
			step_timer -= active_interval
			start_row_step()
		check_danger_line()
	if (
		boss_side_wave_timer > 0.0
		or boss_side_wave_attempt_left > 0.0
		or boss_projectile_separation_left > 0.0
		or side_wave_in_progress
		or _is_boss_side_wave_blocked()
	):
		return
	boss_side_wave_attempt_left = SIDE_WAVE_ATTEMPT_INTERVAL
	_try_spawn_side_wave(_get_board_occupancy(), true)


func _is_boss_side_wave_blocked() -> bool:
	if get_tree().paused or not is_instance_valid(game):
		return true
	if (
		bool(game.get("game_over"))
		or bool(game.get("choosing_card"))
		or bool(game.get("evolution_selection_active"))
		or not bool(game.get("boss_active"))
	):
		return true
	return _is_board_near_danger_line()


func _update_side_wave(delta: float) -> void:
	_update_normal_side_wave_lifecycle(delta)
	side_wave_cooldown_left = maxf(side_wave_cooldown_left - delta, 0.0)
	side_wave_attempt_left = maxf(side_wave_attempt_left - delta, 0.0)
	if side_wave_attempt_left > 0.0:
		return
	side_wave_attempt_left = SIDE_WAVE_ATTEMPT_INTERVAL
	if side_wave_in_progress or _is_side_wave_blocked():
		return
	var center_sparse := _get_center_zone_brick_count() <= CENTER_ZONE_LOW_BRICK_COUNT
	if center_sparse:
		if center_refill_safety_left > 0.0 or not normal_side_wave_bricks.is_empty():
			return
	else:
		if side_wave_cooldown_left > 0.0:
			return
		if _get_board_occupancy() >= side_wave_occupancy_threshold:
			return
	_try_spawn_side_wave(_get_board_occupancy(), false, center_sparse)


func _update_normal_side_wave_lifecycle(delta: float) -> void:
	center_refill_safety_left = maxf(center_refill_safety_left - delta, 0.0)
	if normal_side_wave_bricks.is_empty():
		return
	var still_active: Array[Node2D] = []
	for brick: Node2D in normal_side_wave_bricks:
		if is_instance_valid(brick) and brick.get("is_destroyed") != true:
			still_active.append(brick)
	if still_active.is_empty():
		center_refill_safety_left = CENTER_REFILL_SAFETY_DELAY
	normal_side_wave_bricks = still_active


func _is_side_wave_blocked() -> bool:
	if get_tree().paused or boss_paused or not is_instance_valid(game):
		return true
	if (
		bool(game.get("game_over"))
		or bool(game.get("choosing_card"))
		or bool(game.get("evolution_selection_active"))
		or bool(game.get("boss_pending"))
		or bool(game.get("boss_active"))
		or bool(game.get("boss_warning_running"))
		or bool(game.get("sector_transition_playing"))
	):
		return true
	var menu := game.get_node_or_null("MainMenu") as CanvasLayer
	if is_instance_valid(menu) and menu.visible:
		return true
	return _is_board_near_danger_line()


func _get_active_field_bricks() -> Array[Node2D]:
	var active: Array[Node2D] = []
	for brick_node: Node in get_tree().get_nodes_in_group("game_brick"):
		var brick := brick_node as Node2D
		if not is_instance_valid(brick) or not is_ancestor_of(brick):
			continue
		if brick.get("is_destroyed") == true:
			continue
		active.append(brick)
	return active


func _get_board_occupancy() -> float:
	var capacity := maxi(level_generator.grid_columns * level_generator.GRID_ROWS, 1)
	return float(_get_active_field_bricks().size()) / float(capacity)


func _get_playable_area_rect() -> Rect2:
	var layout_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	var playable_top := maxf(GameManager.PLAYFIELD_TOP, layout_rect.position.y)
	var playable_bottom := minf(danger_line_y, layout_rect.end.y)
	return Rect2(
		Vector2(layout_rect.position.x, playable_top),
		Vector2(layout_rect.size.x, maxf(playable_bottom - playable_top, level_generator.gap_y))
	)


func _get_center_zone_brick_count() -> int:
	var playable_rect := _get_playable_area_rect()
	var zone_height := playable_rect.size.y * CENTER_ZONE_HEIGHT_RATIO
	var center_y := playable_rect.get_center().y
	var zone_top := center_y - zone_height * 0.5
	var zone_bottom := center_y + zone_height * 0.5
	var count := 0
	for brick: Node2D in _get_active_field_bricks():
		if brick.global_position.y >= zone_top and brick.global_position.y <= zone_bottom:
			count += 1
	return count


func _is_board_near_danger_line() -> bool:
	for brick: Node2D in _get_active_field_bricks():
		if danger_line_y - get_brick_bottom(brick) <= SIDE_WAVE_DANGER_DISTANCE:
			return true
	return false


func _try_spawn_side_wave(occupancy: float, boss_wave: bool = false, center_refill: bool = false) -> bool:
	if not boss_wave and is_instance_valid(game) and (
		bool(game.get("boss_pending"))
		or bool(game.get("boss_active"))
		or bool(game.get("boss_warning_running"))
	):
		return false
	var wave_size := randi_range(SIDE_WAVE_MIN_BRICKS, SIDE_WAVE_MAX_BRICKS) if boss_wave else NORMAL_SIDE_WAVE_BRICK_COUNT
	var target_data := _find_side_wave_targets(wave_size, not boss_wave)
	if target_data.is_empty():
		return false
	var targets: Array[Vector2] = target_data["targets"]
	var columns: Array[int] = target_data["columns"]
	var from_left := randf() < 0.5
	var layout_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	var spawn_positions: Array[Vector2] = []
	for index in range(wave_size):
		var spawn_global_x: float = (
			layout_rect.position.x - level_generator.gap_x * float(wave_size - index)
			if from_left
			else layout_rect.end.x + level_generator.gap_x * float(index + 1)
		)
		spawn_positions.append(to_local(Vector2(spawn_global_x, targets[index].y)))

	var local_targets: Array[Vector2] = []
	for target in targets:
		local_targets.append(to_local(target))
	var wave_bricks: Array[Node2D] = level_generator.create_side_wave_group(
		self,
		spawn_positions,
		columns
	)
	if wave_bricks.is_empty():
		return false

	if not boss_wave:
		for brick: Node2D in wave_bricks:
			brick.set_meta("is_side_wave_brick", true)
		normal_side_wave_bricks = wave_bricks.duplicate()
	game.register_spawned_bricks(wave_bricks.size())
	side_wave_in_progress = true
	if boss_wave:
		boss_side_wave_timer = randf_range(boss_side_wave_interval_min, boss_side_wave_interval_max)
		if game.has_method("notify_boss_side_wave_spawned"):
			game.notify_boss_side_wave_spawned(BOSS_EVENT_SEPARATION)
	else:
		side_wave_cooldown_left = side_wave_cooldown
	var entry_duration := randf_range(side_wave_entry_duration_min, side_wave_entry_duration_max)
	side_wave_tween = create_tween().set_parallel(true)
	side_wave_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for index in range(wave_bricks.size()):
		side_wave_tween.tween_property(
			wave_bricks[index],
			"position",
			local_targets[index],
			entry_duration
		)
	side_wave_tween.finished.connect(_on_side_wave_entry_finished)
	if OS.is_debug_build():
		print(
			"SIDE WAVE: %s | bricks=%d | occupancy=%.2f"
			% ["LEFT" if from_left else "RIGHT", wave_bricks.size(), occupancy]
		)
	return true


func _find_side_wave_targets(wave_size: int, center_aligned: bool = false) -> Dictionary:
	if wave_size > level_generator.grid_columns:
		return {}
	var layout_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	var playable_rect := _get_playable_area_rect()
	var minimum_y := maxf(
		GameManager.PLAYFIELD_TOP + level_generator.gap_y * 2.0,
		layout_rect.position.y + layout_rect.size.y * 0.28
	)
	var maximum_y := minf(
		danger_line_y - SIDE_WAVE_DANGER_DISTANCE - level_generator.gap_y,
		layout_rect.position.y + layout_rect.size.y * 0.48
	)
	if maximum_y < minimum_y:
		return {}
	var active_bricks := _get_active_field_bricks()
	for _attempt in range(12):
		var row_y := playable_rect.get_center().y if center_aligned else randf_range(minimum_y, maximum_y)
		row_y = snappedf(row_y - top_row_y, level_generator.gap_y) + top_row_y
		var first_column := randi_range(0, level_generator.grid_columns - wave_size)
		var targets: Array[Vector2] = []
		var columns: Array[int] = []
		var safe := true
		for offset in range(wave_size):
			var column := first_column + offset
			var target := Vector2(level_generator.start_x + column * level_generator.gap_x, row_y)
			for brick: Node2D in active_bricks:
				if (
					absf(brick.global_position.x - target.x) < level_generator.gap_x * 0.72
					and absf(brick.global_position.y - target.y) < level_generator.gap_y * 0.72
				):
					safe = false
					break
			if not safe:
				break
			targets.append(target)
			columns.append(column)
		if safe:
			return {"targets": targets, "columns": columns}
	return {}


func _on_side_wave_entry_finished() -> void:
	side_wave_in_progress = false
	side_wave_tween = null


func _get_active_step_interval() -> float:
	return row_step_interval


## Etkin iniş tabanı. `minimum_safe_step_interval` tasarımcının ayarladığı
## temel değer; ascension katmanları bunu aşağı çeker.
##
## Neden (Faz 5.3 ölçümü): sabit tabanla ağır senaryoda taban derinlik 9'da
## bağlıyordu ve sonrasında sektör/lanet/ascension farkı oyuncuya hiç
## ulaşmıyordu. Ascension 10 ile ascension 0 aynı hızda iniyordu.
func _get_effective_min_step_interval() -> float:
	return GameManager.get_ascension_min_step_interval(minimum_safe_step_interval)


func start_row_step():

	step_tween = create_tween()
	step_tween.set_trans(Tween.TRANS_SINE)
	step_tween.set_ease(Tween.EASE_IN_OUT)
	step_tween.tween_property(
		self,
		"position:y",
		position.y + row_step_distance,
		row_step_tween_duration
	)
	step_tween.finished.connect(finish_row_step)


func finish_row_step():

	distance_since_row += row_step_distance

	while distance_since_row >= level_generator.gap_y:
		distance_since_row -= level_generator.gap_y
		if not boss_paused and not boss_board_drain_pending:
			spawn_next_row()


func is_step_tween_running():

	return step_tween != null and step_tween.is_valid() and step_tween.is_running()


func begin_boss_board_drain() -> void:
	boss_board_drain_pending = true
	side_wave_attempt_left = 0.0
	side_wave_cooldown_left = side_wave_cooldown


func pause_for_boss() -> void:
	boss_paused = true
	stop_boss_side_waves()
	if is_instance_valid(step_tween) and step_tween.is_valid():
		step_tween.kill()
	step_tween = null


func lock_for_boss_transition() -> void:
	pause_for_boss()
	step_timer = 0.0
	side_wave_attempt_left = 0.0
	side_wave_cooldown_left = side_wave_cooldown
	if is_instance_valid(side_wave_tween) and side_wave_tween.is_valid():
		side_wave_tween.kill()
	side_wave_tween = null
	side_wave_in_progress = false


func clear_bricks_for_boss(fade_duration: float = 0.28) -> void:
	var field_bricks: Array[Node] = []
	for brick: Node in get_tree().get_nodes_in_group("game_brick"):
		if not is_instance_valid(brick) or not is_ancestor_of(brick):
			continue
		field_bricks.append(brick)
		brick.remove_from_group("game_brick")
		brick.remove_from_group("explosive_brick")
		brick.remove_from_group("shield_brick")
		var shape := brick.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if is_instance_valid(shape):
			shape.set_deferred("disabled", true)
		var fade := brick.create_tween()
		fade.tween_property(brick, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	game.bricks_left = maxi(game.bricks_left - field_bricks.size(), 0)
	await get_tree().create_timer(fade_duration).timeout
	for brick: Node in field_bricks:
		if is_instance_valid(brick):
			brick.queue_free()


func resume_after_boss() -> void:
	stop_boss_side_waves()
	boss_board_drain_pending = false
	boss_paused = false
	step_timer = 0.0
	spawn_next_row()


func start_boss_side_waves() -> void:
	boss_side_wave_active = true
	boss_side_wave_timer = randf_range(boss_side_wave_interval_min, boss_side_wave_interval_max)
	boss_side_wave_attempt_left = 0.0
	boss_projectile_separation_left = 0.0
	step_timer = 0.0


func stop_boss_side_waves() -> void:
	boss_side_wave_active = false
	boss_side_wave_timer = 0.0
	boss_side_wave_attempt_left = 0.0
	boss_projectile_separation_left = 0.0


func notify_boss_projectile_fired() -> void:
	if boss_side_wave_active:
		boss_projectile_separation_left = BOSS_EVENT_SEPARATION


func resume_after_progression_boss(next_depth: int) -> void:
	GameManager.run_depth = next_depth
	rows_spawned_since_depth = 0
	apply_depth_settings()
	resume_after_boss()


func _refresh_danger_line_from_paddle() -> void:
	var paddle_node := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle_node):
		return
	var paddle_half_height := 0.0
	var paddle_collision := paddle_node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if is_instance_valid(paddle_collision) and paddle_collision.shape is RectangleShape2D:
		var paddle_shape := paddle_collision.shape as RectangleShape2D
		paddle_half_height = paddle_shape.size.y * 0.5 * absf(paddle_node.global_scale.y)
	var paddle_top_y := paddle_node.global_position.y - paddle_half_height
	danger_line_y = paddle_top_y - brick_danger_gap


func check_danger_line():
	var crossed_bricks = []
	for brick in get_tree().get_nodes_in_group("game_brick"):
		if not is_instance_valid(brick):
			continue
		if brick.get("is_destroyed") == true:
			continue
		if get_brick_bottom(brick) >= danger_line_y:
			crossed_bricks.append(brick)

	for brick in crossed_bricks:
		remove_danger_brick(brick)


func spawn_next_row():
	if boss_board_drain_pending or boss_paused:
		return
	var row_depth: int = GameManager.run_depth

	# Remainder dÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¼nya-grid fazÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±nÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± korur; yeni brick local konumu spawn sonrasÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â± sabit kalÃƒÆ’Ã¢â‚¬ÂÃƒâ€šÃ‚Â±r.
	var created = level_generator.create_continuous_row(
		self,
		top_row_y + distance_since_row - position.y,
		rows_spawned_since_depth
	)
	game.register_spawned_bricks(created)
	print_difficulty_debug(created)
	rows_spawned_since_depth += 1

	if rows_spawned_since_depth >= rows_per_depth:
		rows_spawned_since_depth = 0
		increase_depth()

	if game.has_method("on_continuous_row_spawned"):
		game.on_continuous_row_spawned(row_depth)


func brick_destroyed(brick_position, brick_color, source = "ball", damage_context = null, brick_instance_id: int = 0):

	# Brick scriptlerinin mevcut parent callback sÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¶zleÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€¦Ã‚Â¸mesini Main'e ilet.
	game.brick_destroyed(brick_position, brick_color, source, damage_context, brick_instance_id)


func trigger_explosive_blast(origin, source_brick, damage_context = null, is_chain_reaction = false):

	var context = damage_context
	if context == null:
		context = {
			"detonated": {},
			"damaged": {}
		}

	var source_id = source_brick.get_instance_id()
	if context["detonated"].has(source_id):
		return

	context["detonated"][source_id] = true
	context["damaged"][source_id] = true

	if is_chain_reaction:
		await get_tree().create_timer(explosive_chain_delay).timeout

	spawn_explosion_visual(origin)

	for target in get_tree().get_nodes_in_group("game_brick"):
		if not is_instance_valid(target) or target == source_brick:
			continue
		if target.get("is_destroyed") == true:
			continue
		if target.global_position.distance_to(origin) > explosive_radius:
			continue

		var target_id = target.get_instance_id()
		if context["damaged"].has(target_id):
			continue

		context["damaged"][target_id] = true
		target.hit("explosion", context)


func spawn_explosion_visual(origin):
	play_explosion_sfx()

	var effect_root = Node2D.new()
	effect_root.name = "ExplosiveBrickBlast"
	effect_root.global_position = origin
	effect_root.z_index = 35
	if OS.has_feature("mobile"):
		effect_root.scale = Vector2.ONE * 1.20
	get_tree().current_scene.add_child(effect_root)

	var center = Polygon2D.new()
	var center_points = PackedVector2Array()
	for point_index in range(16):
		center_points.append(Vector2.from_angle(TAU * point_index / 16.0) * 9.0)
	center.polygon = center_points
	center.color = Color("#FFF1D6")
	effect_root.add_child(center)

	var center_tween = center.create_tween()
	center_tween.set_parallel(true)
	center_tween.tween_property(center, "scale", Vector2.ONE * 2.0, 0.20)
	center_tween.tween_property(center, "modulate:a", 0.0, 0.20)

	var ring = Line2D.new()
	var ring_points = PackedVector2Array()
	for point_index in range(25):
		ring_points.append(Vector2.from_angle(TAU * point_index / 24.0) * 12.0)
	ring.points = ring_points
	ring.width = 2.0
	ring.default_color = Color("#FF8500")
	ring.antialiased = true
	effect_root.add_child(ring)

	var ring_tween = ring.create_tween()
	ring_tween.set_parallel(true)
	ring_tween.tween_property(ring, "scale", Vector2.ONE * 3.1, 0.28)
	ring_tween.tween_property(ring, "modulate:a", 0.0, 0.28)

	for spark_index in range(10):
		var spark = Polygon2D.new()
		spark.polygon = PackedVector2Array([
			Vector2(-1.2, -0.7), Vector2(3.5, 0), Vector2(-1.2, 0.7)
		])
		spark.color = Color("#FFB340") if spark_index % 2 == 0 else Color("#FFF1D6")
		effect_root.add_child(spark)

		var angle = randf_range(0.0, TAU)
		spark.rotation = angle
		var spark_tween = spark.create_tween()
		spark_tween.set_parallel(true)
		spark_tween.tween_property(spark, "position", Vector2.from_angle(angle) * randf_range(28.0, 58.0), 0.26)
		spark_tween.tween_property(spark, "scale", Vector2(0.15, 0.15), 0.26)
		spark_tween.tween_property(spark, "modulate:a", 0.0, 0.26)

	get_tree().create_timer(0.32).timeout.connect(effect_root.queue_free)


func play_explosion_sfx() -> void:
	var now_msec := Time.get_ticks_msec()
	if now_msec - last_explosion_sfx_msec < EXPLOSION_SFX_RETRIGGER_MSEC:
		return
	for player in explosion_sfx_players:
		if player.playing:
			continue
		last_explosion_sfx_msec = now_msec
		player.pitch_scale = randf_range(0.97, 1.03)
		player.play()
		return


func increase_depth():

	GameManager.run_depth += 1
	apply_depth_settings()
	game.update_depth_debug_label(
		row_step_interval,
		maxf(row_step_interval - step_timer, 0.0)
	)
	print_difficulty_debug(0)


func apply_depth_settings():

	level_generator.configure_for_depth(GameManager.run_depth)

	var depth_intervals = [1.50, 1.35, 1.20, 1.05, 0.90, 0.75]
	var base_interval: float
	if GameManager.run_depth == 1 and not OS.has_feature("mobile"):
		base_interval = desktop_initial_row_step_interval
	elif GameManager.run_depth <= depth_intervals.size():
		base_interval = depth_intervals[GameManager.run_depth - 1]
	else:
		base_interval = 0.75
	var calculated_interval: float = (
		base_interval
		* GameManager.post_boss_descent_multiplier
		* GameManager.get_build_speed_multiplier()
		* GameManager.get_late_game_descent_multiplier()
		* GameManager.get_sector_descent_scale()
		* GameManager.get_curse_descent_scale()
		* GameManager.get_ascension_descent_scale()
		* (mobile_descent_multiplier if OS.has_feature("mobile") else 1.0)
	)
	interval_before_power_synergy = maxf(calculated_interval, _get_effective_min_step_interval())
	_refresh_mobile_power_synergy_pressure()
	if is_instance_valid(game):
		var side_spawner := game.get_node_or_null("SideAttackerSpawner")
		if is_instance_valid(side_spawner) and side_spawner.has_method("refresh_build_modifier"):
			side_spawner.refresh_build_modifier()


func _refresh_mobile_power_synergy_pressure() -> void:
	if not OS.has_feature("mobile"):
		level_generator.set_mobile_power_synergy(0, 0.0)
		# Apply the speed reduction after the floor so it also works at saturation.
		row_step_interval = maxf(interval_before_power_synergy, _get_effective_min_step_interval()) / GameManager.get_card_descent_multiplier()
		return
	var tier := GameManager.get_power_synergy_tier()
	if tier != last_power_synergy_tier:
		last_power_synergy_tier = tier
		var tier_names := ["NONE", "TIER 1", "TIER 2", "TIER 3", "EXTREME"]
		print("POWER SYNERGY: " + tier_names[tier])

	var pressure_scale := 0.0
	if OS.has_feature("mobile") and GameManager.run_depth >= 4 and tier > 0:
		pressure_scale = _get_board_synergy_pressure_scale()
	level_generator.set_mobile_power_synergy(tier, pressure_scale)
	var synergy_multiplier := GameManager.get_power_synergy_interval_multiplier(tier)
	var adaptive_multiplier := lerpf(1.0, synergy_multiplier, pressure_scale)
	# Keep the same floor/pressure calculation, then slow actual movement by 15%.
	row_step_interval = maxf(
		interval_before_power_synergy * adaptive_multiplier,
		_get_effective_min_step_interval()
	) / GameManager.get_card_descent_multiplier()


func _get_board_synergy_pressure_scale() -> float:
	var closest_distance := INF
	for brick: Node2D in get_tree().get_nodes_in_group("game_brick"):
		if not is_instance_valid(brick) or not is_ancestor_of(brick):
			continue
		if brick.get("is_destroyed") == true:
			continue
		closest_distance = minf(closest_distance, danger_line_y - get_brick_bottom(brick))
	if closest_distance <= SYNERGY_PRESSURE_STOP_DISTANCE:
		return 0.0
	if closest_distance <= SYNERGY_PRESSURE_HALF_DISTANCE:
		return 0.5
	return 1.0

func print_difficulty_debug(bricks_this_row):
	var turret_interval := Vector2.ZERO
	if is_instance_valid(game):
		var side_spawner := game.get_node_or_null("SideAttackerSpawner")
		if is_instance_valid(side_spawner) and side_spawner.has_method("get_interval_for_depth"):
			turret_interval = side_spawner.get_interval_for_depth(GameManager.run_depth)
	print(
		"DEPTH: %d | FILL: %.2f | ARMOR: %.2f | SHIELD: %.2f | EXPLOSIVE: %.2f | ELITE: %.3f | STEP_INTERVAL: %.2f | TURRET: %.2f-%.2f | BRICKS_THIS_ROW: %d"
		% [
			GameManager.run_depth,
			level_generator.get_effective_continuous_row_fill(),
			level_generator.get_effective_armored_chance(),
			level_generator.get_effective_shield_chance(),
			level_generator.explosive_chance,
			EliteBricks.get_chance(GameManager.run_depth, GameManager.run_ascension),
			row_step_interval,
			turret_interval.x,
			turret_interval.y,
			bricks_this_row
		]
	)


func debug_advance_depth():

	increase_depth()


func get_brick_bottom(brick):

	var collision_shape = brick.get_node_or_null("CollisionShape2D")
	if collision_shape and collision_shape.shape is RectangleShape2D:
		return brick.global_position.y + collision_shape.shape.size.y * absf(brick.global_scale.y) * 0.5
	return brick.global_position.y


func remove_danger_brick(brick):

	if not is_instance_valid(brick):
		return

	brick.remove_from_group("game_brick")
	game.unregister_danger_brick()
	brick.queue_free()

	if danger_cooldown_left <= 0.0 and not game.game_over:
		danger_cooldown_left = danger_damage_cooldown
		game.apply_danger_damage()
