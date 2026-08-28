extends Area2D


var speed = 850.0
var combo_rank = -1
var direction = Vector2.UP
var remaining_wall_bounces = 0
var wall_bounce_enabled = false
var wall_contact_cooldown = 0.0
var overcharge_visual = false
var ricochet_visual = false
var successful_wall_bounces = 0
var ricochet_glow: Sprite2D
const MOBILE_VISUAL_SCALE_MULTIPLIER := 1.357
const PLASMA_NEON_GREEN := Color(0.224, 1.0, 0.078, 1.0)
const PLASMA_CORE_GREEN := Color(0.82, 1.0, 0.72, 1.0)

@onready var sprite = $Sprite2D
@onready var trail = $Trail

var impact_small = preload(
	"res://assets/weapons/impact_small.png"
)

var impact_big = preload(
	"res://assets/weapons/impact_big.png"
)


func _ready():

	add_to_group("plasma_projectile")
	body_entered.connect(_on_body_entered)
	_ensure_ricochet_glow()
	apply_combo_visual()


func _process(delta):

	wall_contact_cooldown = maxf(wall_contact_cooldown - delta, 0.0)
	position += direction * speed * delta
	_update_visual_direction()
	_check_screen_wall_collision()


	var visible_rect := GameManager.get_desktop_visible_world_rect(get_viewport_rect().size) if not OS.has_feature("mobile") else GameManager.get_layout_safe_rect(get_viewport_rect().size)
	if global_position.y < visible_rect.position.y - 50.0 or global_position.y > visible_rect.end.y + 50.0:

		queue_free()


func _on_body_entered(body):
	if is_queued_for_deletion():
		return
	if body.is_in_group("game_wall"):
		if wall_bounce_enabled:
			_handle_wall_hit(Vector2.DOWN)
		return
	if body.is_in_group("game_boss") and body.has_method("hit_from_plasma"):
		if body.has_method("hit_from_plasma_at"):
			body.hit_from_plasma_at(get_instance_id(), global_position)
		else:
			body.hit_from_plasma(get_instance_id())
		create_impact(false)
		queue_free()
		return
	if body.has_method("hit"):
		if body.has_method("hit_from_plasma"):

			body.hit_from_plasma()

		else:

			body.hit("plasma")

		var use_big_impact = body.is_destroyed

		create_impact(use_big_impact)

		queue_free()


func configure_shot(shot_direction: Vector2, wall_bounces: int) -> void:

	direction = shot_direction.normalized()
	remaining_wall_bounces = maxi(wall_bounces, 0)
	wall_bounce_enabled = remaining_wall_bounces > 0


func set_overcharge_visual(enabled: bool) -> void:
	set_plasma_evolution(&"overcharge" if enabled else &"none")


func set_plasma_evolution(evolution: StringName) -> void:
	overcharge_visual = evolution == &"overcharge"
	ricochet_visual = evolution == &"ricochet"
	if is_node_ready():
		_ensure_ricochet_glow()
		apply_combo_visual()


func _ensure_ricochet_glow() -> void:
	if is_instance_valid(ricochet_glow):
		return
	ricochet_glow = Sprite2D.new()
	ricochet_glow.name = "RicochetProjectileGlow"
	ricochet_glow.texture = sprite.texture
	ricochet_glow.rotation = sprite.rotation
	ricochet_glow.scale = Vector2(0.136, 0.136)
	ricochet_glow.self_modulate = Color(0.224, 1.0, 0.078, 0.0)
	ricochet_glow.z_index = -1
	add_child(ricochet_glow)


func _update_visual_direction() -> void:

	# The projectile asset points right; its existing -90 degree orientation points up.
	sprite.rotation = direction.angle()
	trail.rotation = direction.angle() + PI * 0.5
	if is_instance_valid(ricochet_glow):
		ricochet_glow.rotation = sprite.rotation


func _check_screen_wall_collision() -> void:

	if not wall_bounce_enabled or wall_contact_cooldown > 0.0 or is_queued_for_deletion():
		return
	var gameplay_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	if global_position.x <= gameplay_rect.position.x + 2.0:
		global_position.x = gameplay_rect.position.x + 2.0
		_handle_wall_hit(Vector2.RIGHT)
	elif global_position.x >= gameplay_rect.end.x - 2.0:
		global_position.x = gameplay_rect.end.x - 2.0
		_handle_wall_hit(Vector2.LEFT)
	elif global_position.y <= GameManager.PLAYFIELD_TOP:
		global_position.y = GameManager.PLAYFIELD_TOP
		_handle_wall_hit(Vector2.DOWN)


func _handle_wall_hit(wall_normal: Vector2) -> void:

	if wall_contact_cooldown > 0.0 or is_queued_for_deletion():
		return
	if remaining_wall_bounces <= 0:
		queue_free()
		return
	direction = direction.bounce(wall_normal).normalized()
	remaining_wall_bounces -= 1
	successful_wall_bounces += 1
	wall_contact_cooldown = 0.05
	apply_combo_visual()
	_play_ricochet_bounce_punch()
	_spawn_wall_bounce_feedback()


func _spawn_wall_bounce_feedback() -> void:

	var effect_root := Node2D.new()
	effect_root.name = "PlasmaWallBounceFX"
	effect_root.global_position = global_position
	effect_root.z_index = 32
	get_tree().current_scene.add_child(effect_root)

	var flash := Polygon2D.new()
	flash.polygon = PackedVector2Array([
		Vector2(0.0, -3.0), Vector2(3.0, 0.0),
		Vector2(0.0, 3.0), Vector2(-3.0, 0.0)
	])
	flash.color = PLASMA_CORE_GREEN
	effect_root.add_child(flash)
	var flash_tween := flash.create_tween().set_parallel(true)
	var flash_scale := Vector2(2.15, 2.15) if ricochet_visual else Vector2(1.65, 1.65)
	var flash_duration := 0.15 if ricochet_visual else 0.11
	flash_tween.tween_property(flash, "scale", flash_scale, flash_duration)
	flash_tween.tween_property(flash, "modulate:a", 0.0, flash_duration)

	var spark_count := 8 if ricochet_visual else 4
	for spark_index: int in range(spark_count):
		var spark := Polygon2D.new()
		spark.polygon = PackedVector2Array([
			Vector2(-1.0, -0.45), Vector2(2.2, 0.0), Vector2(-1.0, 0.45)
		])
		spark.color = PLASMA_NEON_GREEN if spark_index % 2 == 0 else PLASMA_CORE_GREEN
		effect_root.add_child(spark)
		var angle: float = randf_range(-PI, PI)
		spark.rotation = angle
		var motion := spark.create_tween().set_parallel(true)
		var spark_distance := randf_range(12.0, 22.0) if ricochet_visual else randf_range(7.0, 13.0)
		motion.tween_property(spark, "position", Vector2.from_angle(angle) * spark_distance, 0.16)
		motion.tween_property(spark, "scale", Vector2(0.15, 0.15), 0.16)
		motion.tween_property(spark, "modulate:a", 0.0, 0.16)

	get_tree().create_timer(0.18).timeout.connect(effect_root.queue_free)


func _play_ricochet_bounce_punch() -> void:
	if not ricochet_visual or not is_instance_valid(sprite):
		return
	var base_scale := Vector2(0.108, 0.108)
	sprite.scale = base_scale * 1.22
	var punch := sprite.create_tween()
	punch.tween_property(sprite, "scale", base_scale, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_instance_valid(ricochet_glow):
		ricochet_glow.modulate.a = 1.0
		var glow_flash := ricochet_glow.create_tween().set_parallel(true)
		glow_flash.tween_property(ricochet_glow, "scale", Vector2(0.18, 0.18), 0.06)
		glow_flash.tween_property(ricochet_glow, "modulate:a", 0.0, 0.12)
		glow_flash.chain().tween_callback(func():
			if is_instance_valid(ricochet_glow):
				ricochet_glow.scale = Vector2(0.136, 0.136)
				apply_combo_visual()
		)


func apply_combo_visual():

	var brightness = 1.0
	var trail_alpha = 0.0

	if combo_rank >= 7:
		brightness = 1.28
		trail_alpha = 0.42
	elif combo_rank >= 5:
		brightness = 1.16
		trail_alpha = 0.28
	if overcharge_visual:
		brightness += 0.14
		trail_alpha = maxf(trail_alpha, 0.34)
		sprite.scale = Vector2(0.113, 0.113)
		trail.width = 2.25
		trail.default_color = Color(0.224, 1.0, 0.078, 0.78)
	else:
		sprite.scale = Vector2(0.1, 0.1)
		trail.width = 2.0
		trail.default_color = Color(0.224, 1.0, 0.078, 0.65)
	if ricochet_visual:
		brightness += 0.16 + minf(float(successful_wall_bounces) * 0.09, 0.27)
		trail_alpha = maxf(trail_alpha, 0.46 + minf(float(successful_wall_bounces) * 0.08, 0.20))
		sprite.scale = Vector2(0.108, 0.108)
		trail.width = 2.15
		trail.default_color = Color(0.224, 1.0, 0.078, 0.82)
	if OS.has_feature("mobile"):
		sprite.scale *= MOBILE_VISUAL_SCALE_MULTIPLIER
		trail.width *= MOBILE_VISUAL_SCALE_MULTIPLIER * 1.15
		trail.default_color.a = minf(trail.default_color.a * 1.18, 0.92)
		brightness *= 1.10

	var visual_tint := Color(
		PLASMA_NEON_GREEN.r * brightness,
		PLASMA_NEON_GREEN.g * brightness,
		PLASMA_NEON_GREEN.b * brightness,
		1.0
	)
	sprite.self_modulate = visual_tint
	trail.modulate.a = trail_alpha
	if is_instance_valid(ricochet_glow):
		ricochet_glow.scale = Vector2(0.136, 0.136) * (
			MOBILE_VISUAL_SCALE_MULTIPLIER if OS.has_feature("mobile") else 1.0
		)
		ricochet_glow.visible = ricochet_visual
		ricochet_glow.self_modulate = Color(
			PLASMA_NEON_GREEN.r, PLASMA_NEON_GREEN.g, PLASMA_NEON_GREEN.b,
			0.20 + minf(float(successful_wall_bounces) * 0.09, 0.27) if ricochet_visual else 0.0
		)


func set_combo_chain_rank(rank_index):

	combo_rank = rank_index
	apply_combo_visual()


func create_impact(use_big_impact):

	var impact = Sprite2D.new()

	if use_big_impact:

		impact.texture = impact_big
		impact.scale = Vector2(0.45, 0.45)

	else:

		impact.texture = impact_small
		impact.scale = Vector2(0.11, 0.11)

	get_parent().add_child(impact)
	impact.global_position = global_position
	impact.z_index = 30

	var target_scale
	var duration

	if use_big_impact:

		target_scale = Vector2(0.95, 0.95)
		duration = 0.24

	else:

		target_scale = impact.scale * 1.45
		duration = 0.22

	var fade = impact.create_tween()
	fade.set_parallel(true)
	fade.tween_property(impact, "scale", target_scale, duration)
	fade.tween_property(impact, "modulate:a", 0.0, duration)
	fade.chain().tween_callback(impact.queue_free)
