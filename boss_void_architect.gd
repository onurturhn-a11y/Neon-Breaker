extends "res://boss_sprite_entity.gd"

# ==================================================
# THE VOID ARCHITECT - 6. progression boss (depth 48)
#
# Serinin son bossu. Gogsundeki bronz usturlap ve sirtindaki
# yikik sutunlar, cokmus bir kozmosun mimarini anlatiyor.
#
# Iki imza saldirisi, ikisi de onceki bosslardan farkli bir sey
# istiyor:
#
#   1) VOID KUYRUKLU YILDIZI - agir, yavas, ilk saniyede rakete
#      dogru hafif yonelen bir cisim. Kacilabilir ama yerinde
#      durursan yakalar; celestial/sovereign'in "sutundan kac"
#      mantigindan farkli olarak SUREKLI konum degistirmeni ister.
#   2) SUTUN PATLAMASI - tabandan iki DALGA halinde sutun firlar.
#      Ilk dalganin bosluklari ikinci dalgada hedef oluyor, yani
#      bir kere kacmak yetmiyor.
#
# Ortak iskelet icin boss_sprite_entity.gd'ye bak.
# ==================================================

const COMET_SCENE = preload("res://void_comet.tscn")

const PILLAR_ZONE_HALF_WIDTH := 58.0
const PILLAR_RISE := 0.20
const PILLAR_HOLD := 0.38
const PILLAR_FADE := 0.24

var pillar_burst_texture: Texture2D
var pillar_shards_texture: Texture2D
var effect_textures_loaded := false
var next_attack := 0


func _get_boss_label() -> String:
	return "THE VOID ARCHITECT"


func _get_base_hp() -> int:
	return 410


func _get_extra_group() -> StringName:
	return &"void_architect_boss"


func _get_frame_dir() -> String:
	return "res://assets/bosses/void_architect/"


func _get_shard_texture_path() -> String:
	return "res://assets/bosses/void/shard_projectile.png"


func _get_target_sprite_height() -> float:
	return 230.0


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
	return 0.30


func _get_enrage_message() -> String:
	return "MİMAR UYANDI"


func _get_phase_message(phase: int) -> String:
	return "MİMAR FAZ %d" % phase


func _get_telegraph_duration() -> float:
	if current_phase >= 3:
		return 0.78
	if current_phase == 2:
		return 0.92
	return 1.08


func _get_attack_interval() -> float:
	if current_phase >= 3:
		return randf_range(3.9, 4.5)
	if current_phase == 2:
		return randf_range(4.9, 5.5)
	return randf_range(5.9, 6.5)


func _load_effect_textures() -> void:
	if effect_textures_loaded:
		return
	effect_textures_loaded = true
	var burst := _get_frame_dir() + "spike_burst.png"
	var shards := _get_frame_dir() + "spike_shards.png"
	if ResourceLoader.exists(burst):
		pillar_burst_texture = load(burst) as Texture2D
	if ResourceLoader.exists(shards):
		pillar_shards_texture = load(shards) as Texture2D


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
			await _run_comet_attack()
		else:
			await _run_pillar_attack()
		next_attack = 1 - next_attack


# --------------------------------------------------
# 1) VOID KUYRUKLU YILDIZI
# --------------------------------------------------

func _get_comet_count() -> int:
	if current_phase >= 3:
		return 3
	return 1 if current_phase == 1 else 2


func _run_comet_attack() -> void:
	signature_active = true
	if is_instance_valid(move_tween):
		move_tween.kill()
	_play_anim(&"charge")
	status_feedback.emit("VOID ÇEKİRDEĞİ", &"exposed")

	var telegraph := _get_telegraph_duration()
	var mark := _spawn_comet_telegraph(telegraph)
	await get_tree().create_timer(telegraph).timeout
	if is_instance_valid(mark):
		mark.queue_free()
	if not combat_active or not accepting_damage:
		signature_active = false
		return

	_play_anim(&"release")
	_shake_world(2.8)
	var count := _get_comet_count()
	for index in range(count):
		_spawn_comet(index, count)
		if index < count - 1:
			await get_tree().create_timer(0.28).timeout
			if not combat_active or not accepting_damage:
				break

	await get_tree().create_timer(0.45).timeout
	signature_active = false
	_return_to_idle()


func _spawn_comet_telegraph(duration: float) -> Node2D:
	var flare := Node2D.new()
	flare.z_index = 9
	flare.global_position = to_global(Vector2(54.0, 8.0))
	get_parent().add_child(flare)

	_add_sprite(flare, _get_beam_blob_texture(), Color(0.18, 0.74, 0.82, 0.75), Vector2.ZERO, Vector2(96.0, 96.0))
	var core := Polygon2D.new()
	var points := PackedVector2Array()
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * 12.0)
	core.polygon = points
	core.color = Color(0.02, 0.03, 0.06, 1.0)
	flare.add_child(core)

	_apply_additive(flare)
	core.material = null   # cekirdek void: toplamali olursa karanligi kayboluyor
	flare.scale = Vector2.ONE * 0.25
	var grow := flare.create_tween()
	grow.tween_property(flare, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return flare


func _spawn_comet(index: int, count: int) -> void:
	var comet = COMET_SCENE.instantiate()
	get_parent().add_child(comet)
	comet.global_position = to_global(Vector2(54.0, 8.0))
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	var aim := Vector2.DOWN
	if is_instance_valid(paddle):
		aim = (paddle.global_position - comet.global_position).normalized()
	# Birden fazlaysa yelpaze halinde: aralarindan gecilebilsin.
	var spread := 0.0 if count <= 1 else lerpf(-24.0, 24.0, float(index) / float(count - 1))
	comet.setup(get_parent(), aim.rotated(deg_to_rad(spread)))
	if get_parent().has_method("notify_boss_projectile_fired"):
		get_parent().notify_boss_projectile_fired()


# --------------------------------------------------
# 2) SUTUN PATLAMASI - iki dalga
# --------------------------------------------------

func _run_pillar_attack() -> void:
	signature_active = true
	if is_instance_valid(move_tween):
		move_tween.kill()
	_play_anim(&"charge_2")
	status_feedback.emit("SÜTUN PATLAMASI", &"exposed")

	var first := _pick_pillar_zones([])
	var telegraph := _get_telegraph_duration()
	var marks: Array[Node2D] = []
	for zone_x: float in first:
		marks.append(_spawn_pillar_telegraph(zone_x, telegraph))
	await get_tree().create_timer(telegraph).timeout
	for mark: Node2D in marks:
		if is_instance_valid(mark):
			mark.queue_free()
	if not combat_active or not accepting_damage:
		signature_active = false
		return

	_play_anim(&"release_2")
	_shake_world(3.0)
	for zone_x: float in first:
		_spawn_pillar(zone_x)
	_apply_pillar_damage(first)

	# Ikinci dalga ilk dalganin BOSLUKLARINI hedefliyor: bir kere kacmak yetmez.
	await get_tree().create_timer(PILLAR_RISE + PILLAR_HOLD * 0.7).timeout
	if not combat_active or not accepting_damage:
		signature_active = false
		return
	var second := _pick_pillar_zones(first)
	var second_marks: Array[Node2D] = []
	for zone_x: float in second:
		second_marks.append(_spawn_pillar_telegraph(zone_x, 0.55))
	await get_tree().create_timer(0.55).timeout
	for mark: Node2D in second_marks:
		if is_instance_valid(mark):
			mark.queue_free()
	if combat_active and accepting_damage:
		_shake_world(3.0)
		for zone_x: float in second:
			_spawn_pillar(zone_x)
		_apply_pillar_damage(second)

	await get_tree().create_timer(PILLAR_RISE + PILLAR_HOLD).timeout
	signature_active = false
	_return_to_idle()


## `avoid` dolu ise o bolgelerin ARASINA yerlesir (ikinci dalga icin).
func _pick_pillar_zones(avoid: Array[float]) -> Array[float]:
	var safe_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	var min_x := safe_rect.position.x + PILLAR_ZONE_HALF_WIDTH
	var max_x := safe_rect.end.x - PILLAR_ZONE_HALF_WIDTH
	var zones: Array[float] = []
	if max_x <= min_x:
		zones.append(safe_rect.get_center().x)
		return zones

	var separation := PILLAR_ZONE_HALF_WIDTH * 2.8
	var count := 3 if current_phase >= 3 else 2
	if avoid.is_empty():
		var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
		if is_instance_valid(paddle):
			zones.append(clampf(paddle.global_position.x, min_x, max_x))
		else:
			zones.append(safe_rect.get_center().x)

	var guard := 0
	while zones.size() < count and guard < 80:
		guard += 1
		var candidate := randf_range(min_x, max_x)
		var too_close := false
		for existing: float in zones:
			if absf(existing - candidate) < separation:
				too_close = true
				break
		if not too_close and not avoid.is_empty():
			# Ikinci dalga: ilk dalganin sutunlarindan UZAK, yani bosluklarda.
			var near_first := false
			for previous: float in avoid:
				if absf(previous - candidate) < separation * 0.8:
					near_first = true
					break
			too_close = near_first
		if not too_close:
			zones.append(candidate)
	if zones.is_empty():
		zones.append((min_x + max_x) * 0.5)
	return zones


func _get_pillar_floor_y() -> float:
	return GameManager.get_gameplay_rect(get_viewport_rect().size).end.y - 26.0


func _spawn_pillar_telegraph(zone_x: float, duration: float) -> Node2D:
	var root := Node2D.new()
	root.z_index = 6
	root.global_position = Vector2(zone_x, _get_pillar_floor_y())
	get_parent().add_child(root)

	var points := PackedVector2Array()
	for index in range(20):
		var angle := TAU * float(index) / 20.0
		points.append(Vector2(cos(angle) * PILLAR_ZONE_HALF_WIDTH, sin(angle) * 19.0))
	var pad := Polygon2D.new()
	pad.polygon = points
	pad.color = Color(0.26, 0.88, 0.90, 0.20)
	root.add_child(pad)

	var edge := Line2D.new()
	edge.points = points
	edge.closed = true
	edge.width = 2.4
	edge.default_color = Color(0.45, 1.0, 0.96, 0.80)
	edge.antialiased = true
	root.add_child(edge)

	for index in range(3):
		var hint := Polygon2D.new()
		hint.polygon = PackedVector2Array([Vector2(-5.0, 0.0), Vector2(0.0, -30.0), Vector2(5.0, 0.0)])
		hint.color = Color(0.55, 1.0, 0.98, 0.0)
		hint.position.x = lerpf(-PILLAR_ZONE_HALF_WIDTH * 0.55, PILLAR_ZONE_HALF_WIDTH * 0.55, float(index) / 2.0)
		root.add_child(hint)
		var pulse := hint.create_tween().set_loops()
		pulse.tween_interval(duration * 0.14 * float(index))
		pulse.tween_property(hint, "color:a", 0.85, duration * 0.20)
		pulse.tween_property(hint, "color:a", 0.0, duration * 0.20)

	_apply_additive(root)
	var grow := root.create_tween()
	grow.tween_property(pad, "color:a", 0.36, duration)
	return root


func _spawn_pillar(zone_x: float) -> void:
	var root := Node2D.new()
	root.z_index = 8
	root.global_position = Vector2(zone_x, _get_pillar_floor_y())
	get_parent().add_child(root)

	if pillar_burst_texture != null:
		var burst := Sprite2D.new()
		burst.texture = pillar_burst_texture
		burst.centered = false
		var target_height := 200.0
		var factor := target_height / float(pillar_burst_texture.get_height())
		burst.scale = Vector2.ONE * factor
		burst.position = Vector2(-pillar_burst_texture.get_width() * factor * 0.5, -target_height)
		root.add_child(burst)
	else:
		for index in range(4):
			var pillar := Polygon2D.new()
			var half := randf_range(11.0, 18.0)
			var height := randf_range(95.0, 170.0)
			pillar.polygon = PackedVector2Array([
				Vector2(-half, 0.0), Vector2(-half * 0.6, -height), Vector2(half * 0.6, -height), Vector2(half, 0.0)
			])
			pillar.color = Color(0.30, 0.90, 0.92, 0.92)
			pillar.position.x = lerpf(-PILLAR_ZONE_HALF_WIDTH * 0.8, PILLAR_ZONE_HALF_WIDTH * 0.8, float(index) / 3.0)
			root.add_child(pillar)

	if pillar_shards_texture != null:
		var shards := Sprite2D.new()
		shards.texture = pillar_shards_texture
		shards.modulate = Color(1.0, 1.0, 1.0, 0.80)
		var shard_factor := 140.0 / float(pillar_shards_texture.get_height())
		shards.scale = Vector2.ONE * shard_factor
		shards.position = Vector2(0.0, -78.0)
		root.add_child(shards)

	root.scale.y = 0.05
	root.modulate.a = 0.0
	var rise := root.create_tween()
	rise.set_parallel(true)
	rise.tween_property(root, "scale:y", 1.0, PILLAR_RISE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rise.tween_property(root, "modulate:a", 1.0, PILLAR_RISE * 0.6)
	rise.chain().tween_interval(PILLAR_HOLD)
	rise.set_parallel(true)
	rise.tween_property(root, "modulate:a", 0.0, PILLAR_FADE)
	rise.tween_property(root, "scale:y", 0.15, PILLAR_FADE)
	rise.set_parallel(false)
	rise.tween_callback(root.queue_free)


func _apply_pillar_damage(zones: Array[float]) -> void:
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		return
	var paddle_half := _get_paddle_half_width(paddle)
	for zone_x: float in zones:
		if absf(paddle.global_position.x - zone_x) > PILLAR_ZONE_HALF_WIDTH + paddle_half:
			continue
		var game_root := get_parent()
		if is_instance_valid(game_root) and game_root.has_method("apply_enemy_projectile_damage"):
			game_root.apply_enemy_projectile_damage()
		return


func _spawn_defeat_burst() -> void:
	# Mimarin yapisi cokuyor: parcalar once disari savruluyor, sonra iceri.
	for index in range(20):
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([
			Vector2(0.0, -8.0), Vector2(14.0, 0.0), Vector2(0.0, 8.0), Vector2(-14.0, 0.0)
		])
		shard.color = Color(0.45, 1.0, 0.96, 0.9) if index % 3 == 0 else Color(0.42, 0.32, 0.22, 0.9)
		shard.material = _get_additive_material() if index % 3 == 0 else null
		var angle := TAU * float(index) / 20.0
		shard.rotation = angle
		visual_root.add_child(shard)
		var collapse := shard.create_tween()
		collapse.tween_property(shard, "position", Vector2.from_angle(angle) * randf_range(110.0, 175.0), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		collapse.set_parallel(true)
		collapse.tween_property(shard, "position", Vector2.ZERO, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		collapse.tween_property(shard, "modulate:a", 0.0, 0.48)
		collapse.set_parallel(false)
		collapse.tween_callback(shard.queue_free)


func _defeat() -> void:
	for comet: Node in get_tree().get_nodes_in_group("void_comet"):
		if is_instance_valid(comet):
			comet.queue_free()
	super()
