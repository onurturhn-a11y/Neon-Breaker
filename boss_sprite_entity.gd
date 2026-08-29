extends StaticBody2D

# ==================================================
# SPRITE SHEET BOSS - ORTAK ISKELET
#
# THE CELESTIAL ve THE VOID ENTITY ayni sheet duzenini ve ayni
# oynatma sistemini paylasiyor. Burada duran her sey boss'tan
# bagimsiz: poz harmanlama, prosedural hareket, hareket/ates
# donguleri, zayif nokta hasari, fazlar, yenilgi.
#
# Bosslara ozel olan tek sey "imza saldirisi" ve konfigurasyon;
# onlari asagidaki _get_* / _signature_loop kancalari uzerinden
# alt siniflar veriyor.
# ==================================================

signal health_changed(current_hp: int, max_hp: int)
signal status_feedback(message: String, tone: StringName)
signal defeated

@export var max_hp: int = 180
@export var entry_duration: float = 1.1
@export var move_speed_phase_1: float = 58.0
@export var move_speed_phase_2: float = 74.0
@export var move_speed_phase_3: float = 88.0
@export var fire_interval_min: float = 2.4
@export var fire_interval_max: float = 2.9
@export var projectile_speed: float = 350.0
@export var ball_hit_lock_duration: float = 0.12
@export var mobile_scale_multiplier: float = 1.12
## 0 birakilirsa sprite otomatik olarak hedef yukseklige olceklenir.
@export var sprite_scale_override: float = 0.0

const PROJECTILE_SCENE = preload("res://boss_projectile.tscn")
const DIRECT_BALL_SOURCES: Array[StringName] = [&"ball", &"piercing_ball", &"fireball_ball"]

const BODY_HALF_WIDTH := 90.0
const BODY_HALF_HEIGHT := 90.0
const CORE_LOCAL := Vector2(0.0, 0.0)
const CORE_HIT_RADIUS := 34.0

const FRAME_SETS := {
	&"idle": ["idle_a.png", "idle_b.png"],
	&"charge": ["attack_charge.png"],
	&"release": ["attack_release.png"],
	&"hit": ["hit_a.png", "hit_b.png"],
	&"defeat": ["defeat_a.png"],
}
const IDLE_BLEND_SPEED := 1.55
const HOVER_SPEED := 1.55
const HOVER_AMPLITUDE := 5.0

var current_hp := 180
var accepting_damage := true
var combat_active := false
var signature_active := false
var current_phase := 1
var move_tween: Tween
var active_ball_contacts: Dictionary = {}
var last_damage_request_msec: Dictionary = {}
var readability_time := 0.0
var projectile_block_until_msec := 0
var using_sprite_frames := false
var pose_frames: Dictionary = {}
var pose_texture_a: Texture2D
var pose_texture_b: Texture2D
var pose_blend := 0.0
var pose_state: StringName = &"idle"
var pose_transition_active := false
var pose_tween: Tween
var impulse_tween: Tween
var tremble_tween: Tween
var impulse_offset := Vector2.ZERO
var impulse_scale := Vector2.ONE
var pose_bank := 0.0
var defeat_tilt := 0.0
var tremble := 0.0
var idle_blend_time := 0.0
var previous_x := 0.0
var additive_material: CanvasItemMaterial
var beam_blob_texture: ImageTexture
var beam_body_texture: ImageTexture
var beam_cap_texture: ImageTexture
var shard_texture: Texture2D
var shard_texture_loaded := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_root: Node2D = $VisualRoot
@onready var pose_root: Node2D = $VisualRoot/PoseRoot
@onready var pose_a: Sprite2D = $VisualRoot/PoseRoot/PoseA
@onready var pose_b: Sprite2D = $VisualRoot/PoseRoot/PoseB
@onready var fallback_visual: Node2D = $VisualRoot/PoseRoot/FallbackVisual
@onready var core_visual: Polygon2D = $VisualRoot/PoseRoot/FallbackVisual/ChestCore
@onready var core_glow: Polygon2D = $VisualRoot/CoreGlow


# ==================================================
# ALT SINIF KANCALARI
# ==================================================

func _get_boss_label() -> String:
	return "BOSS"


## Her boss kendi dayanikliligini bildirir; taban deger yalnizca guvenlik agidir.
func _get_base_hp() -> int:
	return 180


func _get_extra_group() -> StringName:
	return &""


func _get_frame_dir() -> String:
	return ""


func _get_shard_texture_path() -> String:
	return ""


func _get_target_sprite_height() -> float:
	return 200.0


## Bos dizi donerse mermi varsayilan (THE CORE) gorunumunde kalir.
func _get_projectile_palette() -> Array:
	return []


## Bossun imza saldirisi. Taban sinifta yok; alt sinif doldurur.
func _signature_loop() -> void:
	pass


## Kullanilacak poz kareleri. Alt sinif ek poz (charge_2 gibi) ekleyebilir.
func _get_frame_sets() -> Dictionary:
	return FRAME_SETS


## Sarj pozunun ne kadar sureyle titreyecegi.
func _get_telegraph_duration() -> float:
	return 1.0


## Yenilgi patlamasi. Alt sinif kendi temasina gore doldurabilir.
func _spawn_defeat_burst() -> void:
	pass


## Zayif noktayi isaretleyen parlamanin siddeti. Void bosslarinda gogus
## zaten kara delik oldugu icin dolu bir parlama onun ustunu ortuyordu.
func _get_core_glow_alpha_scale() -> float:
	return 1.0


func _get_enrage_message() -> String:
	return "ÖFKE"


func _get_phase_message(phase: int) -> String:
	return "FAZ %d" % phase


func _ready() -> void:
	if OS.has_feature("mobile"):
		scale *= mobile_scale_multiplier
	add_to_group("game_boss")
	var extra := _get_extra_group()
	if extra != &"":
		add_to_group(extra)
	max_hp = maxi(roundi(
		float(_get_base_hp()) * GameManager.get_ascension_boss_hp_scale()
	), 1)
	current_hp = max_hp
	collision_shape.disabled = true
	previous_x = global_position.x
	using_sprite_frames = _load_pose_textures()
	pose_a.visible = using_sprite_frames
	pose_b.visible = using_sprite_frames
	fallback_visual.visible = not using_sprite_frames
	_play_anim(&"idle")
	if OS.is_debug_build():
		print("%s VISUAL: %s" % [_get_boss_label(), "sprite sheet" if using_sprite_frames else "procedural fallback"])
	health_changed.emit(current_hp, max_hp)


# ==================================================
# SPRITE SHEET YUKLEME + POZ HARMANLAMA
#
# Elde 7 kare var; AnimatedSprite2D bunlari sert kesmeyle oynatinca
# ozellikle 2 kareli idle takirdiyordu. Bunun yerine iki Sprite2D
# katmani ust uste duruyor ve aralarinda surekli capraz gecis yapiliyor.
# Uzerine prosedural hareket (suzulme, nefes, yatma, geri tepme) biniyor.
# ==================================================
func _load_pose_textures() -> bool:
	for anim_name: StringName in _get_frame_sets():
		var textures: Array[Texture2D] = []
		for file_name: String in _get_frame_sets()[anim_name]:
			var path: String = _get_frame_dir() + file_name
			if not ResourceLoader.exists(path):
				continue
			var texture := load(path) as Texture2D
			if texture != null:
				textures.append(texture)
		if not textures.is_empty():
			pose_frames[anim_name] = textures
	if not pose_frames.has(&"idle"):
		return false
	var base_scale := _resolve_pose_scale()
	for sprite: Sprite2D in [pose_a, pose_b]:
		sprite.scale = Vector2.ONE * base_scale
		sprite.visible = true
	pose_texture_a = _frame(&"idle", 0)
	pose_texture_b = _frame(&"idle", 0)
	pose_blend = 0.0
	_apply_pose()
	return true
func _resolve_pose_scale() -> float:
	if sprite_scale_override > 0.0:
		return sprite_scale_override
	var reference := _frame(&"idle", 0)
	if reference == null or reference.get_height() <= 0:
		return 1.0
	return _get_target_sprite_height() / float(reference.get_height())
func _frame(anim_name: StringName, index: int) -> Texture2D:
	if not pose_frames.has(anim_name):
		return null
	var textures: Array = pose_frames[anim_name]
	if textures.is_empty():
		return null
	return textures[clampi(index, 0, textures.size() - 1)]
func _apply_pose() -> void:
	if not using_sprite_frames:
		return
	pose_a.texture = pose_texture_a
	pose_b.texture = pose_texture_b
	pose_b.self_modulate.a = pose_blend
func _set_pose_blend(value: float) -> void:
	pose_blend = value
	_apply_pose()
func _visible_pose_texture() -> Texture2D:
	return pose_texture_b if pose_blend >= 0.5 else pose_texture_a


# Gorunen kareyi A'ya sabitleyip hedefi B'ye alir, sonra araya gecis koyar.
func _blend_to(target: Texture2D, duration: float) -> Tween:
	if target == null:
		return null
	pose_texture_a = _visible_pose_texture()
	pose_texture_b = target
	pose_blend = 0.0
	_apply_pose()
	pose_transition_active = true
	if is_instance_valid(pose_tween):
		pose_tween.kill()
	pose_tween = create_tween()
	pose_tween.tween_method(_set_pose_blend, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE)
	return pose_tween
func _settle_pose() -> void:
	pose_texture_a = pose_texture_b
	pose_blend = 0.0
	_apply_pose()
	pose_transition_active = false
func _play_anim(anim_name: StringName) -> void:
	if not using_sprite_frames:
		return
	if pose_state == anim_name and anim_name == &"idle":
		return
	pose_state = anim_name
	match anim_name:
		&"idle":
			var to_idle := _blend_to(_frame(&"idle", 0), 0.18)
			if to_idle != null:
				to_idle.tween_callback(func() -> void:
					_settle_pose()
					idle_blend_time = 0.0)
			_tween_tremble(0.0, 0.14)
		&"charge":
			var to_charge := _blend_to(_frame(&"charge", 0), 0.20)
			if to_charge != null:
				to_charge.tween_callback(_settle_pose)
			_tween_tremble(3.0, _get_telegraph_duration())
			_impulse(Vector2(0.0, -7.0), Vector2(0.97, 1.05), 0.22)
		&"release":
			var to_release := _blend_to(_frame(&"release", 0), 0.03)
			if to_release != null:
				to_release.tween_callback(_settle_pose)
			_tween_tremble(0.0, 0.06)
			_recoil()
		&"hit":
			_hit_sequence()
		&"defeat":
			var to_defeat := _blend_to(_frame(&"defeat", 0), 0.24)
			if to_defeat != null:
				to_defeat.tween_callback(_settle_pose)
			_tween_tremble(0.0, 0.10)
			_defeat_motion()
		_:
			# Alt siniflarin ek pozlari (charge_2 / release_2 gibi).
			var is_release := String(anim_name).begins_with("release")
			var to_extra := _blend_to(_frame(anim_name, 0), 0.03 if is_release else 0.20)
			if to_extra != null:
				to_extra.tween_callback(_settle_pose)
			if is_release:
				_tween_tremble(0.0, 0.06)
				_recoil()
			else:
				_tween_tremble(3.0, _get_telegraph_duration())
				_impulse(Vector2(0.0, -7.0), Vector2(0.97, 1.05), 0.22)
func _hit_sequence() -> void:
	if not pose_frames.has(&"hit"):
		return
	var hit_frames: Array = pose_frames[&"hit"]
	# Darbe kareleri keskin gecsin: capraz gecis burada vurusu koreltiyor
	# ve siluetler farkli oldugu icin hayal goruntu birakiyor. Donus yumusak.
	var sequence := _blend_to(hit_frames[0], 0.025)
	if sequence == null:
		return
	sequence.tween_interval(0.07)
	if hit_frames.size() > 1:
		sequence.tween_callback(func() -> void:
			pose_texture_a = hit_frames[0]
			pose_texture_b = hit_frames[1]
			pose_blend = 0.0
			_apply_pose())
		sequence.tween_method(_set_pose_blend, 0.0, 1.0, 0.025)
		sequence.tween_interval(0.07)
	sequence.tween_callback(func() -> void:
		_settle_pose()
		_return_to_idle())
func _return_to_idle() -> void:
	if not accepting_damage:
		return
	if signature_active and pose_state in [&"charge", &"release"]:
		return
	_play_anim(&"idle")


# ==================================================
# PROSEDURAL HAREKET
# ==================================================
func _impulse(offset: Vector2, squash: Vector2, duration: float) -> void:
	if is_instance_valid(impulse_tween):
		impulse_tween.kill()
	impulse_offset = offset
	impulse_scale = squash
	impulse_tween = create_tween().set_parallel(true)
	impulse_tween.tween_property(self, "impulse_offset", Vector2.ZERO, duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	impulse_tween.tween_property(self, "impulse_scale", Vector2.ONE, duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
func _recoil() -> void:
	_impulse(Vector2(0.0, -16.0), Vector2(1.10, 0.90), 0.45)
func _flinch(from_position: Vector2) -> void:
	var away := (global_position - from_position)
	if away.length() < 0.01:
		away = Vector2.UP
	away = away.normalized() * 11.0
	_impulse(away, Vector2(0.92, 1.08), 0.34)
func _defeat_motion() -> void:
	if is_instance_valid(impulse_tween):
		impulse_tween.kill()
	impulse_tween = create_tween().set_parallel(true)
	impulse_tween.tween_property(self, "impulse_offset", Vector2(0.0, 26.0), 0.80).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	impulse_tween.tween_property(self, "impulse_scale", Vector2(0.94, 0.94), 0.80)
	impulse_tween.tween_property(self, "defeat_tilt", 0.22, 0.80).set_trans(Tween.TRANS_SINE)
func _tween_tremble(target: float, duration: float) -> void:
	if is_instance_valid(tremble_tween):
		tremble_tween.kill()
	tremble_tween = create_tween()
	tremble_tween.tween_property(self, "tremble", target, maxf(duration, 0.05))
func _update_pose_motion(delta: float) -> void:
	if not is_instance_valid(pose_root):
		return
	idle_blend_time += delta

	# Idle: iki kare arasinda kesintisiz gidip gelme. cos ile basladigi
	# noktada blend 0 oldugu icin gecisten sonra ziplama olmuyor.
	if using_sprite_frames and pose_state == &"idle" and not pose_transition_active:
		var idle_textures: Array = pose_frames.get(&"idle", [])
		if idle_textures.size() >= 2:
			pose_texture_a = idle_textures[0]
			pose_texture_b = idle_textures[1]
			pose_blend = (1.0 - cos(idle_blend_time * IDLE_BLEND_SPEED)) * 0.5
			_apply_pose()

	var hover := sin(idle_blend_time * HOVER_SPEED) * HOVER_AMPLITUDE
	var breathe := 1.0 + sin(idle_blend_time * HOVER_SPEED) * 0.014

	# Yatay hiza gore hafif yatma: kaydigi yone dogru egiliyor.
	var velocity_x := (global_position.x - previous_x) / maxf(delta, 0.0001)
	previous_x = global_position.x
	var bank_target := clampf(velocity_x * 0.0016, -0.11, 0.11) + defeat_tilt
	pose_bank = lerp_angle(pose_bank, bank_target, clampf(delta * 5.0, 0.0, 1.0))

	var shake := Vector2.ZERO
	if tremble > 0.01:
		shake = Vector2(randf_range(-tremble, tremble), randf_range(-tremble, tremble))

	pose_root.position = Vector2(0.0, hover) + impulse_offset + shake
	pose_root.scale = Vector2(breathe, breathe) * impulse_scale
	pose_root.rotation = pose_bank


# ==================================================
# YASAM DONGUSU
# ==================================================
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
	call_deferred("_signature_loop")
func _physics_process(delta: float) -> void:
	_update_readability(delta)
	_update_pose_motion(delta)
	if not accepting_damage:
		return
	_update_phase()
	var release_distance := BODY_HALF_WIDTH * absf(global_scale.x) + 42.0
	for attacker_id: int in active_ball_contacts.keys():
		var attacker := instance_from_id(attacker_id) as Node2D
		if not is_instance_valid(attacker) or attacker.global_position.distance_to(global_position) > release_distance:
			active_ball_contacts.erase(attacker_id)
func _movement_loop() -> void:
	while combat_active and accepting_damage:
		if signature_active:
			await get_tree().create_timer(0.12).timeout
			continue
		var safe_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
		var half_width := BODY_HALF_WIDTH * absf(global_scale.x)
		var left_bound := safe_rect.position.x + half_width + 12.0
		var right_bound := safe_rect.end.x - half_width - 12.0
		var target_x := safe_rect.get_center().x
		if right_bound > left_bound:
			target_x = randf_range(left_bound, right_bound)
		var duration := maxf(absf(target_x - global_position.x) / _get_move_speed(), 0.16)
		move_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		move_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		move_tween.tween_property(self, "global_position:x", target_x, duration)
		await _wait_for_move_tween()
		if not combat_active:
			return
		await get_tree().create_timer(randf_range(0.30, 0.62)).timeout


# kill() edilen bir Tween "finished" sinyalini HIC yaymaz. Dogrudan
# await etmek, isin saldirisi tween'i oldurdugu anda hareket dongusunu
# sonsuza kadar askida birakiyordu: boss ilk isindan sonra bir daha
# kipirdamiyordu. is_valid() hem bitisi hem oldurulmeyi yakalar.
func _wait_for_move_tween() -> void:
	while is_instance_valid(move_tween) and move_tween.is_valid():
		await get_tree().physics_frame
func _fire_loop() -> void:
	while combat_active and accepting_damage:
		var interval := randf_range(fire_interval_min, fire_interval_max)
		if current_phase >= 3:
			interval *= 0.85
		await get_tree().create_timer(interval).timeout
		if not combat_active or not accepting_damage:
			return
		if signature_active:
			continue
		await _wait_for_projectile_clearance()
		if not combat_active or not accepting_damage or signature_active:
			return
		_fire_shard()
func _fire_shard() -> void:
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		return
	var muzzle := Vector2(randf_range(-52.0, 52.0), 34.0)
	var projectile := PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = to_global(muzzle)
	projectile.setup(get_parent(), (paddle.global_position - projectile.global_position).normalized(), projectile_speed)
	var palette := _get_projectile_palette()
	if projectile.has_method("apply_palette") and palette.size() >= 3:
		projectile.apply_palette(_get_shard_texture(), palette[0], palette[1], palette[2])
	if get_parent().has_method("notify_boss_projectile_fired"):
		get_parent().notify_boss_projectile_fired()


# Mermi dokusu boss paletine gore renk kaydirilmis ayri bir dosya.
# Yoksa THE CORE'un turuncu mermisi kullanilmaya devam eder.
func _get_shard_texture() -> Texture2D:
	if not shard_texture_loaded:
		shard_texture_loaded = true
		var path := _get_shard_texture_path()
		if path != "" and ResourceLoader.exists(path):
			shard_texture = load(path) as Texture2D
	return shard_texture
func delay_projectile_after_side_wave(seconds: float) -> void:
	projectile_block_until_msec = maxi(
		projectile_block_until_msec,
		Time.get_ticks_msec() + int(seconds * 1000.0)
	)
func _wait_for_projectile_clearance() -> void:
	var wait_seconds := float(projectile_block_until_msec - Time.get_ticks_msec()) / 1000.0
	if wait_seconds > 0.0:
		await get_tree().create_timer(wait_seconds).timeout


# ==================================================
# PRIZMA SUTUNU (imza saldirisi)
# ==================================================
func _get_additive_material() -> CanvasItemMaterial:
	if additive_material == null:
		additive_material = CanvasItemMaterial.new()
		additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return additive_material


# Toplamali harmanlama enerji gorselini karartmadan ust uste bindirir.
# Materyal cocuklara kendiliginden gecmez, agaci gezip tek tek atiyoruz.
func _apply_additive(node: Node) -> void:
	for child: Node in node.get_children():
		if child is CanvasItem:
			(child as CanvasItem).material = _get_additive_material()
		_apply_additive(child)
func _shake_world(amplitude: float) -> void:
	var shaker := get_parent().get_node_or_null("WorldShake")
	if shaker != null and shaker.has_method("start_break"):
		shaker.start_break(amplitude)
func _edge_falloff(t: float) -> float:
	var v := clampf(1.0 - t, 0.0, 1.0)
	return v * v * (3.0 - 2.0 * v)
func _get_beam_blob_texture() -> ImageTexture:
	if beam_blob_texture == null:
		var image := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
		for x in range(64):
			var fx := _edge_falloff(absf(float(x) - 31.5) / 31.5)
			for y in range(64):
				var fy := _edge_falloff(absf(float(y) - 31.5) / 31.5)
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, fx * fy))
		beam_blob_texture = ImageTexture.create_from_image(image)
	return beam_blob_texture
func _add_sprite(root: Node2D, texture: Texture2D, tint: Color, at: Vector2, size: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.modulate = tint
	sprite.position = at
	sprite.scale = Vector2(
		size.x / float(texture.get_width()),
		size.y / float(texture.get_height())
	)
	root.add_child(sprite)
	return sprite
func _get_paddle_half_width(paddle: Node2D) -> float:
	var shape_node := paddle.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if is_instance_valid(shape_node):
		var rect_shape := shape_node.shape as RectangleShape2D
		if rect_shape != null:
			return rect_shape.size.x * 0.5 * absf(paddle.global_scale.x)
	return 60.0


# ==================================================
# HASAR
# ==================================================
func hit_from_ball_at(attacker_instance_id: int, source: StringName, hit_position: Vector2) -> void:
	_apply_region_hit(_region_from_global_hit(hit_position), source, attacker_instance_id, hit_position)
func hit_from_plasma_at(attacker_instance_id: int, hit_position: Vector2) -> void:
	_apply_region_hit(_region_from_global_hit(hit_position), &"plasma", attacker_instance_id, hit_position)
func hit_from_ball(attacker_instance_id: int, source: StringName = &"ball") -> void:
	_apply_region_hit(&"armor", source, attacker_instance_id, global_position)
func hit_from_plasma(attacker_instance_id: int) -> void:
	_apply_region_hit(&"armor", &"plasma", attacker_instance_id, global_position)
func _region_from_global_hit(hit_position: Vector2) -> StringName:
	if to_local(hit_position).distance_to(CORE_LOCAL) <= CORE_HIT_RADIUS:
		return &"core"
	return &"armor"
func _apply_region_hit(region: StringName, source: StringName, attacker_id: int, hit_position: Vector2) -> void:
	if not accepting_damage:
		return
	var base_damage := GameManager.resolve_boss_direct_hit_damage(source)
	if base_damage <= 0:
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

	var damage := base_damage
	if region == &"core":
		damage = base_damage * 2
		_play_core_hit(hit_position)
	else:
		damage = base_damage
		_play_armor_hit(hit_position)

	current_hp = maxi(current_hp - damage, 0)
	if OS.is_debug_build():
		print("%s HIT | region=%s | source=%s | damage=%d | HP=%d/%d" % [_get_boss_label(), region, source, damage, current_hp, max_hp])
	health_changed.emit(current_hp, max_hp)
	if not signature_active:
		_play_anim(&"hit")
	_flinch(hit_position)
	if current_hp <= 0:
		_defeat()
	else:
		_update_phase()
func release_ball_contact(attacker_instance_id: int) -> void:
	active_ball_contacts.erase(attacker_instance_id)
	for source: StringName in DIRECT_BALL_SOURCES:
		for region: StringName in [&"core", &"armor"]:
			last_damage_request_msec.erase("%s:%s:%d" % [region, source, attacker_instance_id])
func _update_phase() -> void:
	var ratio := float(current_hp) / float(maxi(max_hp, 1))
	var next_phase := 1 if ratio > 0.65 else (2 if ratio > 0.32 else 3)
	if next_phase == current_phase:
		return
	current_phase = next_phase
	if current_phase == 3:
		status_feedback.emit(_get_enrage_message(), &"exposed")
		print("%s ENRAGED" % _get_boss_label())
	else:
		status_feedback.emit(_get_phase_message(current_phase), &"shield")
	_play_phase_pulse()
func _get_move_speed() -> float:
	if current_phase >= 3:
		return move_speed_phase_3
	if current_phase == 2:
		return move_speed_phase_2
	return move_speed_phase_1


# ==================================================
# GORSEL GERI BILDIRIM
# ==================================================
func _update_readability(delta: float) -> void:
	readability_time += delta
	if not is_instance_valid(core_glow):
		return
	var pulse := (sin(readability_time * 2.6) + 1.0) * 0.5
	var intensity := 0.16 + pulse * 0.10
	if current_phase >= 3:
		intensity += 0.10
	core_glow.color.a = intensity * _get_core_glow_alpha_scale()
	core_glow.scale = Vector2.ONE * (1.0 + pulse * 0.06)
func _play_core_hit(hit_position: Vector2) -> void:
	visual_root.modulate = Color(1.65, 1.42, 1.85, 1.0)
	var tween := visual_root.create_tween()
	tween.tween_property(visual_root, "modulate", Color.WHITE, 0.11)
	_spawn_hit_ripple(to_local(hit_position), Color(1.0, 0.72, 1.0, 0.95), 3.4)
func _play_armor_hit(hit_position: Vector2) -> void:
	visual_root.modulate = Color(1.18, 1.24, 1.32, 1.0)
	var tween := visual_root.create_tween()
	tween.tween_property(visual_root, "modulate", Color.WHITE, 0.08)
	_spawn_hit_ripple(to_local(hit_position), Color(0.62, 0.94, 1.0, 0.72), 2.2)
func _spawn_hit_ripple(local_hit: Vector2, color: Color, growth: float) -> void:
	var ripple := Line2D.new()
	ripple.z_index = 5
	ripple.width = 2.2
	ripple.default_color = color
	ripple.antialiased = true
	var points := PackedVector2Array()
	for index in range(17):
		var angle := TAU * float(index) / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * 7.0)
	ripple.points = points
	ripple.position = local_hit.clamp(
		Vector2(-BODY_HALF_WIDTH, -BODY_HALF_HEIGHT),
		Vector2(BODY_HALF_WIDTH, BODY_HALF_HEIGHT)
	)
	visual_root.add_child(ripple)
	var tween := ripple.create_tween().set_parallel(true)
	tween.tween_property(ripple, "scale", Vector2.ONE * growth, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ripple, "modulate:a", 0.0, 0.20)
	tween.chain().tween_callback(ripple.queue_free)
func _play_phase_pulse() -> void:
	var target := Color(1.0, 0.42, 0.92, 1.0) if current_phase >= 3 else Color(0.62, 1.0, 1.0, 1.0)
	visual_root.modulate = target
	var tween := visual_root.create_tween()
	tween.tween_property(visual_root, "modulate", Color.WHITE, 0.30)
	if is_instance_valid(core_visual):
		core_visual.color = Color(1.0, 0.44, 0.88, 1.0) if current_phase >= 3 else Color(1.0, 0.78, 0.32, 1.0)


# ==================================================
# OLUM
# ==================================================
func debug_instant_kill() -> void:
	if not accepting_damage:
		return
	current_hp = 0
	health_changed.emit(current_hp, max_hp)
	_defeat()
func _defeat() -> void:
	if not accepting_damage:
		return
	accepting_damage = false
	combat_active = false
	signature_active = false
	collision_shape.set_deferred("disabled", true)
	if is_instance_valid(move_tween):
		move_tween.kill()
	for projectile: Node in get_tree().get_nodes_in_group("boss_projectile"):
		if is_instance_valid(projectile):
			projectile.queue_free()
	_play_anim(&"defeat")
	print("%s defeated" % _get_boss_label())
	_spawn_defeat_burst()
	var fade := visual_root.create_tween().set_parallel(true)
	fade.tween_property(visual_root, "scale", Vector2.ONE * 1.16, 0.24)
	fade.tween_property(visual_root, "modulate", Color(1.6, 1.0, 1.8, 0.0), 0.80)
	await get_tree().create_timer(0.80).timeout
	defeated.emit()
	queue_free()


func _column_polygon(half: float, span: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-half, span.x), Vector2(half, span.x),
		Vector2(half, span.y), Vector2(-half, span.y)
	])
func _get_beam_body_texture() -> ImageTexture:
	if beam_body_texture == null:
		var image := Image.create_empty(64, 1, false, Image.FORMAT_RGBA8)
		for x in range(64):
			var t := absf(float(x) - 31.5) / 31.5
			image.set_pixel(x, 0, Color(1.0, 1.0, 1.0, _edge_falloff(t)))
		beam_body_texture = ImageTexture.create_from_image(image)
	return beam_body_texture
func _get_beam_cap_texture() -> ImageTexture:
	if beam_cap_texture == null:
		var image := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
		for x in range(64):
			var fx := _edge_falloff(absf(float(x) - 31.5) / 31.5)
			for y in range(64):
				var fy := float(y) / 63.0
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, fx * fy * fy))
		beam_cap_texture = ImageTexture.create_from_image(image)
	return beam_cap_texture
func _add_gradient_band(root: Node2D, span: Vector2, half: float, tint: Color, fade: float) -> void:
	var y1 := minf(span.x + fade, span.y)
	_add_sprite(root, _get_beam_body_texture(), tint,
		Vector2(0.0, (y1 + span.y) * 0.5), Vector2(half * 2.0, maxf(span.y - y1, 1.0)))
	_add_sprite(root, _get_beam_cap_texture(), tint,
		Vector2(0.0, (span.x + y1) * 0.5), Vector2(half * 2.0, maxf(y1 - span.x, 1.0)))
