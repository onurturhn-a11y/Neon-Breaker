extends "res://boss_sprite_entity.gd"

# ==================================================
# THE WARDEN - 2. progression boss (derinlik 12)
#
# Boss id kodda &"sentinel" olarak KALIR: derinlik sabitleri,
# ACHIEVEMENT_BOSS_IDS, boss_roster_test, main.gd HUD gostergeleri ve
# basarim sistemi bu id'yi kullaniyor.
#
# Imza mekanigi: omuzlardaki iki jenerator kutugu cekirdegi koruyor.
# Ikisi de kirilana kadar govde hasar ALMIYOR. Kirilinca gogus kepengi
# aciliyor ve cekirdek bir sure savunmasiz kaliyor; pencere biterse
# jeneratorler geri geliyor - ama her turda biraz daha zayif.
#
# Tasarim: GOVDEDEKI TEK SICAK ISIK IKI JENERATOR. Butun boss soguk
# celik; omuzlardaki kutukler turuncu yaniyor. Oyuncu icgudusel olarak
# parlayan seye ates eder ve o zaten dogru hamledir. Mekanik metinle
# degil renkle ogretiliyor.
#
# MIMARI NOTU: bu boss eskiden StaticBody2D'den turuyordu. Faz 9'da
# boss_sprite_entity.gd'ye tasindi.
# ==================================================

signal generator_state_changed(left_active: bool, right_active: bool, core_shielded: bool)

## OLCULMUS DEGERLER - tasima sirasinda korundu.
## 14'ten 8'e dusurulmustu: cekirdegi acmak icin iki jeneratoru de kirmak
## gerekiyor ve her acilma sonrasi ikisi de doluyor; 28 hasar/tur cok
## yuksekti.
const GENERATOR_MAX_HP := 8
## Her yenilenmede jenerator cani bu oranla azalir: 8 -> 6 -> 5 -> 3.
const GENERATOR_REGEN_FALLOFF := 0.75
const GENERATOR_MIN_REGEN_HP := 3

## 10'dan 14'e cikarilmisti: cekirdek 145 HP ve pencere disinda hicbir
## hasar almiyor, 10 saniye tur basina cok az ilerleme veriyordu.
@export var exposure_window: float = 14.0
@export var enraged_exposure_window: float = 11.0
@export var generator_regeneration_duration: float = 0.8

## Jenerator kutuklerinin govde merkezine gore konumu. Yeni sprite'tan
## OLCULDU (idle_a.png: kutuk merkezleri ±57 px, hedef yukseklikte ±47).
## Eski deger ±86 idi ve eski duz PNG'ye aitti.
const GENERATOR_X := 47.0
## Bu x'in disina dusen her vurus o taraftaki jeneratore yazilir. Kutugun
## kendisinden genis: ikinci boss ogretiyor, nisan almayi cezalandirmiyor.
const GENERATOR_SPLIT_X := 24.0

var left_generator_hp := GENERATOR_MAX_HP
var right_generator_hp := GENERATOR_MAX_HP
var core_shielded := true
var regeneration_count := 0
var exposure_token := 0
var exposure_end_msec := 0


func _get_boss_label() -> String:
	return "THE WARDEN"


func _get_base_hp() -> int:
	return 145


func _get_extra_group() -> StringName:
	return &"warden_boss"


func _get_frame_dir() -> String:
	return "res://assets/bosses/sentinel/"


func _get_target_sprite_height() -> float:
	return 215.0


## Durum pozlari taban sinifin sozlugunde yok. exposed/gen_* birer
## SALDIRI degil, DURUM - _set_state_pose() ile suruluyorlar.
func _get_frame_sets() -> Dictionary:
	var sets := FRAME_SETS.duplicate(true)
	sets[&"charge_2"] = ["charge_2.png"]
	sets[&"release_2"] = ["release_2.png"]
	sets[&"exposed"] = ["exposed_a.png"]
	sets[&"gen_one_down"] = ["gen_one_down.png"]
	sets[&"gen_both_down"] = ["gen_both_down.png"]
	return sets


func _get_projectile_palette() -> Array:
	return []


func _get_core_glow_alpha_scale() -> float:
	return 0.0


func _get_enrage_message() -> String:
	return "KEPENK KAPANMIYOR"


func _get_phase_message(phase: int) -> String:
	return "BEKÇİ FAZ %d" % phase


func _get_telegraph_duration() -> float:
	return 0.65 if current_phase >= 2 else 0.80


func _live_generator_count() -> int:
	return int(left_generator_hp > 0) + int(right_generator_hp > 0)


func _ready() -> void:
	super()
	generator_state_changed.emit(true, true, true)


# ==================================================
# DURUM POZLARI
#
# Jenerator durumu bossun GOVDESINDEN okunuyor: iki kutuk yaniyor, biri
# sonuk, ikisi de sonuk, kepenk acik. Bunlar saldiri pozu degil, o yuzden
# _play_anim yerine dogrudan harmanlaniyor (o fonksiyon titreme ve
# geri tepme de ekliyor).
# ==================================================

func _current_state_pose() -> StringName:
	if not core_shielded:
		return &"exposed"
	match _live_generator_count():
		0:
			return &"gen_both_down"
		1:
			return &"gen_one_down"
	return &"idle"


func _set_state_pose() -> void:
	if not using_sprite_frames:
		return
	var name := _current_state_pose()
	if pose_state == name:
		return
	pose_state = name
	var target := _frame(name, 0)
	if target == null:
		return
	var t := _blend_to(target, POSE_FADE_IDLE)
	if t != null:
		t.tween_callback(func() -> void:
			_settle_pose()
			idle_blend_time = 0.0
		)


func _return_to_idle() -> void:
	if not accepting_damage:
		return
	if signature_active:
		return
	pose_state = &""
	_set_state_pose()


# ==================================================
# HASAR YONLENDIRME
#
# Kalkan kapaliyken merkez seride gelen vurus cekirdege gider ve HICBIR
# hasar vermez (metal sesi); disa gelen vurus o taraftaki jeneratore
# yazilir. Kalkan acikken her yer cekirdektir.
# ==================================================

func _region_from_global_hit(hit_position: Vector2) -> StringName:
	if not core_shielded:
		return &"core"
	var local_x := to_local(hit_position).x
	if local_x <= -GENERATOR_SPLIT_X:
		return &"left"
	if local_x >= GENERATOR_SPLIT_X:
		return &"right"
	return &"core"


func _apply_region_hit(region: StringName, source: StringName, attacker_id: int, hit_position: Vector2) -> void:
	if not accepting_damage:
		return
	var damage := GameManager.resolve_boss_direct_hit_damage(source)
	if damage <= 0:
		return
	var is_ball := source in DIRECT_BALL_SOURCES
	if is_ball and active_ball_contacts.has(attacker_id):
		return
	var request_key := "%s:%s:%d" % [region, source, attacker_id]
	var now := Time.get_ticks_msec()
	if now - int(last_damage_request_msec.get(request_key, -1000000)) < int(ball_hit_lock_duration * 1000.0):
		return
	last_damage_request_msec[request_key] = now
	if is_ball:
		active_ball_contacts[attacker_id] = true

	if region == &"core":
		if core_shielded:
			# Kalkan hasari tamamen yutuyor. Ogretici geri bildirim:
			# oyuncu buraya vurmanin ise yaramadigini gormeli.
			_play_armor_hit(hit_position)
			_flinch(hit_position)
			return
		current_hp = maxi(current_hp - damage, 0)
		_play_core_hit(hit_position)
		health_changed.emit(current_hp, max_hp)
		_flinch(hit_position)
		if current_hp <= 0:
			_defeat()
		else:
			_update_phase()
		return

	_damage_generator(region == &"left", damage, hit_position)


func _damage_generator(is_left: bool, damage: int, hit_position: Vector2) -> void:
	var hp := left_generator_hp if is_left else right_generator_hp
	if hp <= 0:
		# Sonmus kutuge vurmak bir sey yapmaz; sessiz kalmasin.
		_play_armor_hit(hit_position)
		return
	hp = maxi(hp - damage, 0)
	if is_left:
		left_generator_hp = hp
	else:
		right_generator_hp = hp
	_play_armor_hit(hit_position)
	_flinch(hit_position)
	if hp <= 0:
		_on_generator_destroyed(is_left)
	else:
		if not signature_active:
			_play_anim(&"hit")
	generator_state_changed.emit(left_generator_hp > 0, right_generator_hp > 0, core_shielded)


func _on_generator_destroyed(is_left: bool) -> void:
	status_feedback.emit(
		"SOL JENERATÖR YOK" if is_left else "SAĞ JENERATÖR YOK", &"shield"
	)
	_shake_world(4.0)
	_set_state_pose()
	if _live_generator_count() == 0:
		call_deferred("_expose_core")


# ==================================================
# ACILMA VE YENILENME
# ==================================================

func _expose_core() -> void:
	if not core_shielded or not accepting_damage:
		return
	core_shielded = false
	exposure_token += 1
	var token := exposure_token
	_set_state_pose()
	generator_state_changed.emit(false, false, false)
	status_feedback.emit("ÇEKİRDEK AÇIK!", &"exposed")
	_shake_world(6.0)
	var window := enraged_exposure_window if current_phase >= 3 else exposure_window
	exposure_end_msec = Time.get_ticks_msec() + int(window * 1000.0)
	await get_tree().create_timer(window).timeout
	if token == exposure_token and accepting_damage and current_hp > 0 and not core_shielded:
		_regenerate_generators()


## Jeneratorler TAM dolu degil, %75 ile geri gelir.
##
## Eski davranista her acilma sonrasi ikisi de tam dolu donuyordu, yani
## oyuncunun onceki turda verdigi jenerator hasari tamamen bosa gidiyordu.
## Ilerlemenin bir kismi tasinsin: her tur bir oncekinden biraz kisa.
func _regenerate_generators() -> void:
	core_shielded = true
	exposure_end_msec = 0
	regeneration_count += 1
	var hp := maxi(
		roundi(float(GENERATOR_MAX_HP) * pow(GENERATOR_REGEN_FALLOFF, float(regeneration_count))),
		GENERATOR_MIN_REGEN_HP
	)
	left_generator_hp = hp
	right_generator_hp = hp
	_set_state_pose()
	generator_state_changed.emit(true, true, true)
	status_feedback.emit("KALKAN GERİ GELDİ", &"shield")


# ==================================================
# SALDIRILAR
#
# Taban sinifin duz ates dongusu kapali: bu bossun atislari jeneratör
# durumuna bagli ve poz eslesmesi gerekiyor.
# ==================================================

func _fire_loop() -> void:
	pass


func _signature_loop() -> void:
	await get_tree().create_timer(2.0).timeout
	while combat_active and accepting_damage:
		await get_tree().create_timer(randf_range(2.6, 3.4)).timeout
		if not combat_active or not accepting_damage:
			return
		# Acilma penceresi saf hasar penceresi: boss saldirmaz.
		if not core_shielded:
			continue
		await _wait_for_projectile_clearance()
		if not combat_active or not accepting_damage or not core_shielded:
			continue
		if _live_generator_count() > 0 and randf() < 0.65:
			await _run_salvo()
		else:
			await _run_heavy_shot()


## Salvo: yasayan her jeneratör rakete dogru ates eder. Bir kutuk
## kirilinca gelen ates de yariya iner - kirmanin odulu aninda hissediliyor.
func _run_salvo() -> void:
	signature_active = true
	if is_instance_valid(move_tween):
		move_tween.kill()
	_play_anim(&"charge")
	await get_tree().create_timer(_get_telegraph_duration()).timeout
	if not combat_active or not accepting_damage:
		signature_active = false
		return
	_play_anim(&"release")
	if left_generator_hp > 0:
		_fire_from(Vector2(-GENERATOR_X, -20.0))
	if right_generator_hp > 0:
		_fire_from(Vector2(GENERATOR_X, -20.0))
	_shake_world(2.0)
	await get_tree().create_timer(0.4).timeout
	_return_to_idle()
	signature_active = false


## Agir atis: gogus kepenginin yarigindan tek, yavas, buyuk mermi.
func _run_heavy_shot() -> void:
	signature_active = true
	if is_instance_valid(move_tween):
		move_tween.kill()
	_play_anim(&"charge_2")
	await get_tree().create_timer(_get_telegraph_duration() + 0.2).timeout
	if not combat_active or not accepting_damage:
		signature_active = false
		return
	_play_anim(&"release_2")
	_fire_from(Vector2(0.0, 10.0), 0.70, true)
	_shake_world(3.5)
	await get_tree().create_timer(0.45).timeout
	_return_to_idle()
	signature_active = false


func _fire_from(local_muzzle: Vector2, speed_scale: float = 1.0, heavy: bool = false) -> void:
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		return
	var projectile: Node2D = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = to_global(local_muzzle)
	var aim := (paddle.global_position - projectile.global_position).normalized()
	projectile.setup(get_parent(), aim, projectile_speed * speed_scale, heavy)
	if get_parent().has_method("notify_boss_projectile_fired"):
		get_parent().notify_boss_projectile_fired()


func _spawn_defeat_burst() -> void:
	exposure_token += 1
	generator_state_changed.emit(false, false, false)
