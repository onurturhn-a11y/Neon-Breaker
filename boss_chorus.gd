extends "res://boss_sprite_entity.gd"

# ==================================================
# THE CHORUS - yeni boss (kadro sirasi 6)
#
# Imza mekanigi: cokluk. Tek govde degil, yavas donen bir halkada bes
# kucuk varlik. Ortak HP havuzu ama ayri ayri olduruluyorlar.
#
# Kadronun tek coklu hedefli dovusu. Dokuz silahin hangisini tasidigin
# burada fark eder: Arc zinciri, Scatter yelpazesi ve Mortar patlamasi
# besini birlikte eritir; saf tek hedefli bir build tek tek ugrasir.
# Ve her olum kalanlari hizlandirdigi icin sona kalan tek uye dovusun
# en tehlikeli anidir - yanlis sirayla oldurmek cezalandiriliyor.
#
# MIMARI NOTU: taban sinif tek govde varsayiyor. Uyeler ayri dugum degil,
# SENTINEL'in jenerator desenindeki gibi BOLGE olarak cozuldu -
# _region_from_global_hit vurusu en yakin uyeye yonlendiriyor. Boylece
# taban sinifin hasar/kilit/faz iskeleti oldugu gibi kullaniliyor.
# ==================================================

const VOICE_COUNT := 5
const VOICE_HP := 58
const VOICE_HIT_RADIUS := 46.0
const RING_RADIUS := 132.0
const RING_RADIUS_FALLOFF := 0.82
const SPIN_BASE := 14.0
const SPIN_PER_DEATH := 6.0
const SALVO_BASE := 2.6
const SALVO_PER_DEATH := 0.35
const NOTE_SPEED_SCALE := 0.78

var voices: Array[Dictionary] = []
var voice_root: Node2D
var ring_spin := 0.0
var deaths := 0
var duet_active := false
var duet_sprite: Sprite2D
var echo_done := false


func _get_boss_label() -> String:
	return "THE CHORUS"


func _get_base_hp() -> int:
	return VOICE_COUNT * VOICE_HP


func _get_extra_group() -> StringName:
	return &"chorus_boss"


func _get_frame_dir() -> String:
	return "res://assets/bosses/chorus/"


func _get_target_sprite_height() -> float:
	return 96.0


## duet_a.png taban sinifin sozlugunde yok; birlesmis form icin ekleniyor.
func _get_frame_sets() -> Dictionary:
	var sets := FRAME_SETS.duplicate(true)
	sets[&"duet"] = ["duet_a.png"]
	return sets


func _get_projectile_palette() -> Array:
	return [
		Color(0.55, 1.00, 0.92, 1.0),
		Color(0.75, 1.00, 0.96, 1.0),
		Color(0.91, 1.00, 0.98, 1.0),
	]


func _get_core_glow_alpha_scale() -> float:
	return 0.0


func _get_enrage_message() -> String:
	return "YANKI"


func _get_phase_message(phase: int) -> String:
	return "KORO FAZ %d" % phase


func _get_telegraph_duration() -> float:
	return 0.55


func _get_spin_speed() -> float:
	return SPIN_BASE + SPIN_PER_DEATH * float(deaths)


func _get_ring_radius() -> float:
	return RING_RADIUS * pow(RING_RADIUS_FALLOFF, float(deaths))


func _get_salvo_interval() -> float:
	return maxf(SALVO_BASE - SALVO_PER_DEATH * float(deaths), 1.0)


func _live_voices() -> Array[Dictionary]:
	var live: Array[Dictionary] = []
	for v: Dictionary in voices:
		if int(v.get("hp", 0)) > 0:
			live.append(v)
	return live


# ==================================================
# KURULUM
# ==================================================

func _ready() -> void:
	super()
	# Taban sinifin tek govde sprite'i kullanilmiyor; uyeleri kendimiz cizeriz.
	pose_a.visible = false
	pose_b.visible = false
	fallback_visual.visible = false
	voice_root = Node2D.new()
	voice_root.name = "VoiceRoot"
	visual_root.add_child(voice_root)
	_build_voices()


func _build_voices() -> void:
	var idle := _frame(&"idle", 0)
	var scale_factor := _resolve_pose_scale()
	for i in range(VOICE_COUNT):
		var holder := Node2D.new()
		voice_root.add_child(holder)
		var sprite := Sprite2D.new()
		sprite.texture = idle
		sprite.scale = Vector2.ONE * scale_factor
		holder.add_child(sprite)
		voices.append({"node": holder, "sprite": sprite, "hp": VOICE_HP, "index": i})
	_layout_ring()


func _layout_ring() -> void:
	var live := _live_voices()
	var n := live.size()
	if n <= 0:
		return
	var radius := _get_ring_radius()
	for i in range(n):
		var holder: Node2D = live[i].get("node")
		if not is_instance_valid(holder):
			continue
		var angle := deg_to_rad(ring_spin) + TAU * float(i) / float(n) - PI * 0.5
		holder.position = Vector2(cos(angle), sin(angle) * 0.55) * radius


func _physics_process(delta: float) -> void:
	super(delta)
	if duet_active or voices.is_empty():
		return
	ring_spin = fmod(ring_spin + _get_spin_speed() * delta, 360.0)
	_layout_ring()


# ==================================================
# HASAR YONLENDIRME
#
# Carpisma sekli halkanin tamamini kapsiyor; vurusun hangi uyeye ait
# oldugunu burada cozuyoruz. Halkanin bos ortasina gelen vurus hicbir
# uyeye yazilmaz - "miss" doner ve hasar uygulanmaz.
# ==================================================

func _region_from_global_hit(hit_position: Vector2) -> StringName:
	if duet_active:
		return &"duet"
	var local := to_local(hit_position)
	var best := -1
	var best_dist := VOICE_HIT_RADIUS
	for v: Dictionary in voices:
		if int(v.get("hp", 0)) <= 0:
			continue
		var holder: Node2D = v.get("node")
		if not is_instance_valid(holder):
			continue
		var d := local.distance_to(holder.position)
		if d <= best_dist:
			best_dist = d
			best = int(v.get("index", -1))
	return &"miss" if best < 0 else StringName("voice_%d" % best)


func _apply_region_hit(region: StringName, source: StringName, attacker_id: int, hit_position: Vector2) -> void:
	if not accepting_damage or region == &"miss":
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

	current_hp = maxi(current_hp - base_damage, 0)
	if not duet_active:
		var idx := int(String(region).replace("voice_", ""))
		for v: Dictionary in voices:
			if int(v.get("index", -1)) != idx:
				continue
			v["hp"] = maxi(int(v.get("hp", 0)) - base_damage, 0)
			if int(v["hp"]) <= 0:
				_kill_voice(v)
			break
	_play_armor_hit(hit_position)
	health_changed.emit(current_hp, max_hp)
	_flinch(hit_position)
	if current_hp <= 0:
		_defeat()
		return
	_update_phase()
	if not duet_active and _live_voices().size() == 2:
		_merge_duet()


func _kill_voice(v: Dictionary) -> void:
	deaths += 1
	var holder: Node2D = v.get("node")
	if is_instance_valid(holder):
		var sprite: Sprite2D = v.get("sprite")
		if is_instance_valid(sprite):
			sprite.texture = _frame(&"defeat", 0)
		var out := holder.create_tween().set_parallel(true)
		out.tween_property(holder, "modulate:a", 0.0, 0.45)
		out.tween_property(holder, "scale", Vector2(1.35, 1.35), 0.45)
		out.chain().tween_callback(holder.queue_free)
	status_feedback.emit("HALKA DARALDI", &"shield")
	_layout_ring()


## Son iki gövde merkezde birlesir; kalan HP'leriyle tek varlik olur.
func _merge_duet() -> void:
	duet_active = true
	var live := _live_voices()
	for v: Dictionary in live:
		var holder: Node2D = v.get("node")
		if is_instance_valid(holder):
			var t := holder.create_tween().set_parallel(true)
			t.tween_property(holder, "position", Vector2.ZERO, 1.1).set_trans(Tween.TRANS_SINE)
			t.tween_property(holder, "modulate:a", 0.0, 1.1)
			t.chain().tween_callback(holder.queue_free)
	status_feedback.emit("DÜET", &"exposed")
	get_tree().create_timer(1.1).timeout.connect(func() -> void:
		if not combat_active:
			return
		duet_sprite = Sprite2D.new()
		duet_sprite.texture = _frame(&"duet", 0)
		duet_sprite.scale = Vector2.ONE * _resolve_pose_scale()
		duet_sprite.modulate.a = 0.0
		voice_root.add_child(duet_sprite)
		duet_sprite.create_tween().tween_property(duet_sprite, "modulate:a", 1.0, 0.35)
	)


# ==================================================
# IMZA SALDIRILARI
# ==================================================

func _signature_loop() -> void:
	await get_tree().create_timer(2.0).timeout
	while combat_active and accepting_damage:
		await get_tree().create_timer(_get_salvo_interval()).timeout
		if not combat_active or not accepting_damage:
			return
		if current_phase >= 3 and duet_active and not echo_done:
			await _run_echo()
			continue
		if duet_active:
			await _run_duet_beam()
		else:
			await _run_note()


## Halka: siradaki uye girtlagi parlayarak tek bir yavas guduml nota yollar.
func _run_note() -> void:
	var live := _live_voices()
	if live.is_empty():
		return
	signature_active = true
	var v: Dictionary = live[randi() % live.size()]
	var sprite: Sprite2D = v.get("sprite")
	if is_instance_valid(sprite):
		sprite.texture = _frame(&"charge", 0)
	await get_tree().create_timer(_get_telegraph_duration()).timeout
	if not combat_active or not accepting_damage:
		signature_active = false
		return
	if is_instance_valid(sprite):
		sprite.texture = _frame(&"release", 0)
	var holder: Node2D = v.get("node")
	if is_instance_valid(holder):
		_fire_note(holder.global_position)
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(sprite):
		sprite.texture = _frame(&"idle", 0)
	signature_active = false


## Duet: iki girtlaktan cift isin; aralarindaki dar bosluk tek guvenli serit.
func _run_duet_beam() -> void:
	signature_active = true
	status_feedback.emit("ÇİFT IŞIN", &"exposed")
	await get_tree().create_timer(0.7).timeout
	if not combat_active or not accepting_damage:
		signature_active = false
		return
	var rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	var span := Vector2(global_position.y + 40.0, rect.end.y)
	for side: float in [-1.0, 1.0]:
		var root := Node2D.new()
		get_parent().add_child(root)
		root.z_index = 7
		root.global_position = Vector2(global_position.x + side * 27.0, 0.0)
		_add_gradient_band(root, span, 22.0, Color(0.30, 0.96, 0.90, 0.34), 70.0)
		_add_gradient_band(root, span, 11.0, Color(0.86, 1.00, 0.96, 0.86), 52.0)
		_apply_additive(root)
		var fade := root.create_tween()
		fade.tween_interval(0.6)
		fade.tween_property(root, "modulate:a", 0.0, 0.25)
		fade.tween_callback(root.queue_free)
	_shake_world(3.5)
	await get_tree().create_timer(0.9).timeout
	signature_active = false


## Yanki: olu uyelerin hayaleti eski duzende belirir ve HEPSI ayni anda
## tek salvo atar. Hayaletler vurulamaz, sadece ates eder.
func _run_echo() -> void:
	echo_done = true
	signature_active = true
	status_feedback.emit("YANKI", &"exposed")
	var idle := _frame(&"idle", 0)
	var scale_factor := _resolve_pose_scale()
	var ghosts: Array[Node2D] = []
	for i in range(VOICE_COUNT):
		var ghost := Sprite2D.new()
		ghost.texture = idle
		ghost.scale = Vector2.ONE * scale_factor
		ghost.modulate = Color(0.65, 1.0, 0.95, 0.0)
		voice_root.add_child(ghost)
		var angle := TAU * float(i) / float(VOICE_COUNT) - PI * 0.5
		ghost.position = Vector2(cos(angle), sin(angle) * 0.55) * RING_RADIUS
		ghost.create_tween().tween_property(ghost, "modulate:a", 0.55, 0.5)
		ghosts.append(ghost)
	await get_tree().create_timer(1.2).timeout
	if combat_active and accepting_damage:
		for ghost: Node2D in ghosts:
			if is_instance_valid(ghost):
				_fire_note(ghost.global_position)
		_shake_world(5.0)
	await get_tree().create_timer(1.4).timeout
	for ghost: Node2D in ghosts:
		if is_instance_valid(ghost):
			var out := ghost.create_tween()
			out.tween_property(ghost, "modulate:a", 0.0, 0.45)
			out.tween_callback(ghost.queue_free)
	signature_active = false


func _fire_note(from: Vector2) -> void:
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		return
	var projectile: Node2D = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = from
	projectile.setup(get_parent(), (paddle.global_position - from).normalized(), projectile_speed * NOTE_SPEED_SCALE)
	var palette := _get_projectile_palette()
	if projectile.has_method("apply_palette") and palette.size() >= 3:
		projectile.apply_palette(_get_shard_texture(), palette[0], palette[1], palette[2])
	if get_parent().has_method("notify_boss_projectile_fired"):
		get_parent().notify_boss_projectile_fired()


## Taban sinif tek govdeyi gizledigi icin idle nefesini biz suruyoruz.
func _update_pose_motion(delta: float) -> void:
	super(delta)
	if not is_instance_valid(voice_root):
		return
	voice_root.position.y = sin(Time.get_ticks_msec() * 0.0016) * 5.0
