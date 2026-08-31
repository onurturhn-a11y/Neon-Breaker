extends StaticBody2D

signal health_changed(current_hp: int, max_hp: int)
signal generator_state_changed(left_active: bool, right_active: bool, core_shielded: bool)
signal status_feedback(message: String, tone: StringName)
signal defeated

@export var max_hp: int = 145
## 14'ten 8'e dusuruldu. Cekirdegi acmak icin iki jeneratoru de kirmak
## gerekiyor (2 x can) ve her acilma sonrasi ikisi de TAM dolu geri geliyor.
## 28 hasar/tur cok yuksekti; 16 daha makul.
@export var generator_max_hp: int = 8
@export var entry_duration: float = 1.0
## 10'dan 14'e cikarildi. Cekirdek 145 HP ve pencere disinda hicbir hasar
## almiyor; 10 saniye tur basina cok az ilerleme veriyordu.
@export var exposure_window: float = 14.0
@export var enraged_exposure_window: float = 11.0
@export var generator_regeneration_duration: float = 0.8
@export var move_speed_phase_1: float = 65.0
@export var move_speed_phase_2: float = 82.0
@export var move_speed_phase_3: float = 92.0
@export var fire_interval_min: float = 2.0
@export var fire_interval_max: float = 2.4
@export var projectile_speed: float = 350.0
@export var heavy_telegraph_duration: float = 0.6
@export var ball_hit_lock_duration: float = 0.12
@export var mobile_scale_multiplier: float = 1.18

const PROJECTILE_SCENE = preload("res://boss_projectile.tscn")
const DIRECT_BALL_SOURCES: Array[StringName] = [&"ball", &"piercing_ball", &"fireball_ball"]
const LEFT_GENERATOR_X := -86.0
const RIGHT_GENERATOR_X := 86.0
const GENERATOR_HIT_HALF_WIDTH := 43.0

## Her kalkan yenilenmesinde jenerator cani bu oranla azalir.
## 8 -> 6 -> 5 -> 3 (taban). Dovus ilerledikce turlar kisalir.
const GENERATOR_REGEN_FALLOFF := 0.75
const GENERATOR_MIN_REGEN_HP := 3
const BODY_HALF_WIDTH := 126.0

var current_hp := 145
var left_generator_hp := 14
var right_generator_hp := 14
var core_shielded := true
## Kacinci kez kalkan yenilendi. Jenerator canini azaltmak icin kullanilir.
var regeneration_count := 0
var accepting_damage := true
var combat_active := false
var exposure_token := 0
var current_phase := 1
var move_tween: Tween
var visual_tween: Tween
var active_ball_contacts: Dictionary = {}
var last_damage_request_msec: Dictionary = {}
var readability_time := 0.0
var exposure_end_msec := 0
var shield_hint_count := 0
var attack_cycle_count := 0
var last_shield_hint_msec := -1000000

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_root: Node2D = $VisualRoot
@onready var core_visual: Polygon2D = $VisualRoot/MainCore
@onready var core_ring: Line2D = $VisualRoot/CoreRing
@onready var shield_surface: Polygon2D = $VisualRoot/ShieldSurface
@onready var shield_ring: Line2D = $VisualRoot/ShieldRing
@onready var left_generator: Node2D = $VisualRoot/LeftGenerator
@onready var right_generator: Node2D = $VisualRoot/RightGenerator


func _ready() -> void:
	if OS.has_feature("mobile"):
		scale *= mobile_scale_multiplier
	add_to_group("game_boss")
	add_to_group("sentinel_boss")
	# Ascension katmani boss dayanikliligini da olcekler.
	max_hp = maxi(roundi(float(max_hp) * GameManager.get_ascension_boss_hp_scale()), 1)
	current_hp = max_hp
	left_generator_hp = generator_max_hp
	right_generator_hp = generator_max_hp
	regeneration_count = 0
	collision_shape.disabled = true
	health_changed.emit(current_hp, max_hp)
	generator_state_changed.emit(true, true, true)


func _physics_process(delta: float) -> void:
	_update_readability(delta)
	if not accepting_damage:
		return
	_update_phase()
	var release_distance := BODY_HALF_WIDTH * absf(global_scale.x) + 34.0
	for attacker_id: int in active_ball_contacts.keys():
		var attacker := instance_from_id(attacker_id) as Node2D
		if not is_instance_valid(attacker) or attacker.global_position.distance_to(global_position) > release_distance:
			active_ball_contacts.erase(attacker_id)


func begin_entry(target_position: Vector2) -> void:
	var entry := create_tween()
	entry.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	entry.tween_property(self, "global_position", target_position, entry_duration)
	await entry.finished
	if not accepting_damage:
		return
	collision_shape.set_deferred("disabled", false)
	combat_active = true
	call_deferred("_movement_loop")
	call_deferred("_fire_loop")


func _movement_loop() -> void:
	while combat_active and accepting_damage:
		var safe_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
		var half_width := BODY_HALF_WIDTH * absf(global_scale.x)
		var left_bound := safe_rect.position.x + half_width + 12.0
		var right_bound := safe_rect.end.x - half_width - 12.0
		var target_x := safe_rect.get_center().x
		if right_bound > left_bound:
			target_x = randf_range(left_bound, right_bound)
		var speed := _get_move_speed()
		var duration := maxf(absf(target_x - global_position.x) / speed, 0.16)
		move_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		move_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		move_tween.tween_property(self, "global_position:x", target_x, duration)
		await move_tween.finished
		if not combat_active:
			return
		await get_tree().create_timer(randf_range(0.28, 0.58)).timeout


func _fire_loop() -> void:
	while combat_active and accepting_damage:
		var interval := randf_range(fire_interval_min, fire_interval_max)
		if current_phase >= 3:
			interval *= 0.85
		await get_tree().create_timer(interval).timeout
		if not combat_active or not accepting_damage:
			return
		await _wait_for_projectile_clearance()
		if not combat_active or not accepting_damage:
			return
		attack_cycle_count += 1
		var heavy_every := 3 if current_phase >= 3 else 4
		if current_phase >= 2 and attack_cycle_count % heavy_every == 0:
			await _fire_heavy_shot()
		else:
			_fire_generator_salvo()


func _fire_generator_salvo() -> void:
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		return
	var target := paddle.global_position
	var available_muzzles: Array[Vector2] = []
	if left_generator_hp > 0:
		available_muzzles.append(Vector2(LEFT_GENERATOR_X, 8.0))
	if right_generator_hp > 0:
		available_muzzles.append(Vector2(RIGHT_GENERATOR_X, 8.0))
	var muzzle := Vector2(0.0, 48.0)
	if not available_muzzles.is_empty():
		muzzle = available_muzzles.pick_random()
	_spawn_projectile_from(muzzle, target, 0.0)


func _fire_heavy_shot() -> void:
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		return
	var target_snapshot := paddle.global_position
	var original_color := core_visual.color
	var charge := core_visual.create_tween().set_parallel(true)
	charge.tween_property(core_visual, "color", Color(1.0, 0.32, 0.08, 1.0), heavy_telegraph_duration)
	charge.tween_property(core_visual, "scale", Vector2.ONE * 1.22, heavy_telegraph_duration)
	await charge.finished
	if not combat_active or not accepting_damage:
		return
	var projectile := PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(0.0, 48.0 * absf(global_scale.y))
	projectile.setup(get_parent(), (target_snapshot - projectile.global_position).normalized(), projectile_speed, true)
	if get_parent().has_method("notify_boss_projectile_fired"):
		get_parent().notify_boss_projectile_fired()
	core_visual.color = original_color
	core_visual.scale = Vector2.ONE


func _spawn_projectile_from(local_muzzle: Vector2, target: Vector2, spread_degrees: float) -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = to_global(local_muzzle)
	var direction: Vector2 = (target - projectile.global_position).normalized().rotated(deg_to_rad(spread_degrees))
	projectile.setup(get_parent(), direction, projectile_speed)
	if get_parent().has_method("notify_boss_projectile_fired"):
		get_parent().notify_boss_projectile_fired()


var projectile_block_until_msec := 0


func delay_projectile_after_side_wave(seconds: float) -> void:
	projectile_block_until_msec = maxi(
		projectile_block_until_msec,
		Time.get_ticks_msec() + int(seconds * 1000.0)
	)


func _wait_for_projectile_clearance() -> void:
	var wait_seconds := float(projectile_block_until_msec - Time.get_ticks_msec()) / 1000.0
	if wait_seconds > 0.0:
		await get_tree().create_timer(wait_seconds).timeout


func hit_from_ball_at(attacker_instance_id: int, source: StringName, hit_position: Vector2) -> void:
	_apply_region_hit(_region_from_global_hit(hit_position), source, attacker_instance_id, hit_position)


func hit_from_plasma_at(attacker_instance_id: int, hit_position: Vector2) -> void:
	_apply_region_hit(_region_from_global_hit(hit_position), &"plasma", attacker_instance_id, hit_position)


func hit_from_ball(attacker_instance_id: int, source: StringName = &"ball") -> void:
	_apply_region_hit(&"core", source, attacker_instance_id, global_position)


func hit_from_plasma(attacker_instance_id: int) -> void:
	_apply_region_hit(&"core", &"plasma", attacker_instance_id, global_position)


func hit_from_mounted_weapon(source: StringName, cycle_id: int) -> void:
	_apply_region_hit(&"core", source, cycle_id, global_position)


func _region_from_global_hit(hit_position: Vector2) -> StringName:
	var local_hit := to_local(hit_position)
	if absf(local_hit.x - LEFT_GENERATOR_X) <= GENERATOR_HIT_HALF_WIDTH:
		return &"left"
	if absf(local_hit.x - RIGHT_GENERATOR_X) <= GENERATOR_HIT_HALF_WIDTH:
		return &"right"
	return &"core"


func _apply_region_hit(region: StringName, source: StringName, attacker_id: int, hit_position: Vector2) -> void:
	if not accepting_damage:
		return
	var damage := _resolve_damage(source)
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
	match region:
		&"left":
			_damage_generator(true, damage)
		&"right":
			_damage_generator(false, damage)
		_:
			_damage_core(damage, hit_position, source)


func _resolve_damage(source: StringName) -> int:
	return GameManager.resolve_boss_direct_hit_damage(source)


func _damage_generator(is_left: bool, damage: int) -> void:
	var hp := left_generator_hp if is_left else right_generator_hp
	if hp <= 0:
		_play_metal_feedback()
		return
	hp = maxi(hp - damage, 0)
	if is_left:
		left_generator_hp = hp
	else:
		right_generator_hp = hp
	_play_generator_hit(is_left)
	if hp <= 0:
		_destroy_generator(is_left)
	generator_state_changed.emit(left_generator_hp > 0, right_generator_hp > 0, core_shielded)
	if left_generator_hp <= 0 and right_generator_hp <= 0 and core_shielded:
		_expose_core()


func _damage_core(damage: int, hit_position: Vector2, source: StringName) -> void:
	if core_shielded:
		_play_shield_feedback(hit_position)
		return
	var previous := current_hp
	current_hp = maxi(current_hp - damage, 0)
	if OS.is_debug_build():
		print("SENTINEL CORE HIT | source=%s | damage=%d | HP=%d/%d" % [source, damage, current_hp, max_hp])
	health_changed.emit(current_hp, max_hp)
	_play_core_hit()
	if current_hp <= 0:
		_defeat()


func _destroy_generator(is_left: bool) -> void:
	var node := left_generator if is_left else right_generator
	_spawn_generator_burst(node.position)
	var fade := node.create_tween().set_parallel(true)
	fade.tween_property(node, "modulate", Color(1.8, 1.15, 0.55, 0.18), 0.22)
	fade.tween_property(node, "scale", Vector2.ONE * 0.72, 0.22)
	print("SENTINEL GENERATOR DESTROYED: %s" % ("LEFT" if is_left else "RIGHT"))

func _expose_core() -> void:
	core_shielded = false
	exposure_token += 1
	var token := exposure_token
	_play_shield_break()
	core_visual.color = Color(1.0, 0.34, 0.08, 1.0)
	core_ring.default_color = Color(1.0, 0.58, 0.18, 0.95)
	generator_state_changed.emit(false, false, false)
	status_feedback.emit("\u00C7EK\u0130RDEK A\u00C7IK!", &"exposed")
	print("THE SENTINEL CORE EXPOSED")
	var window := enraged_exposure_window if current_phase >= 3 else exposure_window
	exposure_end_msec = Time.get_ticks_msec() + int(window * 1000.0)
	await get_tree().create_timer(window).timeout
	if token == exposure_token and accepting_damage and current_hp > 0 and not core_shielded:
		await _regenerate_generators()

## Jeneratorler TAM dolu degil, %75 ile geri gelir.
##
## Eski davranista her acilma sonrasi ikisi de tam dolu donuyordu, yani
## oyuncunun onceki turda verdigi jenerator hasari tamamen bosa gidiyordu.
## Ilerlemenin bir kismi tasinsin: her tur bir oncekinden biraz kisa.
func _regenerate_generators() -> void:
	core_shielded = true
	exposure_end_msec = 0
	shield_ring.visible = true
	shield_surface.visible = true
	shield_ring.modulate = Color(1.0, 1.0, 1.0, 0.0)
	shield_surface.modulate = Color(1.0, 1.0, 1.0, 0.0)
	shield_ring.scale = Vector2.ONE * 1.18
	shield_surface.scale = Vector2.ONE * 1.18
	core_visual.color = Color(0.22, 0.88, 1.0, 1.0)
	core_visual.scale = Vector2.ONE
	core_visual.modulate = Color.WHITE
	core_ring.default_color = Color(0.20, 0.82, 1.0, 0.90)
	var duration := generator_regeneration_duration * (0.72 if current_phase >= 3 else 1.0)
	left_generator.modulate = Color(1.0, 1.0, 1.0, 0.18)
	right_generator.modulate = Color(1.0, 1.0, 1.0, 0.18)
	left_generator.scale = Vector2.ONE * 0.72
	right_generator.scale = Vector2.ONE * 0.72
	var regen := create_tween().set_parallel(true)
	regen.tween_property(left_generator, "modulate", Color.WHITE, duration)
	regen.tween_property(right_generator, "modulate", Color.WHITE, duration)
	regen.tween_property(left_generator, "scale", Vector2.ONE, duration)
	regen.tween_property(right_generator, "scale", Vector2.ONE, duration)
	regen.tween_property(shield_ring, "modulate", Color.WHITE, duration)
	regen.tween_property(shield_surface, "modulate", Color.WHITE, duration)
	regen.tween_property(shield_ring, "scale", Vector2.ONE, duration)
	regen.tween_property(shield_surface, "scale", Vector2.ONE, duration)
	await regen.finished
	if not accepting_damage:
		return
	# Tam dolu DEGIL: her yenilenme bir oncekinden zayif. Boylece oyuncunun
	# onceki turda verdigi jenerator hasari tamamen bosa gitmez ve dovus
	# her turda biraz kisalir.
	regeneration_count += 1
	var regenerated_hp: int = maxi(
		roundi(float(generator_max_hp) * pow(GENERATOR_REGEN_FALLOFF, float(regeneration_count))),
		GENERATOR_MIN_REGEN_HP
	)
	left_generator_hp = regenerated_hp
	right_generator_hp = regenerated_hp
	generator_state_changed.emit(true, true, true)
	status_feedback.emit("KALKAN YENİLENDİ", &"shield")
	print("THE SENTINEL GENERATORS REACTIVATED")

func _update_phase() -> void:
	var ratio := float(current_hp) / float(maxi(max_hp, 1))
	var next_phase := 1 if ratio > 0.60 else (2 if ratio > 0.30 else 3)
	if next_phase == current_phase:
		return
	current_phase = next_phase
	if current_phase == 3:
		print("THE SENTINEL ENRAGED")
		_play_core_pulse(Color(1.0, 0.22, 0.06, 1.0))
	else:
		_play_core_pulse(Color(1.0, 0.58, 0.18, 1.0))


func _get_move_speed() -> float:
	if current_phase >= 3:
		return move_speed_phase_3
	if current_phase == 2:
		return move_speed_phase_2
	return move_speed_phase_1


func _play_generator_hit(is_left: bool) -> void:
	var node := left_generator if is_left else right_generator
	node.modulate = Color(1.35, 0.82, 0.42, 1.0)
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", Color.WHITE, 0.09)


func _play_shield_feedback(hit_position: Vector2) -> void:
	shield_ring.visible = true
	shield_surface.visible = true
	shield_ring.modulate = Color(1.7, 1.85, 2.0, 1.0)
	shield_surface.modulate = Color(1.6, 1.9, 2.2, 1.0)
	var tween := shield_ring.create_tween().set_parallel(true)
	tween.tween_property(shield_ring, "modulate", Color.WHITE, 0.16)
	tween.tween_property(shield_surface, "modulate", Color.WHITE, 0.16)
	tween.tween_property(shield_ring, "scale", Vector2.ONE * 1.07, 0.07)
	tween.chain().tween_property(shield_ring, "scale", Vector2.ONE, 0.09)
	_spawn_shield_ripple(to_local(hit_position))
	var now := Time.get_ticks_msec()
	if shield_hint_count < 3 and now - last_shield_hint_msec >= 1200:
		shield_hint_count += 1
		last_shield_hint_msec = now
		status_feedback.emit("KALKAN AKT\u0130F", &"shield")

func _update_readability(delta: float) -> void:
	readability_time += delta
	var left_core := left_generator.get_node_or_null("Core") as Node2D
	var right_core := right_generator.get_node_or_null("Core") as Node2D
	if left_generator_hp > 0 and is_instance_valid(left_core):
		left_core.scale = Vector2.ONE * (1.0 + sin(readability_time * 3.2) * 0.07)
	if right_generator_hp > 0 and is_instance_valid(right_core):
		right_core.scale = Vector2.ONE * (1.0 + sin(readability_time * 3.2 + 1.4) * 0.07)
	if core_shielded:
		shield_surface.color.a = 0.10 + (sin(readability_time * 2.4) + 1.0) * 0.025
		return
	if exposure_end_msec <= 0:
		return
	var remaining := maxf(float(exposure_end_msec - Time.get_ticks_msec()) / 1000.0, 0.0)
	var pulse_speed := 9.0 if remaining <= 1.5 else 4.2
	var pulse := (sin(readability_time * pulse_speed) + 1.0) * 0.5
	core_visual.scale = Vector2.ONE * (1.0 + pulse * (0.10 if remaining <= 1.5 else 0.055))
	core_visual.modulate = Color(1.0 + pulse * 0.20, 1.0 + pulse * 0.08, 1.0, 1.0)


func _spawn_shield_ripple(local_hit: Vector2) -> void:
	var ripple := Line2D.new()
	ripple.z_index = 5
	ripple.width = 2.2
	ripple.default_color = Color(0.72, 0.98, 1.0, 0.92)
	ripple.antialiased = true
	var points := PackedVector2Array()
	for index in range(17):
		var angle := TAU * float(index) / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * 7.0)
	ripple.points = points
	ripple.position = local_hit.clamp(Vector2(-48.0, -48.0), Vector2(48.0, 48.0))
	visual_root.add_child(ripple)
	var tween := ripple.create_tween().set_parallel(true)
	tween.tween_property(ripple, "scale", Vector2.ONE * 3.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ripple, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(ripple.queue_free)


func _spawn_generator_burst(local_position: Vector2) -> void:
	for index in range(8):
		var spark := Polygon2D.new()
		spark.z_index = 6
		spark.polygon = PackedVector2Array([Vector2(-2.5, -1.0), Vector2(4.5, 0.0), Vector2(-2.5, 1.0)])
		spark.color = Color(0.55, 0.96, 1.0, 0.95) if index % 2 == 0 else Color(1.0, 0.58, 0.16, 0.92)
		spark.position = local_position
		spark.rotation = TAU * float(index) / 8.0
		visual_root.add_child(spark)
		var target := local_position + Vector2.RIGHT.rotated(spark.rotation) * randf_range(20.0, 36.0)
		var tween := spark.create_tween().set_parallel(true)
		tween.tween_property(spark, "position", target, randf_range(0.18, 0.28)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "modulate:a", 0.0, 0.26)
		tween.chain().tween_callback(spark.queue_free)


func _play_shield_break() -> void:
	for index in range(8):
		var fragment := Line2D.new()
		fragment.z_index = 6
		fragment.width = 3.0
		fragment.default_color = Color(0.45, 0.94, 1.0, 0.92)
		fragment.antialiased = true
		fragment.points = PackedVector2Array([Vector2(-7.0, 0.0), Vector2(7.0, 0.0)])
		var angle := TAU * float(index) / 8.0
		fragment.position = Vector2.RIGHT.rotated(angle) * 51.0
		fragment.rotation = angle + PI * 0.5
		visual_root.add_child(fragment)
		var tween := fragment.create_tween().set_parallel(true)
		tween.tween_property(fragment, "position", Vector2.RIGHT.rotated(angle) * 72.0, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(fragment, "modulate:a", 0.0, 0.26)
		tween.chain().tween_callback(fragment.queue_free)
	var fade := create_tween().set_parallel(true)
	fade.tween_property(shield_ring, "modulate:a", 0.0, 0.24)
	fade.tween_property(shield_surface, "modulate:a", 0.0, 0.24)
	fade.tween_property(shield_ring, "scale", Vector2.ONE * 1.18, 0.24)
	fade.tween_property(shield_surface, "scale", Vector2.ONE * 1.18, 0.24)
	await fade.finished
	if not core_shielded:
		shield_ring.visible = false
		shield_surface.visible = false

func _play_metal_feedback() -> void:
	visual_root.modulate = Color(1.18, 1.28, 1.35, 1.0)
	var tween := visual_root.create_tween()
	tween.tween_property(visual_root, "modulate", Color.WHITE, 0.08)


func _play_core_hit() -> void:
	core_visual.modulate = Color(1.55, 1.38, 1.12, 1.0)
	var tween := core_visual.create_tween().set_parallel(true)
	tween.tween_property(core_visual, "modulate", Color.WHITE, 0.09)
	tween.tween_property(core_visual, "scale", Vector2.ONE * 1.05, 0.045)
	tween.chain().tween_property(core_visual, "scale", Vector2.ONE, 0.05)


func _play_core_pulse(color: Color) -> void:
	core_visual.modulate = color
	var tween := core_visual.create_tween()
	tween.tween_property(core_visual, "modulate", Color.WHITE, 0.28)


func release_ball_contact(attacker_instance_id: int) -> void:
	active_ball_contacts.erase(attacker_instance_id)
	for source: StringName in DIRECT_BALL_SOURCES:
		for region: StringName in [&"left", &"core", &"right"]:
			last_damage_request_msec.erase("%s:%s:%d" % [region, source, attacker_instance_id])


func debug_instant_kill() -> void:
	if not accepting_damage:
		return
	core_shielded = false
	current_hp = 0
	health_changed.emit(current_hp, max_hp)
	_defeat()


func _defeat() -> void:
	if not accepting_damage:
		return
	accepting_damage = false
	combat_active = false
	exposure_token += 1
	collision_shape.set_deferred("disabled", true)
	if is_instance_valid(move_tween):
		move_tween.kill()
	for projectile: Node in get_tree().get_nodes_in_group("boss_projectile"):
		if is_instance_valid(projectile):
			projectile.queue_free()
	print("THE SENTINEL defeated")
	var fade := visual_root.create_tween().set_parallel(true)
	fade.tween_property(visual_root, "scale", Vector2.ONE * 1.14, 0.20)
	fade.tween_property(visual_root, "modulate", Color(1.45, 0.72, 0.34, 0.0), 0.70)
	await get_tree().create_timer(0.70).timeout
	defeated.emit()
	queue_free()
