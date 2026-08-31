extends CharacterBody2D


@export var requires_manual_launch = true
@export_range(-60.0, 0.0, 1.0) var aim_angle_min = -60.0
@export_range(0.0, 60.0, 1.0) var aim_angle_max = 60.0
@export var aim_rotation_speed = 105.0
@export_range(0.1, 0.9, 0.01) var mobile_aim_min_vertical = 0.42
@export var boss_separation_distance = 3.0
@export_range(12.0, 15.0, 1.0) var minimum_boss_exit_angle = 15.0
@export_range(45.0, 75.0, 1.0) var max_paddle_bounce_angle = 65.0
@export_range(0.0, 0.20, 0.01) var paddle_bounce_dead_zone = 0.08
@export_range(0.0, 0.30, 0.01) var paddle_english_strength = 0.15
@export_range(0.30, 0.70, 0.01) var minimum_paddle_upward_component = 0.42
@export_range(0.10, 0.30, 0.01) var near_horizontal_threshold = 0.22
@export_range(2, 4, 1) var near_horizontal_bounces_required = 3
@export_range(0.30, 0.35, 0.01) var anti_stall_minimum_vertical = 0.32

const AIM_DOT_COUNT = 10
const AIM_LINE_LENGTH = 170.0
const PADDLE_ATTACH_OFFSET = Vector2(0, -34)
const MOBILE_LAUNCH_COLLISION_CLEARANCE := 2.0
const PIERCE_SEQUENCE_RESET_DISTANCE = 150.0
const PIERCE_EXCEPTION_CLEAR_DISTANCE = 90.0

var speed = 400.0
var max_speed = 750.0
var speed_increase = 8.0
# Asiri Ivme karti bu tabanlarin uzerine carpilir.
var base_speed = 400.0
var base_max_speed = 750.0

var direction = Vector2(0.7, -0.7).normalized()

var radius = 20.0

@onready var ball_visual = $BallVisual
@onready var wall_hit_sound_players = [
	$WallHitSound1,
	$WallHitSound2,
	$WallHitSound3,
	$WallHitSound4
]

const WALL_HIT_AUDIO_COOLDOWN_MS = 40
var next_wall_hit_sound = 0
var last_wall_hit_sound_ms = -WALL_HIT_AUDIO_COOLDOWN_MS
var ball_launched = true
var aim_angle = 15.0
var mobile_aim_active = false
var launch_paddle: Node2D
var aim_guide: Node2D
var pierce_level = 0
var pierce_passes_remaining = 0
var pierce_sequence_active = false
var pierce_distance_since_hit = 0.0
var pierced_bricks = []
var chain_trigger_available = true
var fireball_level = 0
var fireball_trigger_available = true
var active_boss_contact: Node
var near_horizontal_wall_bounces := 0
var last_side_wall_id := 0
var last_side_wall_bounce_frame := -1
var loss_reported := false


func _ready():

	add_to_group("game_ball")
	if OS.has_feature("mobile"):
		scale *= 1.3225
	set_combo_chain_rank(get_parent().get_combo_chain_rank())
	set_pierce_level(GameManager.pierce_level)
	set_fireball_level(GameManager.fireball_level)
	refresh_card_modifiers()
	if requires_manual_launch:
		enter_launch_state()


func _physics_process(delta):

	if loss_reported:
		return

	if not ball_launched:

		update_launch_state(delta)
		if not ball_launched:
			return

	# --------------------------------------------------
	# HAREKET
	# --------------------------------------------------

	speed = minf(speed, max_speed)
	velocity = direction * speed
	if absf(direction.y) >= near_horizontal_threshold:
		_reset_side_wall_stall_counter()
	update_pierce_sequence(delta)


	var collision = move_and_collide(
		velocity * delta
	)
	var boss_contact_this_frame: Node


	if collision:

		var collider = collision.get_collider()


		# --------------------------------------------------
		# RAKETE ÇARPMA
		# --------------------------------------------------

		if collider.is_in_group("game_paddle"):
			# Paddle altından gelen temas oyuna geri sekemez.
			if global_position.y > collider.global_position.y:
				_report_ball_lost()
				return
			_reset_side_wall_stall_counter()
			refill_pierce_capacity()

			BallPaddleAudio.play_hit()

			ball_visual.play_collision_feedback(
				"paddle",
				collision.get_position(),
				collision.get_normal()
			)

			var neon_effect = collider.get_node_or_null(
				"NeonEffect"
			)

			if neon_effect:

				neon_effect.flash()


			_apply_controlled_paddle_bounce(collider)


		# --------------------------------------------------
		# TUĞLA / DUVARA ÇARPMA
		# --------------------------------------------------

		else:

			if collider.is_in_group("game_boss") and collider.has_method("hit_from_ball"):
				_reset_side_wall_stall_counter()
				boss_contact_this_frame = collider
				var boss_damage_source: StringName = &"ball"
				if fireball_level > 0:
					boss_damage_source = &"fireball_ball"
				elif pierce_level > 0:
					boss_damage_source = &"piercing_ball"
				if collider.has_method("hit_from_ball_at"):
					collider.hit_from_ball_at(get_instance_id(), boss_damage_source, collision.get_position())
				else:
					collider.hit_from_ball(get_instance_id(), boss_damage_source)
				resolve_boss_bounce(collider, collision.get_normal())

			elif collider.is_in_group("game_brick") and collider.has_method("hit"):
				_reset_side_wall_stall_counter()

				ball_visual.play_collision_feedback(
					"brick",
					collision.get_position(),
					collision.get_normal()
				)

				var brick_is_shielded: bool = (
					collider.has_method("is_shielded")
					and collider.is_shielded()
				)
				var is_critical_hit: bool = randf() < GameManager.get_crit_chance()
				collider.hit("ball")
				# Kritik Rezonans: ayni temasta ikinci hasar uygulanir.
				if (
					is_critical_hit
					and not brick_is_shielded
					and is_instance_valid(collider)
					and collider.get("is_destroyed") != true
				):
					collider.hit("ball")

				var can_trigger_fireball: bool = pierce_level <= 0 or fireball_trigger_available
				if fireball_level > 0 and can_trigger_fireball:
					get_parent().trigger_fireball_blast(
						collision.get_position(),
						collider,
						fireball_level
					)
					if pierce_level > 0:
						fireball_trigger_available = false

				# ZINCIRLEME evrimi zincir simsegini her delinen tuglada tetikler.
				var can_trigger_chain: bool = (
					pierce_level <= 0
					or chain_trigger_available
					or GameManager.pierce_evolution == &"cascade"
				)
				if (
					not brick_is_shielded
					and can_trigger_chain
					and get_parent().get_chain_lightning_rank() >= 0
				):
					var chain_source: StringName = &"ball"
					if fireball_level > 0:
						chain_source = &"fireball_ball"
					elif pierce_level > 0:
						chain_source = &"piercing_ball"
					get_parent().trigger_chain_lightning(
						collider.global_position,
						collider,
						chain_source
					)
					if pierce_level > 0:
						chain_trigger_available = false

				if not brick_is_shielded and should_pierce_brick(collider):
					register_pierced_brick(collider)
				else:
					direction = direction.bounce(collision.get_normal())

			else:

				direction = direction.bounce(
					collision.get_normal()
				)


			if collider.is_in_group("game_wall"):

				play_wall_hit_sound()

				ball_visual.play_collision_feedback(
					"wall",
					collision.get_position(),
					collision.get_normal()
				)
				if absf(collision.get_normal().x) > 0.70:
					var side_wall_id := -1 if collision.get_normal().x > 0.0 else 1
					_register_near_horizontal_side_wall_bounce(side_wall_id)


	if is_instance_valid(active_boss_contact) and not is_instance_valid(boss_contact_this_frame):
		if active_boss_contact.has_method("release_ball_contact"):
			active_boss_contact.release_ball_contact(get_instance_id())
	active_boss_contact = boss_contact_this_frame

	# --------------------------------------------------
	# EKRAN SINIRLARI
	# --------------------------------------------------

	var screen_size = (
		get_viewport_rect().size
	)
	var safe_rect := GameManager.get_gameplay_rect(screen_size)
	var left_boundary := safe_rect.position.x
	var right_boundary := safe_rect.position.x + safe_rect.size.x


	# Sol duvar
	if position.x <= left_boundary + radius:

		position.x = left_boundary + radius
		play_wall_hit_sound()

		ball_visual.play_collision_feedback(
			"wall",
			Vector2(left_boundary, position.y),
			Vector2.RIGHT
		)

		direction.x = abs(
			direction.x
		)
		_register_near_horizontal_side_wall_bounce(-1)


	# Sağ duvar
	if position.x >= right_boundary - radius:

		position.x = (
			right_boundary - radius
		)
		play_wall_hit_sound()

		ball_visual.play_collision_feedback(
			"wall",
			Vector2(right_boundary, position.y),
			Vector2.LEFT
		)

		direction.x = -abs(
			direction.x
		)
		_register_near_horizontal_side_wall_bounce(1)


	# Üst duvar
	if position.y < GameManager.PLAYFIELD_TOP + radius - 1.0:

		position.y = GameManager.PLAYFIELD_TOP + radius
		play_wall_hit_sound()

		ball_visual.play_collision_feedback(
			"wall",
			Vector2(position.x, GameManager.PLAYFIELD_TOP),
			Vector2.DOWN
		)

		direction.y = abs(
			direction.y
		)


	# --------------------------------------------------
	# TOP AŞAĞI KAÇTI
	# --------------------------------------------------

	var loss_threshold: float = safe_rect.position.y + safe_rect.size.y + radius
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if is_instance_valid(paddle):
		loss_threshold = minf(loss_threshold, paddle.global_position.y + radius * 0.5)
	if global_position.y > loss_threshold:
		_report_ball_lost()


func _report_ball_lost() -> void:
	if loss_reported:
		return
	loss_reported = true
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	get_parent().ball_lost(self)


func _reset_side_wall_stall_counter() -> void:
	near_horizontal_wall_bounces = 0
	last_side_wall_id = 0


func _register_near_horizontal_side_wall_bounce(side_wall_id: int) -> void:
	var physics_frame := Engine.get_physics_frames()
	if physics_frame == last_side_wall_bounce_frame:
		return
	last_side_wall_bounce_frame = physics_frame

	if absf(direction.y) >= near_horizontal_threshold:
		_reset_side_wall_stall_counter()
		return
	# Aynı duvarın overlap/fallback callback'i karşılıklı bounce sayılmaz.
	if last_side_wall_id == side_wall_id:
		return

	near_horizontal_wall_bounces += 1
	last_side_wall_id = side_wall_id
	if near_horizontal_wall_bounces < near_horizontal_bounces_required:
		return

	var vertical_sign := signf(direction.y)
	if is_zero_approx(vertical_sign):
		vertical_sign = -1.0
	var horizontal_sign := signf(direction.x)
	if is_zero_approx(horizontal_sign):
		horizontal_sign = -float(side_wall_id)
	var corrected_vertical := maxf(absf(direction.y), anti_stall_minimum_vertical)
	direction = Vector2(
		horizontal_sign * sqrt(maxf(0.0, 1.0 - corrected_vertical * corrected_vertical)),
		vertical_sign * corrected_vertical
	).normalized()
	velocity = direction * speed
	_reset_side_wall_stall_counter()

func _apply_controlled_paddle_bounce(paddle_node: Node2D) -> void:
	var paddle_half_width := 95.0 * absf(paddle_node.global_scale.x)
	if paddle_node.has_method("get_bounce_half_width"):
		paddle_half_width = maxf(float(paddle_node.get_bounce_half_width()), 1.0)

	var hit_offset := clampf(
		(global_position.x - paddle_node.global_position.x) / paddle_half_width,
		-1.0,
		1.0
	)
	if absf(hit_offset) < paddle_bounce_dead_zone:
		hit_offset = 0.0

	var paddle_motion_ratio := 0.0
	if paddle_node.has_method("get_bounce_english_input"):
		paddle_motion_ratio = clampf(float(paddle_node.get_bounce_english_input()), -1.0, 1.0)
	var controlled_offset := clampf(
		hit_offset + paddle_motion_ratio * paddle_english_strength,
		-1.0,
		1.0
	)
	var bounce_angle := deg_to_rad(controlled_offset * max_paddle_bounce_angle)
	var outgoing := Vector2(sin(bounce_angle), -cos(bounce_angle)).normalized()

	# Export değeri, açı ileride değiştirilse bile neredeyse yatay çıkışı engeller.
	if -outgoing.y < minimum_paddle_upward_component:
		outgoing.y = -minimum_paddle_upward_component
		var horizontal_sign := signf(outgoing.x)
		outgoing.x = horizontal_sign * sqrt(maxf(0.0, 1.0 - outgoing.y * outgoing.y))

	direction = outgoing.normalized()
	velocity = direction * speed

func resolve_boss_bounce(boss: Node2D, collision_normal: Vector2) -> void:
	var safe_normal := collision_normal.normalized()
	var radial_normal := (global_position - boss.global_position).normalized()
	if safe_normal.is_zero_approx():
		safe_normal = radial_normal
	elif not radial_normal.is_zero_approx() and safe_normal.dot(radial_normal) < 0.5:
		safe_normal = radial_normal
	if safe_normal.is_zero_approx():
		safe_normal = -direction.normalized()

	var outgoing := direction.bounce(safe_normal).normalized()
	var minimum_normal_component := sin(deg_to_rad(minimum_boss_exit_angle))
	var normal_component := outgoing.dot(safe_normal)
	if normal_component < minimum_normal_component:
		var tangent := Vector2(-safe_normal.y, safe_normal.x)
		var tangent_sign := signf(outgoing.dot(tangent))
		if is_zero_approx(tangent_sign):
			tangent_sign = 1.0
		var tangent_component := sqrt(maxf(1.0 - minimum_normal_component * minimum_normal_component, 0.0))
		outgoing = (
			safe_normal * minimum_normal_component
			+ tangent * tangent_component * tangent_sign
		).normalized()

	direction = outgoing
	velocity = direction * speed
	separate_from_boss(boss, safe_normal)


func separate_from_boss(boss: Node2D, safe_normal: Vector2) -> void:
	var desired_surface_distance := 0.0
	var boss_shape_node := boss.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var ball_shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if (
		is_instance_valid(boss_shape_node)
		and boss_shape_node.shape is CircleShape2D
		and is_instance_valid(ball_shape_node)
		and ball_shape_node.shape is CircleShape2D
	):
		var boss_radius := (boss_shape_node.shape as CircleShape2D).radius * maxf(absf(boss.global_scale.x), absf(boss.global_scale.y))
		var ball_radius := (ball_shape_node.shape as CircleShape2D).radius * maxf(absf(global_scale.x), absf(global_scale.y))
		desired_surface_distance = boss_radius + ball_radius + boss_separation_distance

	var distance_from_boss := global_position.distance_to(boss.global_position)
	if desired_surface_distance > 0.0 and distance_from_boss < desired_surface_distance:
		global_position = boss.global_position + safe_normal * desired_surface_distance
	else:
		global_position += safe_normal * boss_separation_distance


func enter_launch_state():

	ball_launched = false
	mobile_aim_active = false
	velocity = Vector2.ZERO
	launch_paddle = get_tree().get_first_node_in_group("game_paddle") as Node2D
	add_to_group("manual_launch_waiting")

	if get_parent().has_method("set_plasma_launch_paused"):
		get_parent().set_plasma_launch_paused(true)

	if is_instance_valid(launch_paddle) and launch_paddle.has_method("set_launch_aim_lock"):
		launch_paddle.set_launch_aim_lock(true)

	create_aim_guide()
	update_aim_guide()


func update_launch_state(delta):

	if not is_instance_valid(launch_paddle):
		launch_paddle = get_tree().get_first_node_in_group("game_paddle") as Node2D
		if is_instance_valid(launch_paddle) and launch_paddle.has_method("set_launch_aim_lock"):
			launch_paddle.set_launch_aim_lock(true)

	if is_instance_valid(launch_paddle):
		global_position = launch_paddle.global_position + _get_launch_attach_offset()

	velocity = Vector2.ZERO
	if not mobile_aim_active:
		var aim_input = Input.get_axis("ui_left", "ui_right")
		aim_angle = clampf(
			aim_angle + aim_input * aim_rotation_speed * delta,
			aim_angle_min,
			aim_angle_max
		)
	direction = get_aim_direction()
	update_aim_guide()

	if Input.is_action_just_pressed("ui_up"):
		launch_ball()


func launch_ball():

	ball_launched = true
	refill_pierce_capacity()
	direction = get_aim_direction()
	remove_from_group("manual_launch_waiting")

	# Ikiz Cekirdek karti varsa eksik kalici toplar burada tamamlanir.
	var game := get_parent()
	if is_instance_valid(game) and game.has_method("_refresh_persistent_extra_balls"):
		game.call_deferred("_refresh_persistent_extra_balls")

	if is_instance_valid(aim_guide):
		aim_guide.visible = false

	if is_instance_valid(launch_paddle) and launch_paddle.has_method("set_launch_aim_lock"):
		launch_paddle.set_launch_aim_lock(false)

	if get_parent().has_method("set_plasma_launch_paused"):
		get_parent().set_plasma_launch_paused(false)


func set_mobile_aim_target(target_position: Vector2) -> void:
	if ball_launched:
		return
	var target_direction := target_position - global_position
	if target_direction.length_squared() <= 0.0001:
		return
	# Aşağıdaki bir touch hedefi hiçbir koşulda aşağı yön üretmez.
	target_direction.y = minf(target_direction.y, -0.001)
	target_direction = target_direction.normalized()

	# Yukarı eksenden izin verilen maksimum açı, minimum negatif Y bileşeninden gelir.
	var maximum_angle := acos(clampf(mobile_aim_min_vertical, 0.1, 0.9))
	var angle_from_up := atan2(target_direction.x, -target_direction.y)
	angle_from_up = clampf(angle_from_up, -maximum_angle, maximum_angle)
	aim_angle = rad_to_deg(angle_from_up)
	direction = get_aim_direction()
	mobile_aim_active = true
	update_aim_guide()


func get_aim_direction():

	var angle_radians = deg_to_rad(aim_angle)
	return Vector2(sin(angle_radians), -cos(angle_radians)).normalized()


func set_pierce_level(level):

	pierce_level = clampi(level, 0, 3)
	refill_pierce_capacity(false)
	if is_instance_valid(ball_visual) and ball_visual.has_method("set_pierce_level"):
		ball_visual.set_pierce_level(pierce_level)


func set_fireball_level(level):

	fireball_level = clampi(level, 0, 3)
	if is_instance_valid(ball_visual) and ball_visual.has_method("set_fireball_level"):
		ball_visual.set_fireball_level(fireball_level)


func should_pierce_brick(_brick):

	if pierce_level <= 0 or pierce_passes_remaining <= 0:
		return false
	return true


func register_pierced_brick(brick):

	pierce_passes_remaining -= 1
	pierce_distance_since_hit = 0.0

	if not pierced_bricks.has(brick):
		pierced_bricks.append(brick)
		add_collision_exception_with(brick)


func update_pierce_sequence(delta):

	for index in range(pierced_bricks.size() - 1, -1, -1):
		var brick = pierced_bricks[index]
		if not is_instance_valid(brick):
			pierced_bricks.remove_at(index)
		elif global_position.distance_to(brick.global_position) > PIERCE_EXCEPTION_CLEAR_DISTANCE:
			remove_collision_exception_with(brick)
			pierced_bricks.remove_at(index)

	if not pierce_sequence_active:
		return

	pierce_distance_since_hit += speed * delta
	if pierce_distance_since_hit >= PIERCE_SEQUENCE_RESET_DISTANCE:
		reset_pierce_sequence()


func reset_pierce_sequence():

	for brick in pierced_bricks:
		if is_instance_valid(brick):
			remove_collision_exception_with(brick)

	pierced_bricks.clear()
	pierce_sequence_active = false
	pierce_passes_remaining = 0
	pierce_distance_since_hit = 0.0


## Mobilde top, raketin collision kutusuna gomulmesin (Codex).
func _get_launch_attach_offset() -> Vector2:
	if not OS.has_feature("mobile") or not is_instance_valid(launch_paddle):
		return PADDLE_ATTACH_OFFSET

	var ball_collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var paddle_collision := launch_paddle.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if ball_collision == null or paddle_collision == null:
		return PADDLE_ATTACH_OFFSET

	var ball_circle := ball_collision.shape as CircleShape2D
	var paddle_rectangle := paddle_collision.shape as RectangleShape2D
	if ball_circle == null or paddle_rectangle == null:
		return PADDLE_ATTACH_OFFSET

	var ball_radius := ball_circle.radius * absf(ball_collision.global_scale.y)
	var paddle_half_height := paddle_rectangle.size.y * 0.5 * absf(paddle_collision.global_scale.y)
	var safe_distance := ball_radius + paddle_half_height + MOBILE_LAUNCH_COLLISION_CLEARANCE
	return Vector2(0.0, -maxf(absf(PADDLE_ATTACH_OFFSET.y), safe_distance))


func refresh_card_modifiers() -> void:
	# Asiri Ivme karti topu hizlandirir; mevcut hiz orani korunur.
	var previous_max := maxf(max_speed, 1.0)
	var speed_ratio := clampf(speed / previous_max, 0.0, 1.0)
	# Kart çarpanı ve sektör modifier'ı birlikte uygulanır.
	var multiplier := (
		GameManager.get_ball_speed_multiplier()
		* GameManager.get_sector_ball_speed_scale()
	)
	max_speed = base_max_speed * multiplier
	speed = maxf(base_speed * multiplier, speed_ratio * max_speed)


func refill_pierce_capacity(reset_chain_trigger = true):

	reset_pierce_sequence()
	pierce_passes_remaining = pierce_level
	if pierce_level > 0:
		# Bina herkese temel delme verir; Delici rakette iki katina cikar.
		# Dizi GameManager'da (tek kaynak) — UI ile sapmasin diye.
		pierce_passes_remaining += GameManager.get_colony_pierce_bonus()
	# GENIS DELIK evrimi kapasiteyi kalici olarak artirir.
	if pierce_level > 0 and GameManager.pierce_evolution == &"breach":
		pierce_passes_remaining += 3
	if pierce_level > 0:
		pierce_passes_remaining += GameManager.get_colony_bonus_pierce()
	if reset_chain_trigger:
		chain_trigger_available = true
		fireball_trigger_available = true


func create_aim_guide():

	if is_instance_valid(aim_guide):
		aim_guide.visible = true
		return

	aim_guide = Node2D.new()
	aim_guide.name = "AimGuide"
	aim_guide.z_index = 6
	add_child(aim_guide)

	for i in range(AIM_DOT_COUNT):
		var dot = Polygon2D.new()
		dot.polygon = PackedVector2Array([
			Vector2(0, -2.0),
			Vector2(2.0, 0),
			Vector2(0, 2.0),
			Vector2(-2.0, 0)
		])
		var fade_ratio = float(i) / float(AIM_DOT_COUNT - 1)
		dot.color = Color(0.72, 0.97, 1.0, lerpf(0.72, 0.18, fade_ratio))
		aim_guide.add_child(dot)


func update_aim_guide():

	if not is_instance_valid(aim_guide):
		return

	var aim_direction = get_aim_direction()
	for i in range(AIM_DOT_COUNT):
		var distance = lerpf(20.0, AIM_LINE_LENGTH, float(i) / float(AIM_DOT_COUNT - 1))
		aim_guide.get_child(i).position = aim_direction * distance


func play_wall_hit_sound():

	var now_ms = Time.get_ticks_msec()
	if now_ms - last_wall_hit_sound_ms < WALL_HIT_AUDIO_COOLDOWN_MS:
		return

	last_wall_hit_sound_ms = now_ms
	var player = wall_hit_sound_players[next_wall_hit_sound]
	next_wall_hit_sound = (
		(next_wall_hit_sound + 1)
		% wall_hit_sound_players.size()
	)
	player.pitch_scale = randf_range(0.97, 1.03)
	player.play()


func set_combo_chain_rank(rank_index):

	ball_visual.set_combo_chain_rank(rank_index)


# ==================================================
# TOP HIZINI ARTIR
# ==================================================

func increase_speed(acceleration_scale: float = 1.0):

	speed += speed_increase * clampf(acceleration_scale, 0.0, 1.0)

	speed = min(
		speed,
		max_speed
	)
