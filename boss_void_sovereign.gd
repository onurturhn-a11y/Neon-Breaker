extends "res://boss_sprite_entity.gd"

# ==================================================
# THE VOID SOVEREIGN - 5. progression boss (depth 40)
#
# Void varliginin yukseltilmis hali. Onceki bosslardan farki:
# TEK degil IKI imza saldirisi var ve bunlari sirayla kullaniyor.
#
#   1) VOID TORRENT - yukaridan inen genis bir akinti, ama sabit
#      durmuyor: oyun alanini yatay olarak TARIYOR. Celestial'in
#      sabit sutunlarindan farki bu; kacmak icin taramanin oniinden
#      cikman gerekiyor.
#   2) VOID SPIKES  - taban boyunca isaretlenen bolgelerden diken
#      firliyor. Raketin isaretli bolgede olmamasi gerekiyor.
#
# Faz 3'te iki saldiri arka arkaya geliyor.
#
# Ortak iskelet (poz harmanlama, hareket, hasar, fazlar) icin
# boss_sprite_entity.gd'ye bak.
# ==================================================

const TORRENT_HALF_WIDTH := 46.0
const TORRENT_LIFETIME := 1.45
const TORRENT_FADE := 0.22

const SPIKE_ZONE_HALF_WIDTH := 62.0
const SPIKE_RISE := 0.22
const SPIKE_HOLD := 0.40
const SPIKE_FADE := 0.26

var spike_burst_texture: Texture2D
var spike_shards_texture: Texture2D
var effect_textures_loaded := false
var next_attack := 0


func _get_boss_label() -> String:
	return "THE VOID SOVEREIGN"


func _get_base_hp() -> int:
	return 330


func _get_extra_group() -> StringName:
	return &"void_sovereign_boss"


func _get_frame_dir() -> String:
	return "res://assets/bosses/void_sovereign/"


## Mermi dokusu void varligiyla ayni tema; ayrica uretmeye gerek yok.
func _get_shard_texture_path() -> String:
	return "res://assets/bosses/void/shard_projectile.png"


func _get_target_sprite_height() -> float:
	# Kareler diken alanini da icerdigi icin tuval karakterden uzun.
	return 290.0


func _get_frame_sets() -> Dictionary:
	var sets := FRAME_SETS.duplicate(true)
	sets[&"charge_2"] = ["charge_2.png"]
	sets[&"release_2"] = ["release_2.png"]
	return sets


func _get_projectile_palette() -> Array:
	return [
		Color(0.30, 0.96, 0.94, 1.0),
		Color(0.55, 1.00, 0.92, 1.0),
		Color(0.80, 1.00, 1.00, 1.0),
	]


func _get_core_glow_alpha_scale() -> float:
	return 0.22


func _get_enrage_message() -> String:
	return "BOŞLUK HÜKMEDİYOR"


func _get_phase_message(phase: int) -> String:
	return "VOID FAZ %d" % phase


func _get_telegraph_duration() -> float:
	if current_phase >= 3:
		return 0.80
	if current_phase == 2:
		return 0.95
	return 1.10


func _get_attack_interval() -> float:
	if current_phase >= 3:
		return randf_range(4.2, 4.8)
	if current_phase == 2:
		return randf_range(5.2, 5.8)
	return randf_range(6.2, 6.8)


func _load_effect_textures() -> void:
	if effect_textures_loaded:
		return
	effect_textures_loaded = true
	var burst := _get_frame_dir() + "spike_burst.png"
	var shards := _get_frame_dir() + "spike_shards.png"
	if ResourceLoader.exists(burst):
		spike_burst_texture = load(burst) as Texture2D
	if ResourceLoader.exists(shards):
		spike_shards_texture = load(shards) as Texture2D


# ==================================================
# IMZA SALDIRILARI
# ==================================================

func _signature_loop() -> void:
	_load_effect_textures()
	await get_tree().create_timer(2.4).timeout
	while combat_active and accepting_damage:
		await get_tree().create_timer(_get_attack_interval()).timeout
		if not combat_active or not accepting_damage:
			return
		if next_attack == 0:
			await _run_torrent_attack()
		else:
			await _run_spike_attack()
		next_attack = 1 - next_attack
		# Faz 3'te ikisi arka arkaya geliyor.
		if current_phase >= 3 and combat_active and accepting_damage:
			await get_tree().create_timer(0.7).timeout
			if next_attack == 0:
				await _run_torrent_attack()
			else:
				await _run_spike_attack()
			next_attack = 1 - next_attack


# --------------------------------------------------
# 1) VOID TORRENT - tarayan akinti
# --------------------------------------------------

func _run_torrent_attack() -> void:
	signature_active = true
	if is_instance_valid(move_tween):
		move_tween.kill()
	_play_anim(&"charge")
	status_feedback.emit("VOID AKINTISI", &"exposed")

	var safe_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	var sweep := _pick_torrent_sweep(safe_rect)
	var telegraph := _get_telegraph_duration()
	var mark := _spawn_torrent_telegraph(sweep, telegraph)
	await get_tree().create_timer(telegraph).timeout
	if is_instance_valid(mark):
		mark.queue_free()
	if not combat_active or not accepting_damage:
		signature_active = false
		return

	_play_anim(&"release")
	_shake_world(3.0)
	await _run_torrent_sweep(sweep)
	signature_active = false
	_return_to_idle()


## Baslangic ve bitis x'i. Rakete dogru suepuruyor ki oyuncu kacmak zorunda kalsin.
func _pick_torrent_sweep(safe_rect: Rect2) -> Vector2:
	var min_x := safe_rect.position.x + TORRENT_HALF_WIDTH + 10.0
	var max_x := safe_rect.end.x - TORRENT_HALF_WIDTH - 10.0
	if max_x <= min_x:
		return Vector2(safe_rect.get_center().x, safe_rect.get_center().x)
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	var target := safe_rect.get_center().x
	if is_instance_valid(paddle):
		target = clampf(paddle.global_position.x, min_x, max_x)
	var span := (max_x - min_x) * (0.62 if current_phase >= 3 else 0.48)
	var from_x := clampf(target - span if randf() < 0.5 else target + span, min_x, max_x)
	var to_x := clampf(target + (target - from_x), min_x, max_x)
	return Vector2(from_x, to_x)


func _get_torrent_span() -> Vector2:
	var safe_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	var top := global_position.y + BODY_HALF_HEIGHT * absf(global_scale.y) * 0.30
	return Vector2(top, safe_rect.end.y + 40.0)


func _spawn_torrent_telegraph(sweep: Vector2, duration: float) -> Node2D:
	var span := _get_torrent_span()
	var root := Node2D.new()
	root.z_index = 6
	root.global_position = Vector2(0.0, 0.0)
	get_parent().add_child(root)

	# Yalnizca akintinin BASLANGIC sutunu isaretlenir. Onceden koridorun
	# tamami dolduruluyordu; bu ekranin neredeyse yarisini yikiyor ve
	# telgraf gibi degil, hata gibi gorunuyordu.
	var start_field := Polygon2D.new()
	start_field.polygon = _column_polygon(TORRENT_HALF_WIDTH, span)
	start_field.position.x = sweep.x
	start_field.color = Color(0.14, 0.55, 0.62, 0.14)
	root.add_child(start_field)

	for side: float in [-1.0, 1.0]:
		var edge := Line2D.new()
		edge.points = PackedVector2Array([
			Vector2(sweep.x + TORRENT_HALF_WIDTH * side, span.x),
			Vector2(sweep.x + TORRENT_HALF_WIDTH * side, span.y)
		])
		edge.width = 2.2
		edge.default_color = Color(0.38, 0.98, 0.94, 0.55)
		edge.antialiased = true
		root.add_child(edge)

	var lead := Polygon2D.new()
	lead.polygon = _column_polygon(4.0, span)
	lead.position.x = sweep.x
	lead.color = Color(0.55, 1.0, 0.98, 0.75)
	root.add_child(lead)

	# Tarama yonu tabana yakin ilerleyen chevron'larla veriliyor.
	var direction := signf(sweep.y - sweep.x)
	if direction == 0.0:
		direction = 1.0
	var count := 5
	for index in range(count):
		var chevron := Line2D.new()
		chevron.width = 3.0
		chevron.default_color = Color(0.45, 1.0, 0.96, 0.0)
		chevron.antialiased = true
		chevron.points = PackedVector2Array([
			Vector2(-14.0 * direction, -13.0),
			Vector2(6.0 * direction, 0.0),
			Vector2(-14.0 * direction, 13.0)
		])
		# Oyun alani dikeyde viewport'tan uzun olabiliyor; hem oran hem taban
		# referansi kadraj disina dusuyordu. Bossa gore sabit mesafe guvenli.
		chevron.position = Vector2(
			lerpf(sweep.x, sweep.y, float(index) / float(count - 1)),
			minf(span.x + 230.0, span.y - 60.0)
		)
		root.add_child(chevron)
		var blink := chevron.create_tween().set_loops()
		blink.tween_interval(duration * 0.13 * float(index))
		blink.tween_property(chevron, "default_color:a", 0.90, duration * 0.16)
		blink.tween_property(chevron, "default_color:a", 0.0, duration * 0.20)

	_apply_additive(root)
	var charge := root.create_tween().set_parallel(true)
	charge.tween_property(lead, "scale:x", 4.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	charge.tween_property(start_field, "color:a", 0.30, duration)
	return root


func _run_torrent_sweep(sweep: Vector2) -> void:
	var span := _get_torrent_span()
	var root := Node2D.new()
	root.z_index = 7
	root.global_position = Vector2(sweep.x, 0.0)
	get_parent().add_child(root)

	var fade := 90.0
	_add_gradient_band(root, span, TORRENT_HALF_WIDTH * 3.00, Color(0.14, 0.62, 0.74, 0.50), fade)
	_add_gradient_band(root, span, TORRENT_HALF_WIDTH * 1.70, Color(0.22, 0.88, 0.92, 0.72), fade)
	_add_gradient_band(root, span, TORRENT_HALF_WIDTH * 0.90, Color(0.48, 1.00, 0.97, 0.92), fade * 0.8)
	var core := Polygon2D.new()
	core.polygon = _column_polygon(TORRENT_HALF_WIDTH * 0.09, Vector2(span.x + fade * 0.4, span.y))
	core.color = Color(0.92, 1.0, 1.0, 0.95)
	root.add_child(core)
	_apply_additive(root)

	var flicker := core.create_tween().set_loops()
	flicker.tween_property(core, "scale:x", 1.45, 0.04)
	flicker.tween_property(core, "scale:x", 0.70, 0.05)

	root.scale.x = 0.3
	var open := root.create_tween()
	open.tween_property(root, "scale:x", 1.0, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_torrent_motes(root, span)

	# Tarama: her fizik karesinde raketin akintinin icinde olup olmadigina bak.
	var travel := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	travel.tween_property(root, "global_position:x", sweep.y, TORRENT_LIFETIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var elapsed := 0.0
	while elapsed < TORRENT_LIFETIME and is_instance_valid(root):
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
		_apply_torrent_damage(root.global_position.x)

	if is_instance_valid(root):
		var close := root.create_tween().set_parallel(true)
		close.tween_property(root, "modulate:a", 0.0, TORRENT_FADE)
		close.tween_property(root, "scale:x", 0.22, TORRENT_FADE)
		close.chain().tween_callback(root.queue_free)


func _torrent_motes(root: Node2D, span: Vector2) -> void:
	var count := 8 if OS.has_feature("mobile") else 14
	for index in range(count):
		var mote := Polygon2D.new()
		mote.polygon = PackedVector2Array([
			Vector2(0.0, -5.0), Vector2(4.0, 0.0), Vector2(0.0, 5.0), Vector2(-4.0, 0.0)
		])
		# Akintinin icindeki koyu void lekeleri: sanatta da boyle.
		mote.color = Color(0.02, 0.04, 0.06, 0.85)
		mote.position = Vector2(randf_range(-TORRENT_HALF_WIDTH * 0.7, TORRENT_HALF_WIDTH * 0.7), span.x)
		root.add_child(mote)
		var drift := mote.create_tween()
		drift.tween_interval(randf_range(0.0, 0.5))
		drift.tween_property(mote, "position:y", span.y, randf_range(0.5, 0.85)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		drift.tween_callback(mote.queue_free)


func _apply_torrent_damage(column_x: float) -> void:
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		return
	if absf(paddle.global_position.x - column_x) > TORRENT_HALF_WIDTH + _get_paddle_half_width(paddle):
		return
	var game_root := get_parent()
	if is_instance_valid(game_root) and game_root.has_method("apply_enemy_projectile_damage"):
		game_root.apply_enemy_projectile_damage()


# --------------------------------------------------
# 2) VOID SPIKES - tabandan firlayan dikenler
# --------------------------------------------------

func _run_spike_attack() -> void:
	signature_active = true
	if is_instance_valid(move_tween):
		move_tween.kill()
	_play_anim(&"charge_2")
	status_feedback.emit("VOID DİKENLERİ", &"exposed")

	var zones := _pick_spike_zones()
	var telegraph := _get_telegraph_duration()
	var marks: Array[Node2D] = []
	for zone_x: float in zones:
		marks.append(_spawn_spike_telegraph(zone_x, telegraph))
	await get_tree().create_timer(telegraph).timeout
	for mark: Node2D in marks:
		if is_instance_valid(mark):
			mark.queue_free()
	if not combat_active or not accepting_damage:
		signature_active = false
		return

	_play_anim(&"release_2")
	_shake_world(3.2)
	for zone_x: float in zones:
		_spawn_spike(zone_x)
	_apply_spike_damage(zones)

	await get_tree().create_timer(SPIKE_RISE + SPIKE_HOLD).timeout
	signature_active = false
	_return_to_idle()


func _pick_spike_zones() -> Array[float]:
	var safe_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	var min_x := safe_rect.position.x + SPIKE_ZONE_HALF_WIDTH
	var max_x := safe_rect.end.x - SPIKE_ZONE_HALF_WIDTH
	var zones: Array[float] = []
	if max_x <= min_x:
		zones.append(safe_rect.get_center().x)
		return zones
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if is_instance_valid(paddle):
		zones.append(clampf(paddle.global_position.x, min_x, max_x))
	else:
		zones.append(safe_rect.get_center().x)
	var count := 3 if current_phase >= 3 else 2
	# Bolgeler arasinda raketin sigacagi bosluk kalsin.
	var separation := SPIKE_ZONE_HALF_WIDTH * 2.9
	var guard := 0
	while zones.size() < count and guard < 60:
		guard += 1
		var candidate := randf_range(min_x, max_x)
		var too_close := false
		for existing: float in zones:
			if absf(existing - candidate) < separation:
				too_close = true
				break
		if not too_close:
			zones.append(candidate)
	return zones


func _get_spike_floor_y() -> float:
	return GameManager.get_gameplay_rect(get_viewport_rect().size).end.y - 26.0


func _spawn_spike_telegraph(zone_x: float, duration: float) -> Node2D:
	var floor_y := _get_spike_floor_y()
	var root := Node2D.new()
	root.z_index = 6
	root.global_position = Vector2(zone_x, floor_y)
	get_parent().add_child(root)

	var pad := Polygon2D.new()
	var points := PackedVector2Array()
	for index in range(20):
		var angle := TAU * float(index) / 20.0
		points.append(Vector2(cos(angle) * SPIKE_ZONE_HALF_WIDTH, sin(angle) * 20.0))
	pad.polygon = points
	pad.color = Color(0.28, 0.92, 0.90, 0.20)
	root.add_child(pad)

	var edge := Line2D.new()
	edge.points = points
	edge.closed = true
	edge.width = 2.4
	edge.default_color = Color(0.45, 1.0, 0.96, 0.80)
	edge.antialiased = true
	root.add_child(edge)

	# Yukselen ipuclari: dikenin nereden cikacagini gosterir.
	for index in range(4):
		var hint := Polygon2D.new()
		hint.polygon = PackedVector2Array([Vector2(-4.0, 0.0), Vector2(0.0, -26.0), Vector2(4.0, 0.0)])
		hint.color = Color(0.55, 1.0, 0.98, 0.0)
		hint.position.x = lerpf(-SPIKE_ZONE_HALF_WIDTH * 0.6, SPIKE_ZONE_HALF_WIDTH * 0.6, float(index) / 3.0)
		root.add_child(hint)
		var pulse := hint.create_tween().set_loops()
		pulse.tween_interval(duration * 0.12 * float(index))
		pulse.tween_property(hint, "color:a", 0.85, duration * 0.20)
		pulse.tween_property(hint, "color:a", 0.0, duration * 0.20)

	_apply_additive(root)
	var grow := root.create_tween()
	grow.tween_property(pad, "color:a", 0.36, duration)
	return root


func _spawn_spike(zone_x: float) -> void:
	var floor_y := _get_spike_floor_y()
	var root := Node2D.new()
	root.z_index = 8
	root.global_position = Vector2(zone_x, floor_y)
	get_parent().add_child(root)

	if spike_burst_texture != null:
		var burst := Sprite2D.new()
		burst.texture = spike_burst_texture
		burst.centered = false
		var target_height := 210.0
		var factor := target_height / float(spike_burst_texture.get_height())
		burst.scale = Vector2.ONE * factor
		burst.position = Vector2(-spike_burst_texture.get_width() * factor * 0.5, -target_height)
		root.add_child(burst)
	else:
		# Doku yoksa prosedural diken taragi.
		for index in range(5):
			var spike := Polygon2D.new()
			var half := randf_range(9.0, 16.0)
			var height := randf_range(90.0, 165.0)
			spike.polygon = PackedVector2Array([
				Vector2(-half, 0.0), Vector2(0.0, -height), Vector2(half, 0.0)
			])
			spike.color = Color(0.30, 0.92, 0.92, 0.92)
			spike.position.x = lerpf(-SPIKE_ZONE_HALF_WIDTH * 0.8, SPIKE_ZONE_HALF_WIDTH * 0.8, float(index) / 4.0)
			root.add_child(spike)

	if spike_shards_texture != null:
		var shards := Sprite2D.new()
		shards.texture = spike_shards_texture
		shards.modulate = Color(1.0, 1.0, 1.0, 0.85)
		var shard_factor := 150.0 / float(spike_shards_texture.get_height())
		shards.scale = Vector2.ONE * shard_factor
		shards.position = Vector2(0.0, -70.0)
		root.add_child(shards)

	_apply_additive(root)
	root.scale.y = 0.05
	root.modulate.a = 0.0
	var rise := root.create_tween()
	rise.set_parallel(true)
	rise.tween_property(root, "scale:y", 1.0, SPIKE_RISE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rise.tween_property(root, "modulate:a", 1.0, SPIKE_RISE * 0.6)
	rise.chain().tween_interval(SPIKE_HOLD)
	rise.set_parallel(true)
	rise.tween_property(root, "modulate:a", 0.0, SPIKE_FADE)
	rise.tween_property(root, "scale:y", 0.15, SPIKE_FADE)
	rise.set_parallel(false)
	rise.tween_callback(root.queue_free)


func _apply_spike_damage(zones: Array[float]) -> void:
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		return
	var paddle_half := _get_paddle_half_width(paddle)
	for zone_x: float in zones:
		if absf(paddle.global_position.x - zone_x) > SPIKE_ZONE_HALF_WIDTH + paddle_half:
			continue
		var game_root := get_parent()
		if is_instance_valid(game_root) and game_root.has_method("apply_enemy_projectile_damage"):
			game_root.apply_enemy_projectile_damage()
		return


func _spawn_defeat_burst() -> void:
	for index in range(18):
		var mote := Polygon2D.new()
		mote.polygon = PackedVector2Array([
			Vector2(0.0, -7.0), Vector2(12.0, 0.0), Vector2(0.0, 7.0), Vector2(-12.0, 0.0)
		])
		mote.color = Color(0.42, 1.0, 0.96, 0.9) if index % 2 == 0 else Color(0.16, 0.55, 0.72, 0.85)
		mote.material = _get_additive_material()
		var angle := TAU * float(index) / 18.0
		mote.position = Vector2.from_angle(angle) * randf_range(100.0, 170.0)
		mote.rotation = angle
		visual_root.add_child(mote)
		var suck := mote.create_tween().set_parallel(true)
		suck.tween_property(mote, "position", Vector2.ZERO, randf_range(0.42, 0.66)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		suck.tween_property(mote, "rotation", angle + randf_range(-3.0, 3.0), 0.64)
		suck.tween_property(mote, "modulate:a", 0.0, 0.70)
		suck.chain().tween_callback(mote.queue_free)
