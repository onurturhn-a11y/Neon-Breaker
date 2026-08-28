extends Node2D


const VISUALS = {
	"blue": [
		preload("res://assets/bricks/brick_blue.png"),
		preload("res://assets/bricks/brick_blue_hit1.png"),
		preload("res://assets/bricks/brick_blue_low.png")
	],
	"purple": [
		preload("res://assets/bricks/brick_purple.png"),
		preload("res://assets/bricks/brick_purple_hit1.png"),
		preload("res://assets/bricks/brick_purple_low.png")
	],
	"cyan": [
		preload("res://assets/bricks/brick_cyan.png"),
		preload("res://assets/bricks/brick_cyan_hit1.png"),
		preload("res://assets/bricks/brick_cyan_low.png")
	],
	"green": [
		preload("res://assets/bricks/brick_green.png"),
		preload("res://assets/bricks/brick_green_hit1.png"),
		preload("res://assets/bricks/brick_green_low.png")
	],
	"orange": [
		preload("res://assets/bricks/brick_orange.png"),
		preload("res://assets/bricks/brick_orange_hit1.png"),
		preload("res://assets/bricks/brick_orange_low.png")
	]
}

const EFFECTS = {
	"blue": [
		preload("res://assets/bricks/effects/impact_blue_small.png"),
		preload("res://assets/bricks/effects/impact_blue_big.png")
	],
	"purple": [
		preload("res://assets/bricks/effects/impact_purple_small.png"),
		preload("res://assets/bricks/effects/impact_purple_big.png")
	],
	"cyan": [
		preload("res://assets/bricks/effects/impact_cyan_small.png"),
		preload("res://assets/bricks/effects/impact_cyan_big.png")
	],
	"green": [
		preload("res://assets/bricks/effects/impact_green_small.png"),
		preload("res://assets/bricks/effects/impact_green_big.png")
	],
	"orange": [
		preload("res://assets/bricks/effects/impact_orange_small.png"),
		preload("res://assets/bricks/effects/impact_orange_big.png")
	]
}

const COLOR_REFERENCES = {
	"blue": Color("#247cff"),
	"purple": Color("#b84dff"),
	"cyan": Color("#00e5ff"),
	"green": Color("#28e07b"),
	"orange": Color("#ff7a2f")
}

const EXPLOSIVE_SOURCE_TEXTURE = preload("res://assets/bricks/brick_explosive.png")
const EXPLOSIVE_TEXTURE_REGION = Rect2(0.0, 365.0, 1254.0, 525.0)
const EXPLOSIVE_TEXTURE_SCALE = Vector2(0.079745, 0.079745)
const ARMORED_TEXTURE = preload("res://assets/bricks/brick_armored.png")
const ARMORED_TEXTURE_SCALE = Vector2(0.065, 0.065)
const NORMAL_BRICK_RENDER_WIDTH = 100.0

@onready var sprite = $Sprite2D

var visual_color = "blue"
var armor_damage_overlay: Node2D
var explosive_marker: Node2D
var explosive_core: Polygon2D
var explosive_spark_timer = 0.0
var explosive_texture: AtlasTexture
var fireball_reaction_tween: Tween


func _ready():

	# Yüksek çözünürlüklü neon brick texture'ları sub-pixel harekette Linear kullanır.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.modulate = Color.WHITE
	sprite.self_modulate = Color.WHITE

func configure(brick_color, health, max_health):

	visual_color = find_closest_color(brick_color)
	update_health(health, max_health)


func set_explosive(enabled):

	if not enabled:
		if is_instance_valid(explosive_marker):
			explosive_marker.queue_free()
		return

	if explosive_texture == null:
		explosive_texture = AtlasTexture.new()
		explosive_texture.atlas = EXPLOSIVE_SOURCE_TEXTURE
		explosive_texture.region = EXPLOSIVE_TEXTURE_REGION
	sprite.texture = explosive_texture
	sprite.scale = EXPLOSIVE_TEXTURE_SCALE
	sprite.modulate = Color.WHITE
	sprite.self_modulate = Color.WHITE

	explosive_marker = Node2D.new()
	explosive_marker.name = "FuseSpark"
	explosive_marker.position = Vector2(38, -12)
	explosive_marker.z_index = 7
	add_child(explosive_marker)

	explosive_core = Polygon2D.new()
	explosive_core.polygon = PackedVector2Array([
		Vector2(0, -2.4), Vector2(2.0, 0),
		Vector2(0, 2.4), Vector2(-2.0, 0)
	])
	explosive_core.color = Color(1.0, 0.82, 0.38, 0.92)
	explosive_marker.add_child(explosive_core)

	var spark_glow = Polygon2D.new()
	spark_glow.name = "SoftSparkGlow"
	spark_glow.polygon = PackedVector2Array([
		Vector2(0, -4.2), Vector2(3.6, 0),
		Vector2(0, 4.2), Vector2(-3.6, 0)
	])
	spark_glow.color = Color(1.0, 0.35, 0.05, 0.16)
	spark_glow.z_index = -1
	explosive_marker.add_child(spark_glow)
	explosive_spark_timer = randf_range(0.7, 1.0)


func _process(delta):

	if not is_instance_valid(explosive_marker):
		return

	explosive_spark_timer -= delta
	if explosive_spark_timer <= 0.0:
		play_fuse_glint()
		spawn_fuse_spark()
		explosive_spark_timer = randf_range(0.7, 1.0)

func play_fuse_glint():

	if not is_instance_valid(explosive_core):
		return

	explosive_core.scale = Vector2.ONE
	explosive_core.modulate.a = 1.0
	var glint = explosive_core.create_tween()
	glint.tween_property(explosive_core, "scale", Vector2(1.18, 1.18), 0.08).set_trans(Tween.TRANS_SINE)
	glint.parallel().tween_property(explosive_core, "modulate:a", 0.78, 0.08)
	glint.tween_property(explosive_core, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE)
	glint.parallel().tween_property(explosive_core, "modulate:a", 1.0, 0.16)


func spawn_fuse_spark():

	var spark = Polygon2D.new()
	spark.polygon = PackedVector2Array([
		Vector2(-0.8, -0.5), Vector2(1.8, 0), Vector2(-0.8, 0.5)
	])
	spark.color = Color("#FFB340")
	spark.position = explosive_marker.position + Vector2(randf_range(-2.0, 2.0), randf_range(-1.0, 1.0))
	spark.z_index = 8
	add_child(spark)

	var motion = spark.create_tween()
	motion.set_parallel(true)
	motion.tween_property(spark, "position", spark.position + Vector2(randf_range(-3.0, 3.0), -7.0), 0.24)
	motion.tween_property(spark, "scale", Vector2(0.2, 0.2), 0.24)
	motion.tween_property(spark, "modulate:a", 0.0, 0.24)
	motion.chain().tween_callback(spark.queue_free)


func update_health(health, max_health):
	if max_health > 1:
		sprite.texture = ARMORED_TEXTURE
		sprite.scale = ARMORED_TEXTURE_SCALE
		sprite.modulate = Color.WHITE
		sprite.self_modulate = Color.WHITE
		if health < max_health:
			show_armored_damage_state()
		else:
			clear_armored_damage_state()
		return

	var state = 0
	if max_health > 1 and health < max_health:
		if health <= 1:
			state = 2
		else:
			state = 1

	var normal_texture: Texture2D = VISUALS[visual_color][state]
	sprite.texture = normal_texture
	var normal_scale: float = NORMAL_BRICK_RENDER_WIDTH / float(normal_texture.get_width())
	sprite.scale = Vector2(normal_scale, normal_scale)
	sprite.modulate = Color.WHITE
	sprite.self_modulate = Color.WHITE

func find_closest_color(brick_color):

	var closest_name = "blue"
	var closest_distance = INF

	for color_name in COLOR_REFERENCES:

		var reference = COLOR_REFERENCES[color_name]
		var distance = (
			pow(brick_color.r - reference.r, 2)
			+ pow(brick_color.g - reference.g, 2)
			+ pow(brick_color.b - reference.b, 2)
		)

		if distance < closest_distance:

			closest_distance = distance
			closest_name = color_name

	return closest_name


func get_display_color():

	return COLOR_REFERENCES[visual_color]




func play_fireball_splash_reaction() -> void:
	if not is_instance_valid(sprite):
		return
	if is_instance_valid(fireball_reaction_tween):
		fireball_reaction_tween.kill()
	var original_scale: Vector2 = sprite.scale
	sprite.modulate = Color(1.34, 0.66, 0.34, 1.0)
	fireball_reaction_tween = sprite.create_tween()
	fireball_reaction_tween.set_trans(Tween.TRANS_QUAD)
	fireball_reaction_tween.set_ease(Tween.EASE_OUT)
	fireball_reaction_tween.tween_property(sprite, "scale", original_scale * 1.06, 0.04)
	fireball_reaction_tween.parallel().tween_property(sprite, "modulate", Color(1.16, 0.78, 0.56, 1.0), 0.04)
	fireball_reaction_tween.tween_property(sprite, "scale", original_scale, 0.06)
	fireball_reaction_tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.06)

func play_armor_hit_effect(_brick_color):

	spawn_small_impact()
	spawn_armor_sparks()

	var original_scale = ARMORED_TEXTURE_SCALE
	sprite.scale = original_scale
	sprite.modulate = Color(1.42, 1.18, 0.86, 1.0)
	var impulse = sprite.create_tween()
	impulse.set_parallel(true)
	impulse.tween_property(sprite, "scale", original_scale * 1.03, 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	impulse.tween_property(sprite, "modulate", Color.WHITE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	impulse.chain().tween_property(sprite, "scale", original_scale, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func show_armored_damage_state():

	if is_instance_valid(armor_damage_overlay):
		return

	armor_damage_overlay = Node2D.new()
	armor_damage_overlay.name = "ArmorDamageState"
	armor_damage_overlay.z_index = 6
	add_child(armor_damage_overlay)

	var crack_left = Line2D.new()
	crack_left.points = PackedVector2Array([
		Vector2(-29, -12), Vector2(-24, -6), Vector2(-27, -1), Vector2(-19, 5)
	])
	crack_left.width = 1.15
	crack_left.antialiased = true
	crack_left.default_color = Color(1.0, 0.58, 0.16, 0.72)
	armor_damage_overlay.add_child(crack_left)

	var crack_right = Line2D.new()
	crack_right.points = PackedVector2Array([
		Vector2(27, -9), Vector2(21, -3), Vector2(25, 2), Vector2(18, 9)
	])
	crack_right.width = 0.9
	crack_right.antialiased = true
	crack_right.default_color = Color(1.0, 0.36, 0.08, 0.58)
	armor_damage_overlay.add_child(crack_right)

	for leak_position in [Vector2(-20, 5), Vector2(20, 8), Vector2(29, -7)]:
		var leak = Polygon2D.new()
		leak.position = leak_position
		leak.polygon = PackedVector2Array([
			Vector2(-1.8, -0.5), Vector2(2.4, 0), Vector2(-1.8, 0.5)
		])
		leak.color = Color(1.0, 0.42, 0.06, 0.64)
		armor_damage_overlay.add_child(leak)


func clear_armored_damage_state():

	if is_instance_valid(armor_damage_overlay):
		armor_damage_overlay.queue_free()
	armor_damage_overlay = null


func spawn_armor_sparks():

	var armor_spark_count := randi_range(4, 6) + (1 if OS.has_feature("mobile") else 0)
	for spark_index in range(armor_spark_count):
		var spark = Polygon2D.new()
		spark.polygon = PackedVector2Array([
			Vector2(-1.2, -0.55), Vector2(2.8, 0), Vector2(-1.2, 0.55)
		])
		spark.color = Color(0.92, 0.82, 0.66, 1.0) if spark_index % 2 == 0 else Color(1.0, 0.48, 0.08, 1.0)
		spark.z_index = 34
		get_tree().current_scene.add_child(spark)
		spark.global_position = global_position + Vector2(randf_range(-20.0, 20.0), randf_range(-8.0, 8.0))
		var angle = randf_range(-PI, 0.0)
		spark.rotation = angle
		var duration = randf_range(0.16, 0.22)
		var target = spark.global_position + Vector2.from_angle(angle) * randf_range(15.0, 28.0)
		var motion = spark.create_tween().set_parallel(true)
		motion.tween_property(spark, "global_position", target, duration)
		motion.tween_property(spark, "rotation", angle + randf_range(-1.2, 1.2), duration)
		motion.tween_property(spark, "scale", Vector2(0.12, 0.12), duration)
		motion.tween_property(spark, "modulate:a", 0.0, duration)
		motion.chain().tween_callback(spark.queue_free)


func play_break_effect(_brick_color, source = "ball"):

	if source == "plasma":

		var plasma_original_scale = sprite.scale
		var original_rotation = sprite.rotation

		var warmup = create_tween()
		warmup.tween_property(
			sprite,
			"modulate",
			Color(1.15, 1.18, 1.2, 1),
			0.05
		)
		await warmup.finished

		spawn_plasma_sparks()

		var collapse = create_tween()
		collapse.set_parallel(true)
		collapse.set_trans(Tween.TRANS_QUAD)
		collapse.set_ease(Tween.EASE_IN)
		collapse.tween_property(sprite, "scale", plasma_original_scale * 0.65, 0.07)
		collapse.tween_property(sprite, "rotation", original_rotation + 0.04, 0.07)
		collapse.tween_property(sprite, "modulate:a", 0.82, 0.07)
		await collapse.finished

		var vanish = create_tween()
		vanish.set_parallel(true)
		vanish.set_trans(Tween.TRANS_QUAD)
		vanish.set_ease(Tween.EASE_IN)
		vanish.tween_property(sprite, "scale", Vector2.ZERO, 0.10)
		vanish.tween_property(sprite, "rotation", original_rotation + 0.10, 0.10)
		vanish.tween_property(sprite, "modulate:a", 0.0, 0.10)
		await vanish.finished
		return

	spawn_big_impact()
	spawn_ball_fragments()

	var original_scale = sprite.scale
	var flash = create_tween()
	flash.set_parallel(true)
	flash.tween_property(sprite, "scale", original_scale * 1.10, 0.04)
	var break_flash := Color(2.30, 2.30, 2.30, 1) if OS.has_feature("mobile") else Color(2.0, 2.0, 2.0, 1)
	flash.tween_property(sprite, "modulate", break_flash, 0.04)
	await flash.finished

	var settle = create_tween()
	settle.set_parallel(true)
	settle.tween_property(sprite, "scale", original_scale * 0.88, 0.06)
	settle.tween_property(sprite, "modulate", Color.WHITE, 0.06)
	await settle.finished


func spawn_small_impact():

	var effect = create_effect_sprite(EFFECTS[visual_color][0])
	var base_scale = Vector2(0.22, 0.22)
	if OS.has_feature("mobile"):
		base_scale *= 1.20
	effect.scale = base_scale * 0.55

	var tween = effect.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "scale", base_scale * 1.12, 0.16)
	tween.tween_property(effect, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(effect.queue_free)


func spawn_big_impact():

	var effect = create_effect_sprite(EFFECTS[visual_color][1])
	var base_scale = Vector2(0.34, 0.34)
	if OS.has_feature("mobile"):
		base_scale *= 1.20
	effect.scale = base_scale * 0.45

	var tween = effect.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "scale", base_scale * 1.18, 0.16)
	tween.tween_property(effect, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(effect.queue_free)


func spawn_ball_fragments():

	var source_texture = sprite.texture
	var texture_size = source_texture.get_size()
	var columns = 4
	var rows = 2
	var region_size = Vector2(
		texture_size.x / columns,
		texture_size.y / rows
	)

	for row in range(rows):

		for column in range(columns):

			var region_position = Vector2(
				column * region_size.x,
				row * region_size.y
			)

			var fragment_texture = AtlasTexture.new()
			fragment_texture.atlas = source_texture
			fragment_texture.region = Rect2(
				region_position,
				region_size
			)

			var fragment = Sprite2D.new()
			fragment.texture = fragment_texture
			fragment.scale = sprite.global_scale
			fragment.rotation = sprite.global_rotation

			fragment.modulate = sprite.modulate
			if OS.has_feature("mobile"):
				fragment.modulate *= Color(1.16, 1.16, 1.16, 1.0)
			fragment.z_index = 31
			get_tree().current_scene.add_child(fragment)

			var texture_center = region_position + region_size * 0.5
			var local_offset = texture_center - texture_size * 0.5
			fragment.global_position = sprite.to_global(local_offset)

			var outward = (
				fragment.global_position - global_position
			).normalized()

			outward = outward.rotated(
				randf_range(-0.55, 0.55)
			)

			var duration = randf_range(0.30, 0.45)
			var target_position = (
				fragment.global_position
				+ outward * randf_range(32.0, 62.0)
			)

			var target_rotation = (
				fragment.rotation
				+ randf_range(-2.2, 2.2)
			)

			var motion = fragment.create_tween()
			motion.set_parallel(true)
			motion.set_trans(Tween.TRANS_QUAD)
			motion.set_ease(Tween.EASE_OUT)
			motion.tween_property(fragment, "global_position", target_position, duration)
			motion.tween_property(fragment, "rotation", target_rotation, duration)
			motion.tween_property(fragment, "scale", fragment.scale * 0.15, duration)
			motion.tween_property(fragment, "modulate:a", 0.0, duration)
			motion.chain().tween_callback(fragment.queue_free)


func spawn_plasma_sparks():

	for i in range(7 if OS.has_feature("mobile") else 6):

		var spark = Polygon2D.new()
		spark.polygon = PackedVector2Array([
			Vector2(-1.0, -0.6),
			Vector2(2.5, 0),
			Vector2(-1.0, 0.6)
		])
		spark.color = Color(0.45, 0.95, 1.0, 1.0)
		spark.z_index = 33
		spark.scale = Vector2.ONE
		get_tree().current_scene.add_child(spark)
		spark.global_position = global_position

		var angle = randf_range(0.0, TAU)
		var target = (
			spark.global_position
			+ Vector2.from_angle(angle) * randf_range(22.0, 48.0)
		)
		var duration = randf_range(0.18, 0.28)
		spark.rotation = angle

		var motion = spark.create_tween()
		motion.set_parallel(true)
		motion.tween_property(spark, "global_position", target, duration)
		motion.tween_property(spark, "scale", Vector2(0.1, 0.1), duration)
		motion.tween_property(spark, "modulate:a", 0.0, duration)
		motion.chain().tween_callback(spark.queue_free)


func create_effect_sprite(texture):

	var cropped_texture = AtlasTexture.new()
	cropped_texture.atlas = texture
	cropped_texture.region = Rect2(
		0,
		22,
		texture.get_width(),
		texture.get_height() - 22
	)

	var effect = Sprite2D.new()
	effect.texture = cropped_texture
	effect.z_index = 30
	get_tree().current_scene.add_child(effect)
	effect.global_position = global_position
	return effect
