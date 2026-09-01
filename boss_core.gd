extends "res://boss_sprite_entity.gd"

# ==================================================
# THE FURNACE - 1. progression boss (derinlik 6)
#
# Boss id kodda &"core" olarak KALIR: derinlik sabitleri,
# ACHIEVEMENT_BOSS_IDS, boss_roster_test ve basarim sistemi bu id'yi
# kullaniyor. Degisen yalnizca gorunen ad ve gorsel.
#
# Imza mekanigi: diyafram. Agir, dilimli bir kapak govdenin yuzunu
# kapatiyor. Kapaliyken boss karanlik ve sessiz; sarj ederken kapak
# aciliyor ve icerideki firin isigi disari tasiyor; atista carparak
# kapaniyor.
#
# Neden ilk boss icin dogru: TELEGRAF VE GOVDE AYNI SEY. Oyuncunun ayri
# bir efekt ogrenmesi gerekmiyor - goz aciliyorsa kacacak. Tek okuma,
# belirsizlik yok. Eski radyal amblem bunu yapamiyordu cunku her an ayni
# gorunuyordu.
#
# MIMARI NOTU: bu boss eskiden StaticBody2D'den turuyordu ve hareket,
# ates, hasar, faz mantiginin hepsi burada ayri yazilmisti. Faz 9'da
# boss_sprite_entity.gd'ye tasindi; GOREVLER.md'nin "taban sinifa eklenen
# her yeni davranis ilk iki bossa kendiliginden gelmez" notu bununla
# kapandi.
# ==================================================

## Ayni anda ucusta olabilecek en fazla mermi.
## OLCULMUS DEGER (162d757): ates araligi 1.8-2.4 sn ve merminin ekrani
## gecmesi daha uzun surdugu icin mermiler ust uste birikiyordu.
## Tasima sirasinda korundu.
const MAX_ACTIVE_PROJECTILES := 2

## Faz basina atis sayisi ve yelpaze genisligi (radyan).
const SHOTS_PER_PHASE := [1, 2, 3]
const VOLLEY_SPREAD := 0.30


func _get_boss_label() -> String:
	return "THE FURNACE"


func _get_base_hp() -> int:
	return 100


func _get_extra_group() -> StringName:
	return &"furnace_boss"


func _get_frame_dir() -> String:
	return "res://assets/bosses/core/"


func _get_target_sprite_height() -> float:
	return 190.0


## Bos: THE FURNACE'in mermisi zaten varsayilan turuncu mermi.
func _get_projectile_palette() -> Array:
	return []


func _get_enrage_message() -> String:
	return "KAPAK SIKIŞTI"


func _get_phase_message(phase: int) -> String:
	return "DİYAFRAM FAZ %d" % phase


## Ilk bossun telegrafi bilerek uzun - oyuncunun gordugu ilk boss saldirisi.
func _get_telegraph_duration() -> float:
	if current_phase >= 3:
		return 0.70
	if current_phase == 2:
		return 0.85
	return 1.00


func _get_shot_count() -> int:
	return int(SHOTS_PER_PHASE[clampi(current_phase - 1, 0, SHOTS_PER_PHASE.size() - 1)])


func _get_fire_interval() -> float:
	var base := randf_range(fire_interval_min, fire_interval_max)
	return base * 0.85 if current_phase >= 3 else base


## Sahnede ucusta olan boss mermisi sayisi.
func _active_projectile_count() -> int:
	var count := 0
	for projectile: Node in get_tree().get_nodes_in_group("boss_projectile"):
		if is_instance_valid(projectile) and not projectile.is_queued_for_deletion():
			count += 1
	return count


# ==================================================
# IMZA SALDIRISI
#
# THE FURNACE'in TEK saldirisi bu; taban sinifin ayri ates dongusu
# kapatiliyor, yoksa diyaframdan bagimsiz ikinci bir atis kaynagi olurdu
# ve "goz aciliyorsa saldiri geliyor" okumasi bozulurdu.
# ==================================================

func _fire_loop() -> void:
	pass


func _signature_loop() -> void:
	await get_tree().create_timer(1.6).timeout
	while combat_active and accepting_damage:
		await get_tree().create_timer(_get_fire_interval()).timeout
		if not combat_active or not accepting_damage:
			return
		# Ucusta zaten sinir kadar mermi varsa bu turu atla; bir sonraki
		# aralikta tekrar denenir. Oyuncu her zaman en fazla iki mermiyle
		# ugrasir.
		if _active_projectile_count() >= MAX_ACTIVE_PROJECTILES:
			continue
		await _wait_for_projectile_clearance()
		if not combat_active or not accepting_damage:
			return
		await _run_aperture()


func _run_aperture() -> void:
	signature_active = true
	if is_instance_valid(move_tween):
		move_tween.kill()
	# charge karesi = diyafram ardina kadar acik, beyaz-sicak merkez
	_play_anim(&"charge")
	await get_tree().create_timer(_get_telegraph_duration()).timeout
	if not combat_active or not accepting_damage:
		signature_active = false
		return
	# release karesi = kapak carparak kapaniyor, isik sizarken mermi cikiyor
	_play_anim(&"release")
	_fire_volley(_get_shot_count())
	_shake_world(2.5)
	await get_tree().create_timer(0.35).timeout
	_return_to_idle()
	signature_active = false


func _fire_volley(count: int) -> void:
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		return
	var muzzle := to_global(Vector2(0.0, 30.0))
	var aim := (paddle.global_position - muzzle).normalized()
	for i in range(count):
		var offset := 0.0
		if count > 1:
			offset = lerpf(-VOLLEY_SPREAD, VOLLEY_SPREAD, float(i) / float(count - 1))
		var projectile: Node2D = PROJECTILE_SCENE.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = muzzle
		projectile.setup(get_parent(), aim.rotated(offset), projectile_speed)
		if get_parent().has_method("notify_boss_projectile_fired"):
			get_parent().notify_boss_projectile_fired()


## Diyafram sonuyor: kapak dilimleri disari savruluyor.
func _spawn_defeat_burst() -> void:
	var root := Node2D.new()
	get_parent().add_child(root)
	root.global_position = global_position
	root.z_index = 8
	for i in range(10):
		var shard := Polygon2D.new()
		shard.color = Color(1.0, 0.62, 0.22, 0.9)
		shard.polygon = PackedVector2Array([
			Vector2(-4, -14), Vector2(4, -14), Vector2(3, 14), Vector2(-3, 14),
		])
		shard.rotation = TAU * float(i) / 10.0
		root.add_child(shard)
		var dir := Vector2.RIGHT.rotated(shard.rotation)
		var fly := shard.create_tween().set_parallel(true)
		fly.tween_property(shard, "position", dir * randf_range(90.0, 150.0), 0.55)
		fly.tween_property(shard, "modulate:a", 0.0, 0.55)
	_apply_additive(root)
	root.create_tween().tween_callback(root.queue_free).set_delay(0.7)
