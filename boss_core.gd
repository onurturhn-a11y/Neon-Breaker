extends StaticBody2D

signal health_changed(current_hp: int, max_hp: int)
signal defeated

@export var max_hp: int = 100
@export var entry_duration: float = 1.0
@export_range(90.0, 130.0, 5.0) var move_speed: float = 110.0
@export_range(0.25, 0.70, 0.05) var move_pause_min: float = 0.25
@export_range(0.25, 0.70, 0.05) var move_pause_max: float = 0.70
@export_range(1.8, 2.4, 0.1) var fire_interval_min: float = 1.8
@export_range(1.8, 2.4, 0.1) var fire_interval_max: float = 2.4
@export_range(320.0, 380.0, 5.0) var projectile_speed: float = 350.0
@export var telegraph_duration: float = 0.35
@export_range(3.0, 5.0, 0.5) var recoil_distance: float = 4.0
@export_range(0.08, 0.16, 0.01) var ball_hit_lock_duration: float = 0.12
@export_range(1.0, 1.6, 0.05) var mobile_boss_scale_multiplier: float = 1.35

const PROJECTILE_SCENE = preload("res://boss_projectile.tscn")
const MAX_ACTIVE_CORE_PROJECTILES := 2
var owned_projectiles: Array[WeakRef] = []

## Ayni anda ucusta olabilecek en fazla mermi. Ates araligi 1.8-2.4s ve
## mermi ekrani gecmesi daha uzun surdugu icin ust uste birikebiliyordu.
const MAX_ACTIVE_PROJECTILES := 2

var current_hp: int = 100
var accepting_damage := true
var phase_one_active := false
var hit_tween: Tween
var move_tween: Tween
var charge_tween: Tween
var last_damage_request_msec: Dictionary = {}
var active_ball_contacts: Dictionary = {}
var projectile_phase := 1
var phase_pulse_tween: Tween

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_root: Node2D = $VisualRoot
@onready var energy_core: Polygon2D = $VisualRoot/EnergyCore


func _ready() -> void:
	if OS.has_feature("mobile"):
		scale *= mobile_boss_scale_multiplier
	add_to_group("game_boss")
	# Ascension katmani boss dayanikliligini da olcekler.
	max_hp = maxi(roundi(float(max_hp) * GameManager.get_ascension_boss_hp_scale()), 1)
	current_hp = max_hp
	projectile_phase = get_projectile_phase()
	collision_shape.disabled = true
	health_changed.emit(current_hp, max_hp)


func _physics_process(_delta: float) -> void:
	update_projectile_phase()
	# Aynı fiziksel temas boyunca kilit kalır; top boss çevresinden ayrılınca
	# bir sonraki gerçek dönüş vuruşu için yeniden hazır olur.
	var boss_radius: float = 62.0 * absf(global_scale.x)
	if collision_shape.shape is CircleShape2D:
		boss_radius = (collision_shape.shape as CircleShape2D).radius * absf(global_scale.x)
	var release_distance: float = boss_radius + 28.0
	for attacker_id: int in active_ball_contacts.keys():
		var attacker := instance_from_id(attacker_id) as Node2D
		if not is_instance_valid(attacker) or attacker.global_position.distance_to(global_position) > release_distance:
			active_ball_contacts.erase(attacker_id)


func begin_entry(target_position: Vector2) -> void:
	var entry := create_tween()
	entry.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	entry.tween_property(self, "global_position", target_position, entry_duration)
	await entry.finished
	if accepting_damage:
		collision_shape.set_deferred("disabled", false)
		phase_one_active = true
		call_deferred("_movement_loop")
		call_deferred("_fire_loop")


func _get_effective_visual_half_width() -> float:
	return 68.0 * absf(global_scale.x)

func _movement_loop() -> void:
	while phase_one_active and accepting_damage:
		var safe_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
		var boss_half_width := _get_effective_visual_half_width()
		var left_bound := maxf(
			safe_rect.position.x + safe_rect.size.x * 0.20,
			safe_rect.position.x + boss_half_width
		)
		var right_bound := minf(
			safe_rect.position.x + safe_rect.size.x * 0.80,
			safe_rect.position.x + safe_rect.size.x - boss_half_width
		)
		var target_x := safe_rect.position.x + safe_rect.size.x * 0.5
		if right_bound > left_bound:
			target_x = randf_range(left_bound, right_bound)
		var travel_duration: float = absf(target_x - global_position.x) / move_speed
		move_tween = create_tween()
		move_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		move_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		move_tween.tween_property(self, "global_position:x", target_x, maxf(travel_duration, 0.12))
		await move_tween.finished
		if not phase_one_active:
			return
		await get_tree().create_timer(randf_range(move_pause_min, move_pause_max)).timeout


func _fire_loop() -> void:
	while phase_one_active and accepting_damage:
		await get_tree().create_timer(randf_range(fire_interval_min, fire_interval_max)).timeout
		if not phase_one_active or not accepting_damage:
			return
		# Ucusta zaten sinir kadar mermi varsa bu turu atla; bir sonraki
		# aralikta tekrar denenir. Boylece oyuncu her zaman en fazla
		# MAX_ACTIVE_PROJECTILES mermiyle ugrasir.
		if _active_projectile_count() >= MAX_ACTIVE_PROJECTILES:
			continue
		await _telegraph_and_fire()


## Sahnede ucusta olan boss mermisi sayisi.
func _active_projectile_count() -> int:
	var count := 0
	for projectile in get_tree().get_nodes_in_group("boss_projectile"):
		if is_instance_valid(projectile) and not projectile.is_queued_for_deletion():
			count += 1
	return count


func _telegraph_and_fire() -> void:
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		return
	var normal_color: Color = energy_core.color
	charge_tween = energy_core.create_tween().set_parallel(true)
	charge_tween.tween_property(energy_core, "color", Color(1.0, 0.34, 0.08, 1.0), telegraph_duration)
	charge_tween.tween_property(energy_core, "scale", Vector2(1.28, 1.28), telegraph_duration)
	await charge_tween.finished
	if not phase_one_active or not accepting_damage:
		energy_core.color = normal_color
		energy_core.scale = Vector2.ONE
		return
	var target_snapshot: Vector2 = paddle.global_position
	var shot_direction: Vector2 = (target_snapshot - global_position).normalized()
	await _wait_for_projectile_clearance()
	if not phase_one_active or not accepting_damage:
		energy_core.color = normal_color
		energy_core.scale = Vector2.ONE
		return
	_spawn_projectile_pattern(shot_direction)
	_play_recoil(shot_direction)
	energy_core.color = normal_color
	energy_core.scale = Vector2.ONE


func _spawn_projectile(shot_direction: Vector2) -> void:
	owned_projectiles = owned_projectiles.filter(func(ref: WeakRef) -> bool:
		var node = ref.get_ref()
		return is_instance_valid(node) and not node.is_queued_for_deletion())
	if owned_projectiles.size() >= MAX_ACTIVE_CORE_PROJECTILES:
		return
	var projectile := PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	owned_projectiles.append(weakref(projectile))
	projectile.global_position = global_position + shot_direction * (72.0 * absf(global_scale.x))
	projectile.setup(get_parent(), shot_direction, projectile_speed)
	if get_parent().has_method("notify_boss_projectile_fired"):
		get_parent().notify_boss_projectile_fired()


func _clear_owned_projectiles() -> void:
	for ref in owned_projectiles:
		var projectile = ref.get_ref()
		if is_instance_valid(projectile):
			projectile.queue_free()
	owned_projectiles.clear()


func _exit_tree() -> void:
	_clear_owned_projectiles()


func _spawn_projectile_pattern(center_direction: Vector2) -> void:
	for angle_degrees: float in get_projectile_angles():
		_spawn_projectile(center_direction.rotated(deg_to_rad(angle_degrees)))


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


func get_projectile_phase() -> int:
	var hp_ratio := float(current_hp) / float(maxi(max_hp, 1))
	if hp_ratio > 0.75:
		return 1
	if hp_ratio > 0.25:
		return 2
	return 3


## KULLANILMIYOR. Faz basina 1/2/3 mermilik bir desen tanimliyor ama
## _spawn_projectile_pattern her zaman tek mermi atiyor. Baglanirsa boss 1
## belirgin sekilde zorlasir; MAX_ACTIVE_PROJECTILES ile birlikte
## degerlendirilmeli. Silmedim cunku tasarim niyeti tasiyor.
func get_projectile_angles() -> Array[float]:
	match get_projectile_phase():
		1:
			return [0.0]
		2:
			return [-8.0, 8.0]
		_:
			return [-12.0, 0.0, 12.0]


func update_projectile_phase() -> void:
	var next_phase := get_projectile_phase()
	if next_phase <= projectile_phase:
		return
	projectile_phase = next_phase
	play_phase_threshold_pulse(next_phase)


func play_phase_threshold_pulse(new_phase: int) -> void:
	if is_instance_valid(phase_pulse_tween):
		phase_pulse_tween.kill()
	energy_core.self_modulate = (
		Color(1.35, 0.68, 0.28, 1.0)
		if new_phase == 2
		else Color(1.48, 0.38, 0.18, 1.0)
	)
	phase_pulse_tween = energy_core.create_tween()
	phase_pulse_tween.tween_property(
		energy_core, "self_modulate", Color.WHITE, 0.24
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _play_recoil(shot_direction: Vector2) -> void:
	visual_root.position = -shot_direction * recoil_distance
	var recoil := visual_root.create_tween()
	recoil.tween_property(visual_root, "position", Vector2.ZERO, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func hit_from_ball(attacker_instance_id: int, source: StringName = &"ball") -> void:
	print("BOSS DAMAGE ROUTE | ball.gd::_physics_process")
	apply_boss_damage(0, source, attacker_instance_id)


func hit_from_plasma(attacker_instance_id: int) -> void:
	print("BOSS DAMAGE ROUTE | plasma_bullet.gd::_on_body_entered")
	apply_boss_damage(1, &"plasma", attacker_instance_id)


func hit_from_mounted_weapon(source: StringName, cycle_id: int) -> void:
	apply_boss_damage(1, source, cycle_id)


func debug_instant_kill() -> void:
	if not accepting_damage or current_hp <= 0:
		return
	apply_boss_damage(current_hp, &"debug", get_instance_id())


func release_ball_contact(attacker_instance_id: int) -> void:
	active_ball_contacts.erase(attacker_instance_id)
	for ball_source: StringName in [&"ball", &"piercing_ball", &"fireball_ball"]:
		last_damage_request_msec.erase("%s:%d" % [ball_source, attacker_instance_id])


func apply_boss_damage(amount: int, source: StringName, attacker_instance_id: int) -> void:
	var resolved_amount: int = GameManager.resolve_boss_direct_hit_damage(source, amount)
	print("BOSS DAMAGE REQUEST | source=%s | attacker_id=%d | amount=%d" % [
		source, attacker_instance_id, resolved_amount
	])
	if not accepting_damage or resolved_amount <= 0:
		return
	var is_direct_ball_source: bool = source in [&"ball", &"piercing_ball", &"fireball_ball"]
	if is_direct_ball_source and active_ball_contacts.has(attacker_instance_id):
		print("BOSS DAMAGE BLOCKED | duplicate ball contact")
		return
	var request_key: String = "%s:%d" % [source, attacker_instance_id]
	var now_msec: int = Time.get_ticks_msec()
	var last_request_msec: int = int(last_damage_request_msec.get(request_key, -1000000))
	if now_msec - last_request_msec < int(ball_hit_lock_duration * 1000.0):
		if is_direct_ball_source:
			print("BOSS DAMAGE BLOCKED | duplicate ball contact")
		else:
			print("BOSS DAMAGE BLOCKED | duplicate %s contact" % source)
		return
	last_damage_request_msec[request_key] = now_msec
	if is_direct_ball_source:
		active_ball_contacts[attacker_instance_id] = true
	var previous_hp: int = current_hp
	current_hp = maxi(current_hp - resolved_amount, 0)
	print("BOSS DAMAGE ACCEPTED | HP %d -> %d" % [previous_hp, current_hp])
	health_changed.emit(current_hp, max_hp)
	_play_hit_feedback()
	if current_hp <= 0:
		_defeat()

func _play_hit_feedback() -> void:
	if is_instance_valid(hit_tween):
		hit_tween.kill()
	visual_root.scale = Vector2.ONE
	visual_root.modulate = Color(1.32, 1.46, 1.55, 1.0)
	hit_tween = visual_root.create_tween().set_parallel(true)
	hit_tween.tween_property(visual_root, "scale", Vector2(1.035, 1.035), 0.045)
	hit_tween.tween_property(visual_root, "modulate", Color.WHITE, 0.09)
	hit_tween.chain().tween_property(visual_root, "scale", Vector2.ONE, 0.05)


func _defeat() -> void:
	if not accepting_damage:
		return
	accepting_damage = false
	phase_one_active = false
	if is_instance_valid(move_tween):
		move_tween.kill()
	if is_instance_valid(charge_tween):
		charge_tween.kill()
	collision_shape.set_deferred("disabled", true)
	_clear_owned_projectiles()
	print("THE CORE defeated")
	_spawn_death_burst()
	var fade := visual_root.create_tween().set_parallel(true)
	fade.tween_property(visual_root, "scale", Vector2(1.12, 1.12), 0.18)
	fade.tween_property(visual_root, "modulate", Color(1.4, 1.55, 1.65, 0.0), 0.65)
	await get_tree().create_timer(0.65).timeout
	defeated.emit()
	queue_free()


func _spawn_death_burst() -> void:
	for index: int in range(10):
		var particle := Polygon2D.new()
		particle.polygon = PackedVector2Array([
			Vector2(-2.0, -1.0), Vector2(3.0, 0.0), Vector2(-2.0, 1.0)
		])
		particle.color = Color(0.40, 0.94, 1.0, 1.0) if index % 2 == 0 else Color(1.0, 0.48, 0.12, 1.0)
		visual_root.add_child(particle)
		var angle: float = TAU * float(index) / 10.0
		particle.rotation = angle
		var tween := particle.create_tween().set_parallel(true)
		tween.tween_property(particle, "position", Vector2.from_angle(angle) * 58.0, 0.55)
		tween.tween_property(particle, "modulate:a", 0.0, 0.55)
