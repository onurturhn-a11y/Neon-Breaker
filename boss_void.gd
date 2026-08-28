extends "res://boss_sprite_entity.gd"

# ==================================================
# THE VOID ENTITY - 4. progression boss (depth 32)
#
# Imza mekanigi: tekillik. Boss elinde bir kara delik sarj eder
# ve oyun alanina birakir. Tekillik menzilindeki toplarin
# yorungesini kendine dogru kivirir - top yavaslamaz, kontrol
# edilmesi zorlasir. Faz ilerledikce ayni anda birden fazla
# tekillik aciliyor.
#
# Ortak iskelet (poz harmanlama, hareket, hasar, fazlar) icin
# boss_sprite_entity.gd'ye bak.
# ==================================================

const SINGULARITY_SCENE = preload("res://void_singularity.tscn")
const SINGULARITY_LIFETIME := 3.0
const SINGULARITY_RADIUS := 135.0
## Iki tekillik arasindaki en kucuk mesafe: aralarinda gecis kalsin.
const SINGULARITY_MIN_SEPARATION := 215.0


func _get_boss_label() -> String:
	return "THE VOID ENTITY"


func _get_base_hp() -> int:
	return 260


func _get_extra_group() -> StringName:
	return &"void_boss"


func _get_frame_dir() -> String:
	return "res://assets/bosses/void/"


func _get_shard_texture_path() -> String:
	return "res://assets/bosses/void/shard_projectile.png"


func _get_target_sprite_height() -> float:
	return 210.0


func _get_projectile_palette() -> Array:
	return [
		Color(0.30, 0.96, 0.94, 1.0),
		Color(0.55, 1.00, 0.92, 1.0),
		Color(0.80, 1.00, 1.00, 1.0),
	]


func _get_core_glow_alpha_scale() -> float:
	return 0.22


func _get_enrage_message() -> String:
	return "BOŞLUK YUTUYOR"


func _get_phase_message(phase: int) -> String:
	return "TEKİLLİK FAZ %d" % phase


func _get_telegraph_duration() -> float:
	if current_phase >= 3:
		return 0.85
	if current_phase == 2:
		return 1.00
	return 1.15


func _get_singularity_interval() -> float:
	if current_phase >= 3:
		return randf_range(4.4, 5.0)
	if current_phase == 2:
		return randf_range(5.4, 6.0)
	return randf_range(6.4, 7.0)


func _get_singularity_count() -> int:
	return 1 if current_phase == 1 else 2


func _get_singularity_lifetime() -> float:
	return SINGULARITY_LIFETIME + (0.8 if current_phase >= 3 else 0.0)


# ==================================================
# IMZA SALDIRISI
# ==================================================

func _signature_loop() -> void:
	await get_tree().create_timer(2.2).timeout
	while combat_active and accepting_damage:
		await get_tree().create_timer(_get_singularity_interval()).timeout
		if not combat_active or not accepting_damage:
			return
		await _run_singularity_attack()


func _run_singularity_attack() -> void:
	signature_active = true
	if is_instance_valid(move_tween):
		move_tween.kill()
	_play_anim(&"charge")
	status_feedback.emit("TEKİLLİK ŞARJI", &"exposed")

	var targets := _pick_singularity_targets(_get_singularity_count())
	var telegraph := _get_telegraph_duration()
	var marks: Array[Node2D] = []
	for target: Vector2 in targets:
		marks.append(_spawn_singularity_telegraph(target, telegraph))
	await get_tree().create_timer(telegraph).timeout
	for mark: Node2D in marks:
		if is_instance_valid(mark):
			mark.queue_free()
	if not combat_active or not accepting_damage:
		signature_active = false
		return

	_play_anim(&"release")
	_spawn_hand_burst()
	_shake_world(2.2 + 0.6 * float(targets.size()))
	for target: Vector2 in targets:
		_spawn_singularity(target)

	await get_tree().create_timer(0.55).timeout
	signature_active = false
	_return_to_idle()


func _pick_singularity_targets(count: int) -> Array[Vector2]:
	var safe_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	var margin := SINGULARITY_RADIUS * 0.55
	var min_x := safe_rect.position.x + margin
	var max_x := safe_rect.end.x - margin
	# Tekillikler ne rakete yapissin ne de bossun dibinde acilsin.
	var min_y := global_position.y + 150.0
	var max_y := safe_rect.end.y - 210.0
	var targets: Array[Vector2] = []
	if max_x <= min_x or max_y <= min_y:
		targets.append(safe_rect.get_center())
		return targets
	var guard := 0
	while targets.size() < count and guard < 60:
		guard += 1
		var candidate := Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))
		var too_close := false
		for existing: Vector2 in targets:
			if existing.distance_to(candidate) < SINGULARITY_MIN_SEPARATION:
				too_close = true
				break
		if not too_close:
			targets.append(candidate)
	if targets.is_empty():
		targets.append(Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5))
	return targets


func _spawn_singularity_telegraph(target: Vector2, duration: float) -> Node2D:
	var root := Node2D.new()
	root.z_index = 6
	root.global_position = target
	get_parent().add_child(root)

	var ring := Line2D.new()
	ring.width = 2.4
	ring.default_color = Color(0.40, 1.0, 0.96, 0.75)
	ring.antialiased = true
	ring.material = _get_additive_material()
	var points := PackedVector2Array()
	for index in range(29):
		var angle := TAU * float(index) / 28.0
		points.append(Vector2(cos(angle), sin(angle)) * SINGULARITY_RADIUS)
	ring.points = points
	root.add_child(ring)

	# Disaridan merkeze cekilen isaretciler: nereye acilacagi okunur.
	var count := 6 if OS.has_feature("mobile") else 10
	for index in range(count):
		var mote := Polygon2D.new()
		mote.polygon = PackedVector2Array([
			Vector2(0.0, -3.0), Vector2(9.0, 0.0), Vector2(0.0, 3.0), Vector2(-9.0, 0.0)
		])
		mote.color = Color(0.45, 1.0, 0.96, 0.0)
		mote.material = _get_additive_material()
		var angle := TAU * float(index) / float(count)
		mote.position = Vector2.from_angle(angle) * SINGULARITY_RADIUS * 1.05
		mote.rotation = angle + PI
		root.add_child(mote)
		var pull := mote.create_tween().set_loops()
		pull.tween_property(mote, "color:a", 0.85, duration * 0.22)
		pull.parallel().tween_property(mote, "position", Vector2.from_angle(angle) * SINGULARITY_RADIUS * 0.30, duration * 0.42)
		pull.tween_property(mote, "color:a", 0.0, duration * 0.16)
		pull.parallel().tween_property(mote, "position", Vector2.from_angle(angle) * SINGULARITY_RADIUS * 1.05, 0.01)

	root.scale = Vector2.ONE * 0.55
	var grow := root.create_tween()
	grow.tween_property(root, "scale", Vector2.ONE, duration * 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return root


func _spawn_singularity(target: Vector2) -> void:
	var well = SINGULARITY_SCENE.instantiate()
	well.radius = SINGULARITY_RADIUS
	well.lifetime = _get_singularity_lifetime()
	well.turn_rate = 3.4 if current_phase >= 3 else 3.0
	get_parent().add_child(well)
	well.global_position = target


func _spawn_hand_burst() -> void:
	var burst := Node2D.new()
	burst.z_index = 9
	burst.global_position = to_global(Vector2(52.0, 6.0))
	get_parent().add_child(burst)

	_add_sprite(burst, _get_beam_blob_texture(), Color(0.32, 0.96, 0.94, 0.85), Vector2.ZERO, Vector2(140.0, 140.0))
	_add_sprite(burst, _get_beam_blob_texture(), Color(0.90, 1.00, 1.00, 0.95), Vector2.ZERO, Vector2(46.0, 46.0))
	for index in range(7):
		var streak := Line2D.new()
		streak.width = 2.4
		streak.default_color = Color(0.45, 1.0, 0.96, 0.85)
		streak.antialiased = true
		var angle := TAU * float(index) / 7.0 + randf_range(-0.2, 0.2)
		streak.points = PackedVector2Array([Vector2.ZERO, Vector2.from_angle(angle) * randf_range(30.0, 58.0)])
		burst.add_child(streak)

	_apply_additive(burst)
	burst.scale = Vector2.ONE * 0.4
	var tween := burst.create_tween().set_parallel(true)
	tween.tween_property(burst, "scale", Vector2.ONE * 1.3, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(burst, "modulate:a", 0.0, 0.28)
	tween.chain().tween_callback(burst.queue_free)


func _spawn_defeat_burst() -> void:
	# Kristal bossun aksine parcalar disari savrulmuyor, iceri cokuyor.
	for index in range(16):
		var mote := Polygon2D.new()
		mote.polygon = PackedVector2Array([
			Vector2(0.0, -6.0), Vector2(11.0, 0.0), Vector2(0.0, 6.0), Vector2(-11.0, 0.0)
		])
		mote.color = Color(0.42, 1.0, 0.96, 0.9) if index % 2 == 0 else Color(0.20, 0.62, 0.80, 0.85)
		mote.material = _get_additive_material()
		var angle := TAU * float(index) / 16.0
		mote.position = Vector2.from_angle(angle) * randf_range(90.0, 150.0)
		mote.rotation = angle
		visual_root.add_child(mote)
		var suck := mote.create_tween().set_parallel(true)
		suck.tween_property(mote, "position", Vector2.ZERO, randf_range(0.40, 0.62)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		suck.tween_property(mote, "rotation", angle + randf_range(-2.5, 2.5), 0.60)
		suck.tween_property(mote, "modulate:a", 0.0, 0.66)
		suck.chain().tween_callback(mote.queue_free)


func _defeat() -> void:
	# Yenilirken acik kalan tekillikleri de kapat.
	for well: Node in get_tree().get_nodes_in_group("void_singularity"):
		if is_instance_valid(well):
			well.queue_free()
	super()
