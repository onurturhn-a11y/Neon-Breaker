extends CharacterBody2D


var speed = 800.0
var max_speed = 1100.0
var fixed_y = 0.0
var launch_aim_locked = false
var mobile_slider_dragging = false
var mobile_slider_x = 0.0
var bounce_velocity_x = 0.0
var last_bounce_sample_x = 0.0

@export var acceleration = 14000.0
@export var deceleration = 16000.0

var wide_paddle_active = false
var wide_level = 0
var wide_transition_tween: Tween
var normal_scale = Vector2.ONE
# Kart bonuslari olmadan olculen taban degerler; kart seviyeleri bunlarin uzerine carpilir.
var base_speed = 800.0
var base_max_speed = 1100.0

const WIDE_PICKUP_WIDTH_MULTIPLIER := 1.25
const WIDE_TRANSITION_DURATION := 0.25
const MOBILE_PADDLE_SCALE_MULTIPLIER := 1.15
const PADDLE_VISUAL_WIDTH := 190.0
const BLUE_PADDLE_TEXTURE: Texture2D = preload("res://assets/paddles/paddle_blue.png")
const PLASMA_PADDLE_TEXTURE: Texture2D = preload("res://assets/paddles/plasma_paddle.png")
const PIERCING_PADDLE_TEXTURE: Texture2D = preload("res://assets/paddles/piercing_paddle.png")
const FIRE_PADDLE_TEXTURE: Texture2D = preload("res://assets/paddles/fireball_paddle.png")
const NEON_CORE_VISUAL_SCENE: PackedScene = preload("res://neon_core_paddle_visual.tscn")

var weapon_active = false
var plasma_level = 0
var weapon_ready = false
var weapon_transitioning = false
var plasma_fire_launch_paused = false
var plasma_evolution: StringName = &"none"
var fire_interval = 1.0
var fire_timer = 0.0
const OVERCHARGE_FIRE_RATE_MULTIPLIER := 1.30

var plasma_scene = preload("res://plasma_bullet.tscn")

@onready var weapon_visual = $WeaponSystem
@onready var main_muzzle = $WeaponSystem/MainWeaponMount/MainGun/MainMuzzle
@onready var left_muzzle = $WeaponSystem/LeftWeaponMount/LeftGun/LeftMuzzle
@onready var right_muzzle = $WeaponSystem/RightWeaponMount/RightGun/RightMuzzle


func _ready():
	fixed_y = global_position.y
	add_to_group("game_paddle")
	if OS.has_feature("mobile"):
		scale *= MOBILE_PADDLE_SCALE_MULTIPLIER
	normal_scale = scale
	last_bounce_sample_x = global_position.x
	_apply_paddle_affinity_visual()
	refresh_card_modifiers()


func _physics_process(delta):
	var input_direction = Input.get_axis("ui_left", "ui_right")
	if launch_aim_locked:
		input_direction = 0.0
	if mobile_slider_dragging:
		input_direction = 0.0
		velocity.x = 0.0

	var target_speed = input_direction * speed
	if input_direction == 0.0:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	elif velocity.x != 0.0 and sign(velocity.x) != sign(input_direction):
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	velocity.y = 0.0
	move_and_slide()
	global_position.y = fixed_y
	if mobile_slider_dragging:
		global_position.x = mobile_slider_x
		velocity.x = 0.0

	var horizontal_limits := get_horizontal_limits()
	global_position.x = clamp(global_position.x, horizontal_limits.x, horizontal_limits.y)
	if delta > 0.0:
		bounce_velocity_x = (global_position.x - last_bounce_sample_x) / delta
	last_bounce_sample_x = global_position.x

	if weapon_active and weapon_ready and not plasma_fire_launch_paused:
		fire_timer -= delta
		if fire_timer <= 0.0:
			shoot()
			fire_timer = fire_interval


func increase_speed():
	base_speed = minf(base_speed + 15.0, base_max_speed)
	refresh_card_modifiers()


func set_launch_aim_lock(locked):
	launch_aim_locked = locked
	if launch_aim_locked:
		velocity.x = 0.0


func get_bounce_half_width() -> float:
	var collision_shape := $CollisionShape2D as CollisionShape2D
	if is_instance_valid(collision_shape) and collision_shape.shape is RectangleShape2D:
		var rectangle := collision_shape.shape as RectangleShape2D
		return rectangle.size.x * 0.5 * absf(global_scale.x)
	return 95.0 * absf(global_scale.x)


func get_bounce_english_input() -> float:
	var effective_max_speed := maxf(speed, 1.0)
	return clampf(bounce_velocity_x / effective_max_speed, -1.0, 1.0)


func get_horizontal_half_extent() -> float:
	var normal_scale_x := maxf(absf(normal_scale.x), 0.001)
	return 95.0 * absf(scale.x) / normal_scale_x


func set_desktop_bottom_margin(_viewport_height: float, bottom_margin: float) -> void:
	if OS.has_feature("mobile"):
		return
	var collision_shape := $CollisionShape2D as CollisionShape2D
	var half_height := 12.0 * absf(global_scale.y)
	if is_instance_valid(collision_shape) and collision_shape.shape is RectangleShape2D:
		half_height = (collision_shape.shape as RectangleShape2D).size.y * 0.5 * absf(global_scale.y)
	var visible_rect := GameManager.get_desktop_visible_world_rect(get_viewport_rect().size)
	var world_bottom_margin := bottom_margin / GameManager.DESKTOP_GAMEPLAY_CAMERA_ZOOM
	fixed_y = visible_rect.end.y - world_bottom_margin - half_height
	global_position.y = fixed_y

func get_horizontal_limits() -> Vector2:
	var half_width := get_horizontal_half_extent()
	var safe_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	return Vector2(
		safe_rect.position.x + half_width,
		safe_rect.position.x + safe_rect.size.x - half_width
	)


func get_horizontal_position_ratio() -> float:
	var limits := get_horizontal_limits()
	var usable_width := limits.y - limits.x
	if usable_width <= 0.0:
		return 0.5
	return clampf((global_position.x - limits.x) / usable_width, 0.0, 1.0)


func set_mobile_slider_ratio(ratio: float) -> void:
	var limits := get_horizontal_limits()
	velocity.x = 0.0
	mobile_slider_x = lerpf(limits.x, limits.y, clampf(ratio, 0.0, 1.0))
	mobile_slider_dragging = true
	global_position.x = mobile_slider_x


func set_mobile_control_y(control_y: float) -> void:
	fixed_y = control_y
	global_position.y = fixed_y


func end_mobile_slider_drag() -> void:
	mobile_slider_dragging = false
	velocity.x = 0.0


func set_plasma_launch_paused(paused):
	plasma_fire_launch_paused = paused
	if not plasma_fire_launch_paused and weapon_active:
		fire_timer = 0.0


func refresh_card_modifiers() -> void:
	# Servo Hizlandirici karti hareket hizini, Alan Genisletici karti raket genisligini artirir.
	speed = base_speed * GameManager.get_paddle_speed_multiplier()
	max_speed = base_max_speed * GameManager.get_paddle_speed_multiplier()
	apply_wide_level(wide_level)


func apply_wide_level(level):
	wide_level = clampi(level, 0, 3)
	wide_paddle_active = wide_level > 0
	var width_multiplier := WIDE_PICKUP_WIDTH_MULTIPLIER if wide_paddle_active else 1.0
	width_multiplier *= GameManager.get_paddle_width_multiplier()
	var target_scale := Vector2(normal_scale.x * width_multiplier, normal_scale.y)
	if is_instance_valid(wide_transition_tween):
		wide_transition_tween.kill()
	if scale.is_equal_approx(target_scale):
		scale = target_scale
		return
	wide_transition_tween = create_tween()
	wide_transition_tween.tween_property(
		self,
		"scale",
		target_scale,
		WIDE_TRANSITION_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func apply_plasma_level(level, animate_deploy = true):
	plasma_level = clampi(level, 0, 3)
	weapon_active = plasma_level > 0
	var neon_effect := get_node_or_null("NeonEffect")
	if is_instance_valid(neon_effect) and neon_effect.has_method("set_plasma_active"):
		neon_effect.set_plasma_active(weapon_active)
	weapon_visual.set_plasma_level(plasma_level, animate_deploy and weapon_visual.deployed)
	var intervals = [1.0, 1.0, 0.85, 0.70]
	_set_plasma_fire_interval(intervals[plasma_level])
	fire_timer = 0.0
	if not weapon_active:
		weapon_ready = false
		if weapon_visual.deployed:
			weapon_visual.retract()
		return
	if weapon_visual.deployed:
		weapon_ready = true
		return
	if not animate_deploy:
		weapon_visual.show_deployed_immediate()
		weapon_ready = true
		return
	if weapon_transitioning:
		return
	weapon_transitioning = true
	await weapon_visual.deploy()
	weapon_transitioning = false
	weapon_ready = weapon_active


func apply_plasma_evolution(evolution: StringName, animate_transition = true) -> void:
	plasma_evolution = evolution
	weapon_visual.set_plasma_evolution(plasma_evolution, animate_transition)
	var intervals = [1.0, 1.0, 0.85, 0.70]
	_set_plasma_fire_interval(intervals[clampi(plasma_level, 0, 3)])
	fire_timer = 0.0


func _set_plasma_fire_interval(base_interval: float) -> void:
	fire_interval = base_interval
	if plasma_evolution == &"overcharge":
		fire_interval /= OVERCHARGE_FIRE_RATE_MULTIPLIER
	if plasma_level > 0:
		var lab_level := clampi(
			GameManager.get_colony_building_level(GameManager.COLONY_BUILDING_PLASMA_LAB),
			0,
			3
		)
		# Bina herkese temel indirim verir; Plazma raketinde indirim iki katina cikar.
		var base_reductions := [0.0, 0.115, 0.130, 0.150]
		var reduction: float = (
			base_reductions[lab_level]
			* GameManager.get_affinity_scale(GameManager.PADDLE_PLASMA)
		)
		fire_interval *= maxf(1.0 - reduction, 0.55)
	fire_interval *= GameManager.get_colony_plasma_interval_scale()


func shoot() -> void:
	if not weapon_active or not weapon_ready:
		return
	weapon_visual.fire_muzzles()
	weapon_visual.play_fire_sound()
	var muzzles: Array = [main_muzzle]
	if plasma_level >= 2:
		muzzles.append(left_muzzle)
		muzzles.append(right_muzzle)
	for index in range(muzzles.size()):
		var shot_angle := 0.0
		if plasma_evolution == &"ricochet" and muzzles.size() > 1:
			shot_angle = lerpf(-10.0, 10.0, float(index) / float(muzzles.size() - 1))
		_spawn_plasma(muzzles[index], Vector2.UP.rotated(deg_to_rad(shot_angle)))


func _spawn_plasma(muzzle: Marker2D, shot_direction: Vector2) -> void:
	var projectile = plasma_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = muzzle.global_position
	if projectile.has_method("set_plasma_evolution"):
		projectile.set_plasma_evolution(plasma_evolution)
	if projectile.has_method("configure_shot"):
		projectile.configure_shot(shot_direction, 3 if plasma_evolution == &"ricochet" else 0)
	if get_parent().has_method("get_combo_chain_rank") and projectile.has_method("set_combo_chain_rank"):
		projectile.set_combo_chain_rank(get_parent().get_combo_chain_rank())


func set_combo_chain_rank(rank_index) -> void:
	weapon_visual.set_combo_chain_rank(rank_index)


func apply_run_upgrades(level: int, evolution: StringName = &"none") -> void:
	apply_wide_level(0)
	apply_plasma_level(level, false)
	apply_plasma_evolution(evolution, false)


func _apply_paddle_affinity_visual() -> void:
	var neon_effect := $NeonEffect
	var visual_layers := $NeonEffect/VisualLayers
	for dynamic_name in [&"ActivePaddleTexture", &"ActivePaddleGlow", &"NeonCoreVisual"]:
		var dynamic_visual := visual_layers.get_node_or_null(NodePath(dynamic_name))
		if is_instance_valid(dynamic_visual):
			dynamic_visual.queue_free()
	for child in visual_layers.get_children():
		if child is CanvasItem:
			child.visible = true
	if neon_effect.has_method("configure_special_paddle"):
		neon_effect.configure_special_paddle(null, null, Color.WHITE)
	if neon_effect.has_method("configure_cosmetic_visual"):
		neon_effect.configure_cosmetic_visual(null)

	if GameManager.paddle_affinity == GameManager.PADDLE_NEUTRAL:
		return

	for child in visual_layers.get_children():
		if child is CanvasItem:
			child.visible = false

	if GameManager.paddle_affinity == GameManager.PADDLE_NEON_CORE:
		var neon_core_visual := NEON_CORE_VISUAL_SCENE.instantiate()
		neon_core_visual.name = "NeonCoreVisual"
		visual_layers.add_child(neon_core_visual)
		if neon_effect.has_method("configure_cosmetic_visual"):
			neon_effect.configure_cosmetic_visual(neon_core_visual)
		if neon_core_visual.has_method("set_plasma_active"):
			neon_core_visual.set_plasma_active(weapon_active)
		return

	var texture := BLUE_PADDLE_TEXTURE
	var theme_color := Color(0.2, 0.9, 1.0, 1.0)
	match GameManager.paddle_affinity:
		GameManager.PADDLE_PLASMA:
			texture = PLASMA_PADDLE_TEXTURE
			theme_color = Color(0.22, 1.0, 0.18, 1.0)
		GameManager.PADDLE_FIRE:
			texture = FIRE_PADDLE_TEXTURE
			theme_color = Color(1.0, 0.2, 0.08, 1.0)
		GameManager.PADDLE_PIERCING:
			texture = PIERCING_PADDLE_TEXTURE
			theme_color = Color(1.0, 0.72, 0.12, 1.0)

	var special_glow := Sprite2D.new()
	special_glow.name = "ActivePaddleGlow"
	special_glow.texture = texture
	special_glow.z_index = -1
	special_glow.self_modulate = Color(theme_color.r, theme_color.g, theme_color.b, 0.30)
	special_glow.scale = _get_texture_fit_scale(texture) * 1.06
	visual_layers.add_child(special_glow)

	var special_sprite := Sprite2D.new()
	special_sprite.name = "ActivePaddleTexture"
	special_sprite.texture = texture
	special_sprite.scale = _get_texture_fit_scale(texture)
	special_sprite.z_index = 1
	visual_layers.add_child(special_sprite)
	if neon_effect.has_method("configure_special_paddle"):
		neon_effect.configure_special_paddle(special_sprite, special_glow, theme_color)

func _get_texture_fit_scale(texture: Texture2D) -> Vector2:
	if not is_instance_valid(texture) or texture.get_width() <= 0:
		return Vector2.ONE
	var uniform_scale := PADDLE_VISUAL_WIDTH / float(texture.get_width())
	return Vector2(uniform_scale, uniform_scale)
