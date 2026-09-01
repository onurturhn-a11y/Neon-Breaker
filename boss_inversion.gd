extends "res://boss_sprite_entity.gd"

# ==================================================
# THE INVERSION - yeni boss (kadro sirasi 9)
#
# Imza mekanigi: ayna bandi. Ekrani boydan boya kesen yatay bir duzlem
# boss ile raket arasinda suzuluyor; icinden gecen her OYUNCU MERMISI
# emiliyor ve kisa sure sonra rakete nisanlanip geri atiliyor. Top
# etkilenmiyor - yalnizca silah mermileri.
#
# Kadronun geri kalani kacinma testi. Bu boss ATES KESME testi: iki silah
# yuvasi otomatik ates ederken oyuncudan ates etmemesini istiyor. Mermi
# hizi farki ilk kez burada onemli - Railgun bandi aninda gecer, Mortar'in
# yavas yayi bandin icinde yakalanir.
#
# Ortak iskelet icin boss_sprite_entity.gd'ye bak.
# ==================================================

## Emilebilecek oyuncu mermisi gruplari. Top burada YOK: kasitli.
##
## YENI SILAH EKLERKEN buraya mermi grubunu da yaz, yoksa o silah aynadan
## muaf kalir ve bossun mekanigi sessizce delinir.
##
## Dogal olarak muaf olanlar (mermi dugumu uretmiyorlar, anlik/isin):
##   Railgun, Pulse Laser, Arc Cannon. Bu bir eksiklik degil - oyuncunun
##   ogrenecegi bir sey: aynaya karsi isin silahlari guvenli.
##
## Eksik: Mortar. mortar_shell.gd hicbir gruba girmiyor (yalnizca carpma
## efekti icin mortar_impact_vfx var), dolayisiyla ucustaki mermi
## bulunamiyor. Codex bolgesi - ILETISIM A13'te soruldu.
## Orbital Strike de yok: hedefin uzerinde doguyor, sahayi katederek
## gelen bir dugum degil; emilmesi ayri bir kanca ister.
const ABSORB_GROUPS: Array[StringName] = [
	&"plasma_projectile",
	&"scatter_projectile",
	&"homing_missile",
	&"drone_bay_projectile",
]

const BAND_HALF_HEIGHT := 17.0
const BAND_DRIFT_BASE := 62.0
const BAND_DRIFT_PHASE2 := 78.0
const RETURN_DELAY := 0.8
const ABSORB_CAP_PHASE1 := 6
const ABSORB_CAP_PHASE2 := 10

var bands: Array[Dictionary] = []
var band_root: Node2D
var absorbed := 0
var absorbed_total := 0
var payback_done := false
var bands_active := false


func _get_boss_label() -> String:
	return "THE INVERSION"


func _get_base_hp() -> int:
	return 455


func _get_extra_group() -> StringName:
	return &"inversion_boss"


func _get_frame_dir() -> String:
	return "res://assets/bosses/inversion/"


func _get_target_sprite_height() -> float:
	return 275.0


func _get_frame_sets() -> Dictionary:
	var sets := FRAME_SETS.duplicate(true)
	sets[&"charge_2"] = ["charge_2.png"]
	sets[&"release_2"] = ["release_2.png"]
	return sets


func _get_projectile_palette() -> Array:
	return [
		Color(1.00, 0.24, 0.78, 1.0),
		Color(1.00, 0.48, 0.88, 1.0),
		Color(1.00, 0.82, 0.96, 1.0),
	]


func _get_core_glow_alpha_scale() -> float:
	return 0.45


func _get_enrage_message() -> String:
	return "GERİ ÖDEME"


func _get_phase_message(phase: int) -> String:
	return "AYNA FAZ %d" % phase


func _get_telegraph_duration() -> float:
	return 0.75 if current_phase >= 2 else 0.90


func _get_band_count() -> int:
	return 2 if current_phase >= 2 else 1


func _get_absorb_cap() -> int:
	return ABSORB_CAP_PHASE2 if current_phase >= 2 else ABSORB_CAP_PHASE1


func _ready() -> void:
	super()
	band_root = Node2D.new()
	band_root.name = "BandRoot"
	band_root.top_level = true
	band_root.z_index = 6
	add_child(band_root)


# ==================================================
# AYNA BANDI
# ==================================================

func _get_band_span() -> Vector2:
	var rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	return Vector2(rect.position.x - 40.0, rect.end.x + 40.0)


func _band_travel_range() -> Vector2:
	var rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	var low := paddle.global_position.y - 120.0 if is_instance_valid(paddle) else rect.end.y - 150.0
	return Vector2(global_position.y + 110.0, maxf(low, global_position.y + 180.0))


func _spawn_band(direction: float, start_ratio: float) -> void:
	var span := _get_band_span()
	var travel := _band_travel_range()
	var root := Node2D.new()
	band_root.add_child(root)
	root.global_position = Vector2(0.0, lerpf(travel.x, travel.y, start_ratio))
	var width := span.y - span.x
	# Genisten dara: sogumus hale -> beyaz cekirdek. Isin ailesiyle ayni dil.
	for layer: Array in [[BAND_HALF_HEIGHT * 2.60, Color(0.30, 0.96, 0.94, 0.20)],
						 [BAND_HALF_HEIGHT * 1.40, Color(1.00, 0.24, 0.78, 0.34)],
						 [BAND_HALF_HEIGHT * 0.55, Color(1.00, 1.00, 1.00, 0.92)]]:
		var poly := Polygon2D.new()
		var h: float = layer[0]
		poly.color = layer[1]
		poly.polygon = PackedVector2Array([
			Vector2(span.x, -h), Vector2(span.y, -h),
			Vector2(span.y, h), Vector2(span.x, h),
		])
		root.add_child(poly)
	_apply_additive(root)
	root.modulate.a = 0.0
	root.create_tween().tween_property(root, "modulate:a", 1.0, 0.35)
	bands.append({"node": root, "dir": direction, "range": travel})


func _clear_bands() -> void:
	for band: Dictionary in bands:
		var node: Node2D = band.get("node")
		if is_instance_valid(node):
			var fade := node.create_tween()
			fade.tween_property(node, "modulate:a", 0.0, 0.25)
			fade.tween_callback(node.queue_free)
	bands.clear()


func _physics_process(delta: float) -> void:
	super(delta)
	if not bands_active or bands.is_empty():
		return
	var speed := BAND_DRIFT_PHASE2 if current_phase >= 2 else BAND_DRIFT_BASE
	for band: Dictionary in bands:
		var node: Node2D = band.get("node")
		if not is_instance_valid(node):
			continue
		var rng: Vector2 = band.get("range")
		var dir: float = band.get("dir")
		var y := node.global_position.y + dir * speed * delta
		if y < rng.x:
			y = rng.x; band["dir"] = 1.0
		elif y > rng.y:
			y = rng.y; band["dir"] = -1.0
		node.global_position.y = y
	_absorb_crossing_projectiles()


## Bandin icinden gecen oyuncu mermilerini yutar. Top listede yok.
func _absorb_crossing_projectiles() -> void:
	if absorbed >= _get_absorb_cap():
		return
	for group: StringName in ABSORB_GROUPS:
		for node: Node in get_tree().get_nodes_in_group(group):
			var shot := node as Node2D
			if not is_instance_valid(shot):
				continue
			for band: Dictionary in bands:
				var band_node: Node2D = band.get("node")
				if not is_instance_valid(band_node):
					continue
				if absf(shot.global_position.y - band_node.global_position.y) > BAND_HALF_HEIGHT:
					continue
				_absorb(shot, band_node.global_position.y)
				break
			if absorbed >= _get_absorb_cap():
				return


func _absorb(shot: Node2D, band_y: float) -> void:
	var at := Vector2(shot.global_position.x, band_y)
	shot.queue_free()
	absorbed += 1
	absorbed_total += 1
	_spawn_absorb_flash(at)
	if not payback_done:
		get_tree().create_timer(RETURN_DELAY).timeout.connect(func() -> void:
			if combat_active and accepting_damage and not payback_done:
				_return_shot(at)
				absorbed = maxi(absorbed - 1, 0)
		)


func _spawn_absorb_flash(at: Vector2) -> void:
	var flash := Polygon2D.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.9)
	flash.polygon = PackedVector2Array([
		Vector2(-4, -26), Vector2(4, -26), Vector2(4, 26), Vector2(-4, 26),
	])
	band_root.add_child(flash)
	flash.top_level = true
	flash.global_position = at
	_apply_additive(flash)
	var t := flash.create_tween().set_parallel(true)
	t.tween_property(flash, "scale", Vector2(3.2, 0.25), 0.24)
	t.tween_property(flash, "modulate:a", 0.0, 0.24)
	t.chain().tween_callback(flash.queue_free)


## Emilen atisi rakete nisanlayip geri gonderir.
func _return_shot(from: Vector2) -> void:
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		return
	var projectile: Node2D = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = from
	projectile.setup(get_parent(), (paddle.global_position - from).normalized(), projectile_speed * 1.05)
	var palette := _get_projectile_palette()
	if projectile.has_method("apply_palette") and palette.size() >= 3:
		projectile.apply_palette(_get_shard_texture(), palette[0], palette[1], palette[2])


# ==================================================
# IMZA SALDIRILARI
# ==================================================

func _signature_loop() -> void:
	await get_tree().create_timer(1.8).timeout
	if not combat_active or not accepting_damage:
		return
	await _open_bands()
	while combat_active and accepting_damage:
		await get_tree().create_timer(randf_range(4.0, 4.8)).timeout
		if not combat_active or not accepting_damage:
			return
		if current_phase >= 3 and not payback_done:
			await _run_payback()
			continue
		if bands.size() < _get_band_count():
			await _open_bands()
		else:
			await _run_refraction()


func _open_bands() -> void:
	signature_active = true
	_play_anim(&"charge")
	status_feedback.emit("AYNA AÇILIYOR", &"exposed")
	await get_tree().create_timer(_get_telegraph_duration()).timeout
	if not combat_active or not accepting_damage:
		signature_active = false
		return
	_play_anim(&"release")
	_clear_bands()
	var n := _get_band_count()
	for i in range(n):
		_spawn_band(1.0 if i % 2 == 0 else -1.0, 0.15 if i % 2 == 0 else 0.85)
	bands_active = true
	_shake_world(3.0)
	await get_tree().create_timer(0.4).timeout
	_return_to_idle()
	signature_active = false


## Kirilma: band bosken bile baski kalsin diye duzlemin iki yanina
## simetrik iki mermi.
func _run_refraction() -> void:
	signature_active = true
	_play_anim(&"charge_2")
	await get_tree().create_timer(_get_telegraph_duration()).timeout
	if not combat_active or not accepting_damage:
		signature_active = false
		return
	_play_anim(&"release_2")
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	var palette := _get_projectile_palette()
	for side: float in [-1.0, 1.0]:
		var projectile: Node2D = PROJECTILE_SCENE.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = to_global(Vector2(side * 46.0, 30.0))
		var aim := Vector2(side * 0.42, 1.0).normalized()
		if is_instance_valid(paddle):
			aim = (paddle.global_position - projectile.global_position).normalized().rotated(side * 0.22)
		projectile.setup(get_parent(), aim, projectile_speed)
		if projectile.has_method("apply_palette") and palette.size() >= 3:
			projectile.apply_palette(_get_shard_texture(), palette[0], palette[1], palette[2])
	await get_tree().create_timer(0.4).timeout
	_return_to_idle()
	signature_active = false


## Geri odeme: bandlar raket hizasina kilitlenir, dovus boyunca emilen HER
## mermi tek salvoda geri kusulur. Az ates eden oyuncu kucuk bir salvoyla
## karsilasir - bu fazin zorlugunu oyuncunun kendi davranisi belirler.
func _run_payback() -> void:
	payback_done = true
	signature_active = true
	if is_instance_valid(move_tween):
		move_tween.kill()
	_play_anim(&"charge_2")
	status_feedback.emit("GERİ ÖDEME", &"exposed")
	await get_tree().create_timer(1.0).timeout
	if not combat_active or not accepting_damage:
		signature_active = false
		return
	var travel := _band_travel_range()
	for band: Dictionary in bands:
		var node: Node2D = band.get("node")
		if is_instance_valid(node):
			node.create_tween().tween_property(node, "global_position:y", travel.y, 0.5)
	await get_tree().create_timer(0.55).timeout
	_play_anim(&"release_2")
	var salvo := maxi(absorbed_total, 2)
	var span := _get_band_span()
	for i in range(salvo):
		if not combat_active or not accepting_damage:
			break
		var x := lerpf(span.x + 60.0, span.y - 60.0, float(i) / float(maxi(salvo - 1, 1)))
		_return_shot(Vector2(x, global_position.y + 90.0))
		await get_tree().create_timer(0.08).timeout
	bands_active = false
	_clear_bands()
	_shake_world(6.0)
	status_feedback.emit("AYNALAR KIRILDI", &"shield")
	_play_anim(&"hit")
	await get_tree().create_timer(3.0).timeout
	_return_to_idle()
	signature_active = false
	await _open_bands()


func _spawn_defeat_burst() -> void:
	bands_active = false
	_clear_bands()
