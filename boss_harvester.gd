extends "res://boss_sprite_entity.gd"

# ==================================================
# THE HARVESTER - yeni boss (kadro sirasi 3)
#
# Imza mekanigi: yem. Boss tehlike hattina en yakin tuglalari sahadan
# sokup aliyor ve govdesine zirh plakasi olarak perciniyor. Yani yemesine
# izin vermek anlik bir can simidi (saha nefes aliyor) ama uzun vadede
# daha kalin bir boss. Karar oyuncunun: yarismak mi, nefes almak mi.
#
# SENTINEL'den farki: plakalar hasari KAPATMIYOR, yalnizca azaltiyor.
# Boss her an vurulabilir; jenerator gibi bir pencere beklemek yok.
#
# Ortak iskelet (poz harmanlama, hareket, hasar, fazlar) icin
# boss_sprite_entity.gd'ye bak.
# ==================================================

## Plakanin emdigi hasar orani ve kirilmadan once dayandigi isabet sayisi.
const PLATE_ABSORB := 0.40
const PLATE_HITS := 2

const PLATE_RADIUS := 74.0
const PLATE_SIZE := Vector2(34.0, 22.0)
const PLATE_TEXTURE_PATH := "res://assets/bricks/brick_cyan.png"

## Kusulan tugla raket hizasinda kac parcaya ayrilir.
const SPIT_FRAGMENTS := 4
const SPIT_SPEED_SCALE := 0.62

var plates: Array[Dictionary] = []
var plate_root: Node2D
var plate_spin := 0.0
var plate_texture: Texture2D
var plate_texture_loaded := false
var starving_burst_done := false


func _get_boss_label() -> String:
	return "THE HARVESTER"


func _get_base_hp() -> int:
	return 175


func _get_extra_group() -> StringName:
	return &"harvester_boss"


func _get_frame_dir() -> String:
	return "res://assets/bosses/harvester/"


func _get_target_sprite_height() -> float:
	return 215.0


func _get_frame_sets() -> Dictionary:
	var sets := FRAME_SETS.duplicate(true)
	sets[&"charge_2"] = ["charge_2.png"]
	sets[&"release_2"] = ["release_2.png"]
	return sets


## Pas turuncusu: kadronun tek sicak metali.
func _get_projectile_palette() -> Array:
	return [
		Color(1.00, 0.54, 0.17, 1.0),
		Color(1.00, 0.72, 0.28, 1.0),
		Color(1.00, 0.90, 0.62, 1.0),
	]


func _get_enrage_message() -> String:
	return "AÇ KALDI"


func _get_phase_message(phase: int) -> String:
	return "HASAT FAZ %d" % phase


func _get_telegraph_duration() -> float:
	return 0.70 if current_phase >= 2 else 0.85


func _get_harvest_count() -> int:
	return 5 if current_phase >= 2 else 3


func _get_harvest_interval() -> float:
	if current_phase >= 3:
		return randf_range(4.4, 5.0)
	if current_phase == 2:
		return randf_range(5.0, 5.6)
	return randf_range(6.2, 6.8)


func _get_plate_cap() -> int:
	return 5 if current_phase >= 2 else 3


func _ready() -> void:
	super()
	plate_root = Node2D.new()
	plate_root.name = "PlateRoot"
	visual_root.add_child(plate_root)


func _get_plate_texture() -> Texture2D:
	if not plate_texture_loaded:
		plate_texture_loaded = true
		if ResourceLoader.exists(PLATE_TEXTURE_PATH):
			plate_texture = load(PLATE_TEXTURE_PATH) as Texture2D
	return plate_texture


# ==================================================
# ZIRH PLAKALARI
# ==================================================

## Plakalar govdenin cevresinde yorungede duruyor. Faz 2'den itibaren
## donuyorlar - sabit bir noktadan vurmak artik ise yaramasin diye.
func _physics_process(delta: float) -> void:
	super(delta)
	if plates.is_empty() or not is_instance_valid(plate_root):
		return
	if current_phase >= 2:
		plate_spin += deg_to_rad(18.0) * delta
	_layout_plates()


func _layout_plates() -> void:
	var n := plates.size()
	for i in range(n):
		var node: Node2D = plates[i].get("node")
		if not is_instance_valid(node):
			continue
		var angle := plate_spin + TAU * float(i) / float(maxi(n, 1)) - PI * 0.5
		node.position = Vector2(cos(angle), sin(angle) * 0.62) * PLATE_RADIUS
		node.rotation = angle + PI * 0.5


func _add_plate() -> void:
	if plates.size() >= _get_plate_cap():
		return
	var node := Node2D.new()
	plate_root.add_child(node)
	var tex := _get_plate_texture()
	if tex != null:
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.scale = PLATE_SIZE / Vector2(maxf(tex.get_width(), 1.0), maxf(tex.get_height(), 1.0))
		node.add_child(sprite)
	else:
		var poly := Polygon2D.new()
		poly.color = Color(0.32, 0.92, 0.96, 0.92)
		poly.polygon = PackedVector2Array([
			Vector2(-PLATE_SIZE.x * 0.5, -PLATE_SIZE.y * 0.5),
			Vector2(PLATE_SIZE.x * 0.5, -PLATE_SIZE.y * 0.5),
			Vector2(PLATE_SIZE.x * 0.5, PLATE_SIZE.y * 0.5),
			Vector2(-PLATE_SIZE.x * 0.5, PLATE_SIZE.y * 0.5),
		])
		node.add_child(poly)
	var edge := Line2D.new()
	edge.width = 2.0
	edge.default_color = Color(0.42, 0.98, 1.00, 0.85)
	edge.points = PackedVector2Array([
		Vector2(-PLATE_SIZE.x * 0.5, -PLATE_SIZE.y * 0.5),
		Vector2(PLATE_SIZE.x * 0.5, -PLATE_SIZE.y * 0.5),
		Vector2(PLATE_SIZE.x * 0.5, PLATE_SIZE.y * 0.5),
		Vector2(-PLATE_SIZE.x * 0.5, PLATE_SIZE.y * 0.5),
		Vector2(-PLATE_SIZE.x * 0.5, -PLATE_SIZE.y * 0.5),
	])
	node.add_child(edge)
	node.scale = Vector2.ZERO
	var pop := node.create_tween()
	pop.tween_property(node, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	plates.append({"node": node, "hits": PLATE_HITS})
	_layout_plates()


func _break_plate() -> void:
	if plates.is_empty():
		return
	var plate: Dictionary = plates.pop_back()
	var node: Node2D = plate.get("node")
	if not is_instance_valid(node):
		return
	var shatter := node.create_tween().set_parallel(true)
	shatter.tween_property(node, "scale", Vector2(1.6, 1.6), 0.22)
	shatter.tween_property(node, "modulate:a", 0.0, 0.22)
	shatter.chain().tween_callback(node.queue_free)


## Plakalar hasari azaltir ama kesmez: her isabette ustteki plaka bir
## dayanikliligini kaybeder, hasarin %40'i emilir.
func _apply_region_hit(region: StringName, source: StringName, attacker_id: int, hit_position: Vector2) -> void:
	if plates.is_empty() or not accepting_damage:
		super(region, source, attacker_id, hit_position)
		return
	var before := current_hp
	super(region, source, attacker_id, hit_position)
	var dealt := before - current_hp
	if dealt <= 0:
		return
	# Emilen payi geri ver, sonra plakayi yipratf.
	current_hp = mini(current_hp + int(round(float(dealt) * PLATE_ABSORB)), max_hp)
	health_changed.emit(current_hp, max_hp)
	var top: Dictionary = plates[plates.size() - 1]
	top["hits"] = int(top.get("hits", PLATE_HITS)) - 1
	if int(top["hits"]) <= 0:
		_break_plate()


# ==================================================
# IMZA SALDIRILARI
# ==================================================

func _signature_loop() -> void:
	await get_tree().create_timer(2.3).timeout
	while combat_active and accepting_damage:
		await get_tree().create_timer(_get_harvest_interval()).timeout
		if not combat_active or not accepting_damage:
			return
		if current_phase >= 3 and not starving_burst_done and plates.size() >= 2:
			await _run_starving_burst()
			continue
		if plates.is_empty():
			await _run_harvest()
		else:
			await _run_spit()


## Hasat: tehlike hattina en yakin tuglalari sokup al, her biri bir plaka.
func _run_harvest() -> void:
	signature_active = true
	if is_instance_valid(move_tween):
		move_tween.kill()
	_play_anim(&"charge")
	status_feedback.emit("HASAT", &"exposed")
	await get_tree().create_timer(_get_telegraph_duration()).timeout
	if not combat_active or not accepting_damage:
		signature_active = false
		return
	_play_anim(&"release")
	var field := get_parent().get_node_or_null("BrickField")
	var taken := 0
	if is_instance_valid(field) and field.has_method("harvest_lowest_bricks"):
		taken = field.harvest_lowest_bricks(_get_harvest_count())
	for i in range(taken):
		_add_plate()
		await get_tree().create_timer(0.06).timeout
	if taken == 0:
		status_feedback.emit("SAHA BOŞ", &"shield")
	_shake_world(4.0)
	await get_tree().create_timer(0.45).timeout
	_return_to_idle()
	signature_active = false


## Kusma: bir plakayi yakit yapip agir ve yavas bir mermi atar.
func _run_spit() -> void:
	signature_active = true
	if is_instance_valid(move_tween):
		move_tween.kill()
	_play_anim(&"charge_2")
	status_feedback.emit("KUSMA", &"exposed")
	await get_tree().create_timer(_get_telegraph_duration()).timeout
	if not combat_active or not accepting_damage:
		signature_active = false
		return
	_play_anim(&"release_2")
	_spit_plate()
	_break_plate()
	_shake_world(3.0)
	await get_tree().create_timer(0.42).timeout
	_return_to_idle()
	signature_active = false


## Ac kalma: elindeki tum plakalari pes pese kusar, sonra savunmasiz kalir.
## Dovusun en acik hasar penceresi - ama oyuncunun sahasi ayni anda dolar.
func _run_starving_burst() -> void:
	starving_burst_done = true
	signature_active = true
	if is_instance_valid(move_tween):
		move_tween.kill()
	_play_anim(&"charge_2")
	status_feedback.emit("AÇ KALDI", &"exposed")
	await get_tree().create_timer(0.8).timeout
	if not combat_active or not accepting_damage:
		signature_active = false
		return
	while not plates.is_empty() and combat_active and accepting_damage:
		_play_anim(&"release_2")
		_spit_plate()
		_break_plate()
		await get_tree().create_timer(0.35).timeout
	_shake_world(6.0)
	status_feedback.emit("SAVUNMASIZ", &"shield")
	_play_anim(&"hit")
	await get_tree().create_timer(2.4).timeout
	_return_to_idle()
	signature_active = false


## Firlatilan sey GERCEKTEN tugla gorunmeli.
##
## Onceden mermi dokusu verilmiyordu ve THE CORE'un varsayilan turuncu
## sarapneline dusuyordu - mekanik dogruydu ama ekranda "blok firlatiyor"
## diye okunmuyordu. Artik plakalarin dokusunun aynisi kullaniliyor:
## bossun YEDIGI sey, USTUNDE TASIDIGI sey ve FIRLATTIGI sey ayni.
##
## heavy_visual: mermiye agirlik veren hazir bayrak (glow/bolt/core buyur,
## turuncuya kayar). Pas makinesinin firlatgi kizgin blok icin birebir.
func _spit_plate() -> void:
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		return
	var projectile: Node2D = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = to_global(Vector2(0.0, 40.0))
	var dir := (paddle.global_position - projectile.global_position).normalized()
	projectile.setup(get_parent(), dir, projectile_speed * SPIT_SPEED_SCALE, true)
	var palette := _get_projectile_palette()
	if projectile.has_method("apply_palette") and palette.size() >= 3:
		projectile.apply_palette(_get_plate_texture(), palette[0], palette[1], palette[2])
	if get_parent().has_method("notify_boss_projectile_fired"):
		get_parent().notify_boss_projectile_fired()
	_schedule_fragments(projectile, paddle)


## Mermi raket hizasina yaklasinca parcalara ayrilir.
func _schedule_fragments(projectile: Node2D, paddle: Node2D) -> void:
	var travel := absf(paddle.global_position.y - projectile.global_position.y)
	var speed := maxf(projectile_speed * SPIT_SPEED_SCALE, 1.0)
	var delay := maxf(travel / speed - 0.18, 0.15)
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		if not is_instance_valid(projectile) or not combat_active:
			return
		var origin := projectile.global_position
		projectile.queue_free()
		var palette := _get_projectile_palette()
		for i in range(SPIT_FRAGMENTS):
			var spread := lerpf(-0.72, 0.72, float(i) / float(maxi(SPIT_FRAGMENTS - 1, 1)))
			var frag: Node2D = PROJECTILE_SCENE.instantiate()
			get_parent().add_child(frag)
			frag.global_position = origin
			frag.setup(get_parent(), Vector2(sin(spread), cos(spread) * 0.55).normalized(), projectile_speed * 0.9)
			frag.scale = Vector2(0.7, 0.7)
			if frag.has_method("apply_palette") and palette.size() >= 3:
				# Parcalar da ayni dokudan: blogun kirilmis hali.
				frag.apply_palette(_get_plate_texture(), palette[0], palette[1], palette[2])
	)


func _spawn_defeat_burst() -> void:
	while not plates.is_empty():
		_break_plate()
