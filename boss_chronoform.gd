extends "res://boss_sprite_entity.gd"

# ==================================================
# THE CHRONOFORM - 7. progression boss (depth 56)
#
# Serinin son bossu ve tek insansi olmayani: donen bir mandala.
# Palet de void mavisi-moru yerine mavi-turuncu.
#
# Iki imza saldirisi, ikisi de yeni bir okuma istiyor:
#
#   1) RUNIK SUPURGE - mandala donerken yelpaze halinde mermi
#      savuruyor. Onceki tum saldirilar DIKEYdi (sutun, akinti,
#      diken); bu RADYAL. Donen bosluklari okuman gerekiyor.
#   2) KRONO DUVARI - taban boyunca bastan basa kristal duvar
#      cikiyor, ama tek bir BOSLUK birakiyor. Bolgeden kacmak
#      degil, bosluga girmek gerekiyor - ters okuma.
#
# Ortak iskelet icin boss_sprite_entity.gd'ye bak.
# ==================================================

const SWEEP_VOLLEY_INTERVAL := 0.16
const SWEEP_DURATION := 1.15
## Yelpaze araligi (derece). 0 = saga, 90 = asagi.
const SWEEP_ANGLE_MIN := 22.0
const SWEEP_ANGLE_MAX := 158.0

const WALL_TILE_WIDTH := 130.0
const WALL_GAP_HALF_WIDTH := 78.0
const WALL_RISE := 0.22
const WALL_HOLD := 0.55
const WALL_FADE := 0.26

var wall_burst_texture: Texture2D
var wall_shards_texture: Texture2D
var effect_textures_loaded := false
var next_attack := 0
var spin_time := 0.0


func _get_boss_label() -> String:
	return "THE CHRONOFORM"


func _get_base_hp() -> int:
	return 500


func _get_extra_group() -> StringName:
	return &"chronoform_boss"


func _get_frame_dir() -> String:
	return "res://assets/bosses/chronoform/"


## Palet bos: bu bossun runeleri zaten turuncu, THE CORE'un varsayilan
## mermisi temaya birebir oturuyor. Ayri doku uretmeye gerek yok.
func _get_projectile_palette() -> Array:
	return []


func _get_target_sprite_height() -> float:
	return 235.0


func _get_frame_sets() -> Dictionary:
	var sets := FRAME_SETS.duplicate(true)
	sets[&"charge_2"] = ["charge_2.png"]
	sets[&"release_2"] = ["release_2.png"]
	return sets


func _get_core_glow_alpha_scale() -> float:
	return 0.45


func _get_enrage_message() -> String:
	return "ZAMAN ÇÖZÜLÜYOR"


func _get_phase_message(phase: int) -> String:
	return "KRONO FAZ %d" % phase


func _get_telegraph_duration() -> float:
	if current_phase >= 3:
		return 0.75
	if current_phase == 2:
		return 0.90
	return 1.05


func _get_attack_interval() -> float:
	if current_phase >= 3:
		return randf_range(3.7, 4.3)
	if current_phase == 2:
		return randf_range(4.7, 5.3)
	return randf_range(5.7, 6.3)


func _load_effect_textures() -> void:
	if effect_textures_loaded:
		return
	effect_textures_loaded = true
	var burst := _get_frame_dir() + "spike_burst.png"
	var shards := _get_frame_dir() + "spike_shards.png"
	if ResourceLoader.exists(burst):
		wall_burst_texture = load(burst) as Texture2D
	if ResourceLoader.exists(shards):
		wall_shards_texture = load(shards) as Texture2D


# Mandala surekli donuyor: insansi bosslarin "yatma" hareketi burada
# anlamsiz, onun yerine kendi ekseninde agir agir donuyor.
func _update_pose_motion(delta: float) -> void:
	super(delta)
	if not is_instance_valid(pose_root):
		return
	spin_time += delta
	var spin_speed := 0.30 + 0.10 * float(current_phase - 1)
	if signature_active:
		spin_speed *= 2.6
	pose_root.rotation = wrapf(pose_root.rotation + delta * spin_speed, -PI, PI)


# ==================================================
# IMZA SALDIRILARI
# ==================================================

func _signature_loop() -> void:
	_load_effect_textures()
	await get_tree().create_timer(2.3).timeout
	while combat_active and accepting_damage:
		await get_tree().create_timer(_get_attack_interval()).timeout
		if not combat_active or not accepting_damage:
			return
		if next_attack == 0:
			await _run_sweep_attack()
		else:
			await _run_wall_attack()
		next_attack = 1 - next_attack


# --------------------------------------------------
# 1) RUNIK SUPURGE - donen radyal yelpaze
# --------------------------------------------------

func _get_sweep_arms() -> int:
	if current_phase >= 3:
		return 4
	return 2 if current_phase == 1 else 3


func _run_sweep_attack() -> void:
	signature_active = true
	if is_instance_valid(move_tween):
		move_tween.kill()
	_play_anim(&"charge")
	status_feedback.emit("RUNİK SÜPÜRGE", &"exposed")

	var telegraph := _get_telegraph_duration()
	var sweep_from_left := randf() < 0.5
	var mark := _spawn_sweep_telegraph(sweep_from_left, telegraph)
	await get_tree().create_timer(telegraph).timeout
	if is_instance_valid(mark):
		mark.queue_free()
	if not combat_active or not accepting_damage:
		signature_active = false
		return

	_play_anim(&"release")
	_shake_world(2.6)

	var arms := _get_sweep_arms()
	var volleys := int(SWEEP_DURATION / SWEEP_VOLLEY_INTERVAL)
	for volley in range(volleys):
		if not combat_active or not accepting_damage:
			break
		var progress := float(volley) / float(maxi(volleys - 1, 1))
		if not sweep_from_left:
			progress = 1.0 - progress
		var base_angle := lerpf(SWEEP_ANGLE_MIN, SWEEP_ANGLE_MAX, progress)
		for arm in range(arms):
			# Kollar yelpazeye esit dagiliyor: aralarinda gecilebilir bosluk kaliyor.
			var offset := (SWEEP_ANGLE_MAX - SWEEP_ANGLE_MIN) * float(arm) / float(arms)
			_fire_rune_bolt(wrapf(base_angle + offset, 0.0, 360.0))
		await get_tree().create_timer(SWEEP_VOLLEY_INTERVAL).timeout

	signature_active = false
	_return_to_idle()


func _fire_rune_bolt(angle_degrees: float) -> void:
	var direction := Vector2.RIGHT.rotated(deg_to_rad(angle_degrees))
	var projectile := PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + direction * 48.0
	projectile.setup(get_parent(), direction, projectile_speed * 0.86)
	if get_parent().has_method("notify_boss_projectile_fired"):
		get_parent().notify_boss_projectile_fired()


func _spawn_sweep_telegraph(from_left: bool, duration: float) -> Node2D:
	var root := Node2D.new()
	root.z_index = 6
	root.global_position = global_position
	get_parent().add_child(root)

	# Yelpazenin sinirlari ve tarama yonu.
	for angle_degrees: float in [SWEEP_ANGLE_MIN, SWEEP_ANGLE_MAX]:
		var edge := Line2D.new()
		edge.width = 2.2
		edge.default_color = Color(1.0, 0.62, 0.20, 0.55)
		edge.antialiased = true
		var direction := Vector2.RIGHT.rotated(deg_to_rad(angle_degrees))
		edge.points = PackedVector2Array([direction * 54.0, direction * 300.0])
		root.add_child(edge)

	var arc := Line2D.new()
	arc.width = 2.6
	arc.default_color = Color(0.42, 0.72, 1.0, 0.60)
	arc.antialiased = true
	var arc_points := PackedVector2Array()
	for index in range(25):
		var t := float(index) / 24.0
		var angle := deg_to_rad(lerpf(SWEEP_ANGLE_MIN, SWEEP_ANGLE_MAX, t))
		arc_points.append(Vector2(cos(angle), sin(angle)) * 210.0)
	arc.points = arc_points
	root.add_child(arc)

	# Tarama yonunde ilerleyen isaretci.
	var marker := Polygon2D.new()
	marker.polygon = PackedVector2Array([Vector2(-9.0, -7.0), Vector2(11.0, 0.0), Vector2(-9.0, 7.0)])
	marker.color = Color(1.0, 0.78, 0.30, 0.95)
	root.add_child(marker)
	_apply_additive(root)

	var start_angle := SWEEP_ANGLE_MIN if from_left else SWEEP_ANGLE_MAX
	var end_angle := SWEEP_ANGLE_MAX if from_left else SWEEP_ANGLE_MIN
	var slide := root.create_tween().set_loops()
	slide.tween_method(
		func(t: float) -> void:
			if not is_instance_valid(marker):
				return
			var angle := deg_to_rad(lerpf(start_angle, end_angle, t))
			marker.position = Vector2(cos(angle), sin(angle)) * 210.0
			marker.rotation = angle,
		0.0, 1.0, duration * 0.55
	)
	slide.tween_interval(duration * 0.12)
	return root


# --------------------------------------------------
# 2) KRONO DUVARI - tek bosluklu kristal duvar
# --------------------------------------------------

func _run_wall_attack() -> void:
	signature_active = true
	if is_instance_valid(move_tween):
		move_tween.kill()
	_play_anim(&"charge_2")
	status_feedback.emit("KRONO DUVARI", &"exposed")

	var safe_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	var gap_x := _pick_wall_gap(safe_rect)
	var telegraph := _get_telegraph_duration()
	var mark := _spawn_wall_telegraph(safe_rect, gap_x, telegraph)
	await get_tree().create_timer(telegraph).timeout
	if is_instance_valid(mark):
		mark.queue_free()
	if not combat_active or not accepting_damage:
		signature_active = false
		return

	_play_anim(&"release_2")
	_shake_world(3.2)
	_spawn_wall(safe_rect, gap_x)
	_apply_wall_damage(gap_x)

	await get_tree().create_timer(WALL_RISE + WALL_HOLD).timeout
	signature_active = false
	_return_to_idle()


## Bosluk raketten UZAK secilir: oyuncunun kosmasi gerekiyor.
func _pick_wall_gap(safe_rect: Rect2) -> float:
	var min_x := safe_rect.position.x + WALL_GAP_HALF_WIDTH + 20.0
	var max_x := safe_rect.end.x - WALL_GAP_HALF_WIDTH - 20.0
	if max_x <= min_x:
		return safe_rect.get_center().x
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		return randf_range(min_x, max_x)
	var paddle_x: float = paddle.global_position.x
	var best := randf_range(min_x, max_x)
	var best_distance := -1.0
	for attempt in range(8):
		var candidate := randf_range(min_x, max_x)
		var distance := absf(candidate - paddle_x)
		if distance > best_distance:
			best_distance = distance
			best = candidate
	return best


func _get_wall_floor_y() -> float:
	return GameManager.get_gameplay_rect(get_viewport_rect().size).end.y - 26.0


func _spawn_wall_telegraph(safe_rect: Rect2, gap_x: float, duration: float) -> Node2D:
	var floor_y := _get_wall_floor_y()
	var root := Node2D.new()
	root.z_index = 6
	root.global_position = Vector2(0.0, floor_y)
	get_parent().add_child(root)

	# Tehlikeli bant: bosluk disindaki iki parca.
	for segment: Vector2 in [
		Vector2(safe_rect.position.x, gap_x - WALL_GAP_HALF_WIDTH),
		Vector2(gap_x + WALL_GAP_HALF_WIDTH, safe_rect.end.x),
	]:
		if segment.y - segment.x < 8.0:
			continue
		var band := Polygon2D.new()
		band.polygon = PackedVector2Array([
			Vector2(segment.x, -20.0), Vector2(segment.y, -20.0),
			Vector2(segment.y, 16.0), Vector2(segment.x, 16.0)
		])
		band.color = Color(0.95, 0.45, 0.12, 0.18)
		root.add_child(band)
		var pulse := band.create_tween().set_loops()
		pulse.tween_property(band, "color:a", 0.38, duration * 0.26)
		pulse.tween_property(band, "color:a", 0.16, duration * 0.22)

	# Guvenli bosluk: farkli renk, tersine okunacak sekilde vurgulaniyor.
	var gap := Polygon2D.new()
	gap.polygon = PackedVector2Array([
		Vector2(gap_x - WALL_GAP_HALF_WIDTH, -22.0), Vector2(gap_x + WALL_GAP_HALF_WIDTH, -22.0),
		Vector2(gap_x + WALL_GAP_HALF_WIDTH, 18.0), Vector2(gap_x - WALL_GAP_HALF_WIDTH, 18.0)
	])
	gap.color = Color(0.30, 0.72, 1.0, 0.26)
	root.add_child(gap)

	var gap_edge := Line2D.new()
	gap_edge.width = 2.8
	gap_edge.default_color = Color(0.45, 0.82, 1.0, 0.9)
	gap_edge.antialiased = true
	gap_edge.closed = true
	gap_edge.points = gap.polygon
	root.add_child(gap_edge)

	for index in range(3):
		var hint := Polygon2D.new()
		hint.polygon = PackedVector2Array([Vector2(-6.0, 0.0), Vector2(0.0, -30.0), Vector2(6.0, 0.0)])
		hint.color = Color(0.55, 0.88, 1.0, 0.0)
		hint.position = Vector2(gap_x + lerpf(-40.0, 40.0, float(index) / 2.0), -14.0)
		hint.rotation = PI
		root.add_child(hint)
		var blink := hint.create_tween().set_loops()
		blink.tween_interval(duration * 0.12 * float(index))
		blink.tween_property(hint, "color:a", 0.85, duration * 0.20)
		blink.tween_property(hint, "color:a", 0.0, duration * 0.20)

	_apply_additive(root)
	return root


func _spawn_wall(safe_rect: Rect2, gap_x: float) -> void:
	var floor_y := _get_wall_floor_y()
	var root := Node2D.new()
	root.z_index = 8
	root.global_position = Vector2(0.0, floor_y)
	get_parent().add_child(root)

	var x := safe_rect.position.x + WALL_TILE_WIDTH * 0.5
	while x < safe_rect.end.x:
		if absf(x - gap_x) > WALL_GAP_HALF_WIDTH + WALL_TILE_WIDTH * 0.60:
			_add_wall_tile(root, x)
		x += WALL_TILE_WIDTH

	root.scale.y = 0.05
	root.modulate.a = 0.0
	var rise := root.create_tween()
	rise.set_parallel(true)
	rise.tween_property(root, "scale:y", 1.0, WALL_RISE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rise.tween_property(root, "modulate:a", 1.0, WALL_RISE * 0.6)
	rise.chain().tween_interval(WALL_HOLD)
	rise.set_parallel(true)
	rise.tween_property(root, "modulate:a", 0.0, WALL_FADE)
	rise.tween_property(root, "scale:y", 0.15, WALL_FADE)
	rise.set_parallel(false)
	rise.tween_callback(root.queue_free)


func _add_wall_tile(root: Node2D, x: float) -> void:
	if wall_burst_texture != null:
		var tile := Sprite2D.new()
		tile.texture = wall_burst_texture
		tile.centered = false
		var target_height := randf_range(165.0, 205.0)
		# Yatay olcek dokunun kendi oranindan DEGIL, karo genisliginden
		# turetiliyor. Yoksa karolar birbirinin ustune tasip bosluğu
		# kapatiyordu ve duvar kesintisiz gorunuyordu.
		var factor_y := target_height / float(wall_burst_texture.get_height())
		var factor_x := (WALL_TILE_WIDTH * 1.12) / float(wall_burst_texture.get_width())
		tile.scale = Vector2(factor_x, factor_y)
		tile.position = Vector2(x - wall_burst_texture.get_width() * factor_x * 0.5, -target_height)
		root.add_child(tile)
		return
	for index in range(3):
		var spike := Polygon2D.new()
		var half := randf_range(12.0, 20.0)
		var height := randf_range(100.0, 175.0)
		spike.polygon = PackedVector2Array([
			Vector2(-half, 0.0), Vector2(0.0, -height), Vector2(half, 0.0)
		])
		spike.color = Color(0.32, 0.62, 1.0, 0.92) if index % 2 == 0 else Color(1.0, 0.58, 0.18, 0.92)
		spike.position.x = x + lerpf(-40.0, 40.0, float(index) / 2.0)
		root.add_child(spike)


func _apply_wall_damage(gap_x: float) -> void:
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		return
	# Bosluktaysa guvende; degilse duvar onu yakaliyor.
	if absf(paddle.global_position.x - gap_x) <= WALL_GAP_HALF_WIDTH:
		return
	var game_root := get_parent()
	if is_instance_valid(game_root) and game_root.has_method("apply_enemy_projectile_damage"):
		game_root.apply_enemy_projectile_damage()


func _spawn_defeat_burst() -> void:
	# Mandala cozuluyor: halkalar disari acilip sonuyor.
	for ring_index in range(3):
		var ring := Line2D.new()
		ring.width = 3.4
		ring.default_color = Color(1.0, 0.62, 0.20, 0.85) if ring_index % 2 == 0 else Color(0.38, 0.70, 1.0, 0.85)
		ring.antialiased = true
		ring.closed = true
		ring.material = _get_additive_material()
		var points := PackedVector2Array()
		var sides := 6 + ring_index * 2
		for index in range(sides):
			var angle := TAU * float(index) / float(sides)
			points.append(Vector2(cos(angle), sin(angle)) * 34.0)
		ring.points = points
		visual_root.add_child(ring)
		var open := ring.create_tween()
		open.tween_interval(0.07 * float(ring_index))
		open.set_parallel(true)
		open.tween_property(ring, "scale", Vector2.ONE * randf_range(3.4, 4.6), 0.60).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		open.tween_property(ring, "rotation", randf_range(-1.6, 1.6), 0.60)
		open.tween_property(ring, "modulate:a", 0.0, 0.62)
		open.chain().tween_callback(ring.queue_free)

	for index in range(14):
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([
			Vector2(0.0, -7.0), Vector2(13.0, 0.0), Vector2(0.0, 7.0), Vector2(-13.0, 0.0)
		])
		shard.color = Color(0.34, 0.66, 1.0, 0.9) if index % 2 == 0 else Color(1.0, 0.55, 0.16, 0.9)
		shard.material = _get_additive_material()
		var angle := TAU * float(index) / 14.0
		shard.rotation = angle
		visual_root.add_child(shard)
		var fly := shard.create_tween().set_parallel(true)
		fly.tween_property(shard, "position", Vector2.from_angle(angle) * randf_range(120.0, 190.0), 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fly.tween_property(shard, "modulate:a", 0.0, 0.64)
		fly.chain().tween_callback(shard.queue_free)
