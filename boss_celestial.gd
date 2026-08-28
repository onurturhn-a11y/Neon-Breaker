extends "res://boss_sprite_entity.gd"

# ==================================================
# THE CELESTIAL - 3. progression boss (depth 24)
#
# Imza mekanigi: prizma sutunu. Boss once sarj olur (telegraph),
# sonra oyun alanina dikey lazer sutunlari indirir. Sutunlarin
# arasindaki bosluga kacmak zorundasin; faz ilerledikce sutun
# sayisi artar.
#
# Ortak iskelet (poz harmanlama, hareket, hasar, fazlar) icin
# boss_sprite_entity.gd'ye bak.
# ==================================================

const BEAM_HALF_WIDTH := 27.0
const BEAM_LIFETIME := 0.50
const BEAM_FADE := 0.20


func _get_boss_label() -> String:
	return "THE CELESTIAL"


func _get_base_hp() -> int:
	return 200

func _get_extra_group() -> StringName:
	return &"celestial_boss"

func _get_frame_dir() -> String:
	return "res://assets/bosses/celestial/"

func _get_shard_texture_path() -> String:
	return "res://assets/bosses/celestial/shard_projectile.png"

func _get_target_sprite_height() -> float:
	return 200.0

func _get_projectile_palette() -> Array:
	return [
		Color(0.86, 0.32, 1.00, 1.0),
		Color(0.42, 0.92, 1.00, 1.0),
		Color(1.00, 0.62, 1.00, 1.0),
	]

func _get_enrage_message() -> String:
	return "PRİZMA ÖFKESİ"

func _get_phase_message(phase: int) -> String:
	return "PRİZMA FAZ %d" % phase

func _get_beam_interval() -> float:
	if current_phase >= 3:
		return randf_range(3.1, 3.6)
	if current_phase == 2:
		return randf_range(4.0, 4.6)
	return randf_range(5.0, 5.6)

func _get_telegraph_duration() -> float:
	if current_phase >= 3:
		return 0.80
	if current_phase == 2:
		return 0.95
	return 1.10

func _get_beam_column_count() -> int:
	return current_phase

func _signature_loop() -> void:
	# Ilk sutun dovusun hemen basinda gelmesin ama mekanik gec de tanitilmasin.
	await get_tree().create_timer(1.8).timeout
	while combat_active and accepting_damage:
		await get_tree().create_timer(_get_beam_interval()).timeout
		if not combat_active or not accepting_damage:
			return
		await _run_beam_attack()

func _run_beam_attack() -> void:
	signature_active = true
	if is_instance_valid(move_tween):
		move_tween.kill()
	_play_anim(&"charge")
	status_feedback.emit("PRİZMA ŞARJI", &"exposed")
	var columns := _pick_beam_columns(_get_beam_column_count())
	var telegraph_duration := _get_telegraph_duration()
	var telegraphs: Array[Node2D] = []
	for column_x: float in columns:
		telegraphs.append(_spawn_beam_telegraph(column_x, telegraph_duration))
	await get_tree().create_timer(telegraph_duration).timeout
	for telegraph: Node2D in telegraphs:
		if is_instance_valid(telegraph):
			telegraph.queue_free()
	if not combat_active or not accepting_damage:
		signature_active = false
		return
	_play_anim(&"release")
	_spawn_hand_flare()
	for column_x: float in columns:
		_spawn_beam(column_x)
	_shake_world(2.4 + 0.5 * float(columns.size()))
	_apply_beam_damage(columns)
	await get_tree().create_timer(BEAM_LIFETIME).timeout
	signature_active = false
	_return_to_idle()

func _pick_beam_columns(count: int) -> Array[float]:
	var safe_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	var min_x := safe_rect.position.x + BEAM_HALF_WIDTH
	var max_x := safe_rect.end.x - BEAM_HALF_WIDTH
	var columns: Array[float] = []
	if max_x <= min_x:
		columns.append(safe_rect.get_center().x)
		return columns
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if is_instance_valid(paddle):
		columns.append(clampf(paddle.global_position.x, min_x, max_x))
	else:
		columns.append(safe_rect.get_center().x)
	# Kalan sutunlar arasinda kacilabilir bosluk kalsin diye minimum ayrim uygula.
	var min_separation := BEAM_HALF_WIDTH * 3.4
	var guard := 0
	while columns.size() < count and guard < 48:
		guard += 1
		var candidate := randf_range(min_x, max_x)
		var too_close := false
		for existing_x: float in columns:
			if absf(existing_x - candidate) < min_separation:
				too_close = true
				break
		if not too_close:
			columns.append(candidate)
	return columns

func _get_beam_span() -> Vector2:
	# Sutun boss'un altindan oyun alaninin dibine kadar iner.
	var safe_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	var top := global_position.y + BODY_HALF_HEIGHT * absf(global_scale.y) * 0.35
	return Vector2(top, safe_rect.end.y + 40.0)

func _spawn_beam_telegraph(column_x: float, duration: float) -> Node2D:
	var span := _get_beam_span()
	var root := Node2D.new()
	root.z_index = 6
	root.global_position = Vector2(column_x, 0.0)
	get_parent().add_child(root)

	var field := Polygon2D.new()
	field.polygon = _column_polygon(BEAM_HALF_WIDTH, span)
	field.color = Color(0.42, 0.16, 0.72, 0.13)
	root.add_child(field)

	for side: float in [-1.0, 1.0]:
		var edge := Line2D.new()
		edge.points = PackedVector2Array([
			Vector2(BEAM_HALF_WIDTH * side, span.x), Vector2(BEAM_HALF_WIDTH * side, span.y)
		])
		edge.width = 2.2
		edge.default_color = Color(0.55, 1.0, 0.95, 0.50)
		edge.antialiased = true
		root.add_child(edge)

	var spine := Polygon2D.new()
	spine.polygon = _column_polygon(3.0, span)
	spine.color = Color(1.0, 0.72, 1.0, 0.55)
	root.add_child(spine)

	_spawn_charge_motes(root, span, duration)
	_apply_additive(root)

	# Sarj ilerledikce cekirdek kalinlasir: atesin ne zaman gelecegi okunur.
	var charge := root.create_tween().set_parallel(true)
	charge.tween_property(spine, "scale:x", 3.6, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	charge.tween_property(field, "color:a", 0.30, duration)

	var flicker := root.create_tween().set_loops()
	flicker.tween_property(root, "modulate:a", 1.0, duration * 0.16)
	flicker.tween_property(root, "modulate:a", 0.58, duration * 0.12)
	return root

func _spawn_charge_motes(root: Node2D, span: Vector2, duration: float) -> void:
	var count := 6 if OS.has_feature("mobile") else 10
	for index in range(count):
		var mote := Polygon2D.new()
		mote.polygon = PackedVector2Array([
			Vector2(0.0, -3.0), Vector2(8.0, 0.0), Vector2(0.0, 3.0), Vector2(-8.0, 0.0)
		])
		mote.color = Color(0.75, 0.95, 1.0, 0.0)
		var side := 1.0 if index % 2 == 0 else -1.0
		mote.position = Vector2(
			side * randf_range(95.0, 215.0),
			randf_range(span.x, minf(span.y, span.x + 560.0))
		)
		root.add_child(mote)
		var mote_tween := mote.create_tween()
		mote_tween.tween_interval(duration * 0.7 * float(index) / float(count))
		mote_tween.set_parallel(true)
		mote_tween.tween_property(mote, "position:x", 0.0, duration * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		mote_tween.tween_property(mote, "color:a", 0.85, duration * 0.30)
		mote_tween.chain().tween_property(mote, "color:a", 0.0, duration * 0.20)


# Gradyan dokular: vertex_colors ile yapilan gecisler ucgen kosegeni boyunca
# kama seklinde dikis birakiyordu. Tek Sprite2D + doku hem puruzsuz hem ucuz.

func _spawn_beam(column_x: float) -> void:
	var span := _get_beam_span()
	var root := Node2D.new()
	root.z_index = 7
	root.global_position = Vector2(column_x, 0.0)
	get_parent().add_child(root)

	var fade := 84.0
	# Genisten dara: yumusak hale -> mor govde -> camgobegi -> sicak beyaz.
	_add_gradient_band(root, span, BEAM_HALF_WIDTH * 3.60, Color(0.44, 0.18, 0.98, 0.34), fade)
	_add_gradient_band(root, span, BEAM_HALF_WIDTH * 1.90, Color(0.82, 0.34, 1.00, 0.52), fade)
	_add_gradient_band(root, span, BEAM_HALF_WIDTH * 1.05, Color(0.38, 0.96, 1.00, 0.78), fade * 0.8)
	_add_gradient_band(root, span, BEAM_HALF_WIDTH * 0.50, Color(0.96, 1.00, 1.00, 0.96), fade * 0.6)

	# Prizma kirilmasi: cekirdegin iki yaninda magenta/camgobegi serit.
	for fringe_side: float in [-0.58, 0.58]:
		var fringe := Polygon2D.new()
		fringe.polygon = _column_polygon(BEAM_HALF_WIDTH * 0.085, Vector2(span.x + fade * 0.55, span.y))
		fringe.position.x = BEAM_HALF_WIDTH * fringe_side
		fringe.color = Color(1.0, 0.30, 0.88, 0.75) if fringe_side < 0.0 else Color(0.32, 1.0, 0.96, 0.75)
		root.add_child(fringe)

	var core := Polygon2D.new()
	core.polygon = _column_polygon(BEAM_HALF_WIDTH * 0.17, Vector2(span.x + fade * 0.40, span.y))
	core.color = Color(1.0, 1.0, 1.0, 1.0)
	root.add_child(core)

	_apply_additive(root)

	var core_flicker := core.create_tween().set_loops()
	core_flicker.tween_property(core, "scale:x", 1.85, 0.035)
	core_flicker.tween_property(core, "scale:x", 0.68, 0.045)
	core_flicker.tween_property(core, "scale:x", 1.28, 0.030)

	root.scale.x = 0.26
	var strike := root.create_tween()
	strike.tween_property(root, "scale:x", 1.16, 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	strike.tween_property(root, "scale:x", 1.0, 0.05)
	strike.tween_interval(BEAM_LIFETIME - 0.11)
	strike.set_parallel(true)
	strike.tween_property(root, "modulate:a", 0.0, BEAM_FADE)
	strike.tween_property(root, "scale:x", 0.20, BEAM_FADE)
	strike.set_parallel(false)
	strike.tween_callback(root.queue_free)

	_beam_arc_loop(root, span)
	_beam_surge_loop(root, span)
	_spawn_beam_impact(Vector2(column_x, span.y - 70.0))


# Isin boyunca asagi akan parlak nabizlar: sutun "akiyor" hissi verir.

func _beam_surge_loop(root: Node2D, span: Vector2) -> void:
	var surges := 2 if OS.has_feature("mobile") else 4
	for index in range(surges):
		if not is_instance_valid(root):
			return
		_spawn_beam_surge(root, span)
		await get_tree().create_timer(BEAM_LIFETIME / float(surges + 1)).timeout

func _spawn_beam_surge(root: Node2D, span: Vector2) -> void:
	if not is_instance_valid(root):
		return
	# Isinin icinde kalsin: cok genis olursa sutunun tepesinde kutu gibi duruyor.
	var surge := _add_sprite(
		root, _get_beam_blob_texture(), Color(0.90, 1.0, 1.0, 0.95),
		Vector2(0.0, span.x + 56.0), Vector2(BEAM_HALF_WIDTH * 2.6, 54.0)
	)
	surge.material = _get_additive_material()
	var travel := surge.create_tween()
	travel.set_parallel(true)
	travel.tween_property(surge, "position:y", span.y, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	travel.tween_property(surge, "modulate:a", 0.0, 0.26).set_ease(Tween.EASE_IN)
	travel.chain().tween_callback(surge.queue_free)

func _beam_arc_loop(root: Node2D, span: Vector2) -> void:
	var bursts := 3 if OS.has_feature("mobile") else 6
	for index in range(bursts):
		if not is_instance_valid(root):
			return
		_spawn_beam_arc(root, span)
		if not OS.has_feature("mobile"):
			_spawn_beam_arc(root, span)
		await get_tree().create_timer(BEAM_LIFETIME / float(bursts + 1)).timeout

func _spawn_beam_arc(root: Node2D, span: Vector2) -> void:
	if not is_instance_valid(root):
		return
	var arc := Line2D.new()
	arc.width = randf_range(1.6, 2.8)
	arc.default_color = Color(0.72, 0.94, 1.0, 0.75)
	arc.antialiased = true
	arc.material = _get_additive_material()
	# Kisa parcali, dar genlikli: sutuna sarilan elektrik.
	var reach := BEAM_HALF_WIDTH * 0.85
	var length := randf_range(90.0, 190.0)
	var start_y := randf_range(span.x, maxf(span.x, span.y - length))
	var points := PackedVector2Array()
	var y := start_y
	while y < start_y + length and y < span.y:
		points.append(Vector2(randf_range(-reach, reach), y))
		y += randf_range(11.0, 22.0)
	if points.size() < 2:
		arc.queue_free()
		return
	arc.points = points
	root.add_child(arc)
	var arc_tween := arc.create_tween()
	arc_tween.tween_property(arc, "modulate:a", 0.0, randf_range(0.07, 0.13))
	arc_tween.tween_callback(arc.queue_free)


# Bossun elinde tek bir patlama: sutunlarin nereden geldigini baglar.

func _spawn_hand_flare() -> void:
	var flare := Node2D.new()
	flare.z_index = 9
	flare.global_position = to_global(Vector2(46.0, 26.0))
	get_parent().add_child(flare)

	_add_sprite(flare, _get_beam_blob_texture(), Color(0.62, 0.92, 1.0, 0.85),
		Vector2.ZERO, Vector2(150.0, 150.0))
	_add_sprite(flare, _get_beam_blob_texture(), Color(1.0, 1.0, 1.0, 0.95),
		Vector2.ZERO, Vector2(54.0, 54.0))

	for index in range(6):
		var spike := Line2D.new()
		spike.width = 2.6
		spike.default_color = Color(1.0, 0.62, 1.0, 0.85)
		spike.antialiased = true
		var angle := TAU * float(index) / 6.0 + randf_range(-0.2, 0.2)
		spike.points = PackedVector2Array([Vector2.ZERO, Vector2.from_angle(angle) * randf_range(34.0, 62.0)])
		flare.add_child(spike)

	_apply_additive(flare)
	flare.scale = Vector2.ONE * 0.45
	var flare_tween := flare.create_tween().set_parallel(true)
	flare_tween.tween_property(flare, "scale", Vector2.ONE * 1.35, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flare_tween.tween_property(flare, "modulate:a", 0.0, 0.28)
	flare_tween.chain().tween_callback(flare.queue_free)

func _spawn_beam_impact(impact_position: Vector2) -> void:
	var burst := Node2D.new()
	burst.z_index = 8
	burst.global_position = impact_position
	get_parent().add_child(burst)

	var flash := Polygon2D.new()
	var flash_points := PackedVector2Array()
	for index in range(18):
		var angle := TAU * float(index) / 18.0
		flash_points.append(Vector2(cos(angle), sin(angle) * 0.42) * 60.0)
	flash.polygon = flash_points
	flash.color = Color(0.90, 0.98, 1.0, 0.90)
	burst.add_child(flash)

	var ring_count := 2 if OS.has_feature("mobile") else 3
	var rings: Array[Line2D] = []
	for index in range(ring_count):
		var ring := Line2D.new()
		ring.width = 3.4
		ring.default_color = Color(1.0, 0.62, 1.0, 0.85) if index % 2 == 0 else Color(0.45, 0.95, 1.0, 0.85)
		ring.antialiased = true
		var ring_points := PackedVector2Array()
		for step in range(25):
			var angle := TAU * float(step) / 24.0
			ring_points.append(Vector2(cos(angle), sin(angle) * 0.34) * 34.0)
		ring.points = ring_points
		burst.add_child(ring)
		rings.append(ring)

	var spark_count := 8 if OS.has_feature("mobile") else 14
	var sparks: Array[Polygon2D] = []
	for index in range(spark_count):
		var spark := Polygon2D.new()
		spark.polygon = PackedVector2Array([Vector2(-3.0, -1.3), Vector2(6.5, 0.0), Vector2(-3.0, 1.3)])
		spark.color = Color(0.62, 0.98, 1.0, 0.95) if index % 2 == 0 else Color(1.0, 0.62, 1.0, 0.92)
		spark.rotation = randf_range(-PI * 0.92, -PI * 0.08)
		burst.add_child(spark)
		sparks.append(spark)

	_apply_additive(burst)

	var flash_tween := flash.create_tween().set_parallel(true)
	flash_tween.tween_property(flash, "scale", Vector2(1.9, 1.5), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(flash, "color:a", 0.0, 0.26)

	for index in range(rings.size()):
		var ring := rings[index]
		var ring_tween := ring.create_tween()
		ring_tween.tween_interval(0.06 * float(index))
		ring_tween.set_parallel(true)
		ring_tween.tween_property(ring, "scale", Vector2.ONE * randf_range(3.0, 4.2), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ring_tween.tween_property(ring, "modulate:a", 0.0, 0.42)

	for spark: Polygon2D in sparks:
		var spark_tween := spark.create_tween().set_parallel(true)
		spark_tween.tween_property(
			spark, "position",
			Vector2.from_angle(spark.rotation) * randf_range(48.0, 132.0),
			randf_range(0.26, 0.44)
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		spark_tween.tween_property(spark, "modulate:a", 0.0, 0.44)

	get_tree().create_timer(0.95).timeout.connect(burst.queue_free)

func _apply_beam_damage(columns: Array[float]) -> void:
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		return
	var paddle_half := _get_paddle_half_width(paddle)
	for column_x: float in columns:
		if absf(paddle.global_position.x - column_x) > BEAM_HALF_WIDTH + paddle_half:
			continue
		var game_root := get_parent()
		if is_instance_valid(game_root) and game_root.has_method("apply_enemy_projectile_damage"):
			game_root.apply_enemy_projectile_damage()
		return

func _spawn_shatter_burst() -> void:
	for index in range(16):
		var shard := Polygon2D.new()
		shard.z_index = 7
		shard.polygon = PackedVector2Array([
			Vector2(0.0, -9.0), Vector2(4.5, 0.0), Vector2(0.0, 9.0), Vector2(-4.5, 0.0)
		])
		shard.color = [
			Color(0.55, 0.98, 1.0, 0.95),
			Color(1.0, 0.55, 1.0, 0.92),
			Color(0.68, 1.0, 0.72, 0.92),
			Color(1.0, 0.86, 0.42, 0.92),
		][index % 4]
		shard.position = Vector2(randf_range(-40.0, 40.0), randf_range(-70.0, 60.0))
		visual_root.add_child(shard)
		var angle := TAU * float(index) / 16.0 + randf_range(-0.2, 0.2)
		var tween := shard.create_tween().set_parallel(true)
		tween.tween_property(shard, "position", shard.position + Vector2.from_angle(angle) * randf_range(70.0, 140.0), 0.70).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(shard, "rotation", randf_range(-4.0, 4.0), 0.70)
		tween.tween_property(shard, "modulate:a", 0.0, 0.70)
		tween.chain().tween_callback(shard.queue_free)
