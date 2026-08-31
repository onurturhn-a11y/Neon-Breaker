extends Node2D


const NORMAL_BALL_TEXTURE: Texture2D = preload("res://assets/ball/normal_ball.png")
const PIERCING_BALL_TEXTURE: Texture2D = preload("res://assets/ball/piercing_ball.png")
const FIRE_BALL_VISUAL_SCENE: PackedScene = preload("res://balls/fire_ball_visual.tscn")
const BALL_VISUAL_DIAMETER := 40.0
const PIERCING_VISUAL_DIAMETER := 44.0

const TRAIL_TEXTURES = [
	preload("res://assets/ball/trail_1.png"),
	preload("res://assets/ball/trail_2.png"),
	preload("res://assets/ball/trail_3.png"),
	preload("res://assets/ball/trail_4.png"),
	preload("res://assets/ball/trail_5.png"),
	preload("res://assets/ball/trail_6.png")
]

const IDLE_BASE_ROTATION_SPEED = 60.0
const MOVING_BASE_ROTATION_MIN = 220.0
const MOVING_BASE_ROTATION_MAX = 500.0
const CORE_ROTATION_RATIO = -0.60
const GLOW_ROTATION_RATIO = 0.08

const WARM_PALETTE_SHADER = """
shader_type canvas_item;

uniform vec4 shadow_color : source_color;
uniform vec4 mid_color : source_color;
uniform vec4 highlight_color : source_color;
uniform float radial_strength : hint_range(0.0, 1.0) = 1.0;

varying vec4 item_modulate;

void vertex() {
	item_modulate = COLOR;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float detail = max(max(source.r, source.g), source.b);
	float radial = clamp(length(UV - vec2(0.5)) * 2.0, 0.0, 1.0);

	vec3 detail_palette = mix(shadow_color.rgb, mid_color.rgb, smoothstep(0.05, 0.52, detail));
	detail_palette = mix(detail_palette, highlight_color.rgb, smoothstep(0.55, 0.98, detail));

	vec3 radial_palette = mix(highlight_color.rgb, mid_color.rgb, smoothstep(0.12, 0.62, radial));
	radial_palette = mix(radial_palette, shadow_color.rgb, smoothstep(0.66, 1.0, radial));
	vec3 palette = mix(detail_palette, radial_palette, radial_strength * 0.72);

	float brightness = dot(item_modulate.rgb, vec3(0.333333));
	COLOR = vec4(palette * brightness, source.a * item_modulate.a);
}
"""

@onready var ball = get_parent()
@onready var base_layer = $BaseLayer
@onready var core_layer = $CoreLayer
@onready var glow_layer = $GlowLayer

var pulse_time = 0.0
var trail_timer = 0.0
var core_hit_boost = 0.0
var glow_hit_scale = 0.0
var hit_tween: Tween
var combo_chain_rank = -1
var chain_arc_timer = 0.0
var pierce_level = 0
var fireball_level = 0
var pierce_indicator: Polygon2D
var warm_palette_shader: Shader
var orange_trail_material: ShaderMaterial
var fire_ball_visual: Node2D
var core_resonance_ready := false
var core_resonance_indicator: Line2D

var base_scale = Vector2(0.069615, 0.069615)
var core_scale = Vector2(0.07541625, 0.07541625)
var glow_scale = Vector2(0.069615, 0.069615)


func _ready():

	setup_warm_palette()

	fire_ball_visual = FIRE_BALL_VISUAL_SCENE.instantiate() as Node2D

	fire_ball_visual.name = "FireBallVisual"

	add_child(fire_ball_visual)

	setup_ball_skin()
	create_pierce_indicator()
	create_core_resonance_indicator()


func _process(delta):

	pulse_time += delta
	set_core_resonance_ready(GameManager.is_core_resonance_ready())
	update_core_resonance_indicator()

	var speed_ratio = clamp(
		(ball.speed - 500.0) / (ball.max_speed - 500.0),
		0.0,
		1.0
	)

	update_visual_rotation(delta)

	var core_pulse = (
		sin(pulse_time * TAU / 0.85) + 1.0
	) * 0.5

	core_layer.scale = (
		core_scale
		* lerp(0.92, 1.08, core_pulse)
	)

	var core_brightness = (
		lerp(1.0, 1.22, speed_ratio)
		+ core_hit_boost
	)
	if combo_chain_rank >= 0:
		core_brightness += get_combo_electric_strength()
	core_brightness += pierce_level * 0.055
	core_brightness += fireball_level * 0.045
	if OS.has_feature("mobile"):
		core_brightness *= 1.10
	core_layer.modulate = Color(
		core_brightness,
		core_brightness,
		core_brightness,
		1.0
	)

	var glow_pulse = (
		sin(pulse_time * TAU / 1.55 + 0.6) + 1.0
	) * 0.5

	glow_layer.scale = (
		glow_scale
		* lerp(0.96, 1.04, glow_pulse)
		* (1.0 + glow_hit_scale)
	)

	glow_layer.modulate.a = clamp(
		lerp(0.32, 0.48, glow_pulse)
		+ speed_ratio * 0.18,
		0.0,
		0.72
	)
	if OS.has_feature("mobile"):
		glow_layer.modulate.a = minf(glow_layer.modulate.a * 1.10, 0.79)
	if combo_chain_rank >= 0:
		glow_layer.modulate.a = minf(
			glow_layer.modulate.a + get_combo_electric_strength() * 0.62,
			0.88
		)
	if pierce_level > 0:
		glow_layer.modulate.a = minf(
			glow_layer.modulate.a + pierce_level * 0.025,
			0.88
		)
		update_pierce_indicator()
	if fireball_level > 0:
		glow_layer.modulate.a = minf(glow_layer.modulate.a + fireball_level * 0.035, 0.9)

	chain_arc_timer -= delta
	if combo_chain_rank >= 0 and chain_arc_timer <= 0.0:
		spawn_ball_electric_arc()
		if combo_chain_rank <= 1:
			chain_arc_timer = randf_range(0.18, 0.26)
		elif combo_chain_rank <= 4:
			chain_arc_timer = randf_range(0.11, 0.18)
		else:
			chain_arc_timer = randf_range(0.08, 0.14)

	trail_timer -= delta

	if fireball_level <= 0 and trail_timer <= 0.0 and ball.velocity.length_squared() > 0.0:

		spawn_trail(speed_ratio)
		trail_timer = lerp(0.028, 0.022, speed_ratio)


func spawn_trail(speed_ratio):

	var texture_index

	if speed_ratio >= 0.90:

		texture_index = 0

	elif speed_ratio >= 0.62:

		texture_index = 1

	elif speed_ratio >= 0.38:

		texture_index = 2

	else:

		texture_index = 3

	var trail = Sprite2D.new()
	trail.texture = TRAIL_TEXTURES[texture_index]
	trail.scale = Vector2.ONE * lerp(0.0580125, 0.0716625, speed_ratio)
	trail.modulate.a = lerp(0.30, 0.52, speed_ratio)
	if fireball_level > 0 and combo_chain_rank < 0:
		trail.material = orange_trail_material
	if combo_chain_rank >= 0:
		trail.texture = TRAIL_TEXTURES[mini(texture_index, 1)]
		var electric_strength = get_combo_electric_strength()
		trail.scale *= 1.0 + electric_strength * 0.25
		trail.modulate = Color(
			0.72,
			0.96,
			1.0,
			minf(trail.modulate.a + electric_strength * 0.55, 0.68)
		)
	if pierce_level > 0:
		trail.texture = TRAIL_TEXTURES[mini(texture_index, 2)]
		trail.modulate = Color(
			0.88,
			0.97,
			1.0,
			minf(trail.modulate.a + pierce_level * 0.035, 0.68)
		)
	if fireball_level > 0 and combo_chain_rank < 0:
		trail.modulate = Color(1.0, 0.62, 0.20, minf(trail.modulate.a + 0.04 * fireball_level, 0.68))
	if OS.has_feature("mobile"):
		trail.modulate.a = minf(trail.modulate.a * 1.18, 0.82)
	trail.z_index = -1

	get_tree().current_scene.add_child(trail)
	var movement_direction = ball.direction.normalized()
	trail.global_position = (
		ball.global_position
		- movement_direction * 6.0
	)
	trail.rotation = movement_direction.angle() - PI * 0.75

	var lifetime = lerp(0.12, 0.15, speed_ratio)
	if OS.has_feature("mobile"):
		lifetime *= 1.23
	var fade = trail.create_tween()
	fade.set_parallel(true)
	fade.tween_property(trail, "scale", trail.scale * 0.72, lifetime)
	fade.tween_property(trail, "modulate:a", 0.0, lifetime)
	fade.chain().tween_callback(trail.queue_free)


func create_core_resonance_indicator() -> void:
	if is_instance_valid(core_resonance_indicator):
		return
	core_resonance_indicator = Line2D.new()
	core_resonance_indicator.name = "CoreResonanceReady"
	core_resonance_indicator.width = 1.8
	core_resonance_indicator.closed = true
	core_resonance_indicator.antialiased = true
	core_resonance_indicator.z_index = 7
	for index in range(28):
		core_resonance_indicator.add_point(
			Vector2.from_angle(TAU * float(index) / 28.0) * 24.0
		)
	add_child(core_resonance_indicator)
	core_resonance_indicator.visible = false


func set_core_resonance_ready(value: bool) -> void:
	core_resonance_ready = value
	if is_instance_valid(core_resonance_indicator):
		core_resonance_indicator.visible = value


func update_core_resonance_indicator() -> void:
	if not core_resonance_ready or not is_instance_valid(core_resonance_indicator):
		return
	var pulse := 0.5 + 0.5 * sin(pulse_time * TAU / 0.90)
	var color := Color(1.0, 0.46, 0.12, 1.0) if fireball_level > 0 else Color(0.56, 0.88, 1.0, 1.0)
	core_resonance_indicator.default_color = color
	core_resonance_indicator.modulate.a = 0.34 + pulse * 0.30
	core_resonance_indicator.scale = Vector2.ONE * (0.97 + pulse * 0.06)


func play_core_resonance_proc(core_id: StringName) -> void:
	var flash := Line2D.new()
	flash.name = "CoreResonanceProc"
	flash.width = 2.4
	flash.closed = true
	flash.antialiased = true
	flash.z_index = 8
	flash.default_color = (
		Color(1.0, 0.48, 0.14, 0.95)
		if core_id == &"fireball"
		else Color(0.62, 0.92, 1.0, 0.95)
	)
	for index in range(28):
		flash.add_point(Vector2.from_angle(TAU * float(index) / 28.0) * 23.0)
	add_child(flash)
	var tween := flash.create_tween().set_parallel(true)
	tween.tween_property(flash, "scale", Vector2.ONE * 1.34, 0.20)
	tween.tween_property(flash, "modulate:a", 0.0, 0.20)
	tween.chain().tween_callback(flash.queue_free)


func setup_ball_skin() -> void:
	var active_texture: Texture2D = NORMAL_BALL_TEXTURE
	var target_diameter := BALL_VISUAL_DIAMETER
	var glow_color := Color(0.30, 0.84, 1.0, glow_layer.modulate.a)
	if fireball_level > 0:
		glow_color = Color(1.0, 0.30, 0.06, glow_layer.modulate.a)
	elif pierce_level > 0:
		active_texture = PIERCING_BALL_TEXTURE
		target_diameter = PIERCING_VISUAL_DIAMETER
		glow_color = Color(0.72, 0.22, 1.0, glow_layer.modulate.a)

	base_layer.texture = active_texture

	var fire_active: bool = int(fireball_level) > 0

	base_layer.visible = not fire_active

	core_layer.visible = false

	glow_layer.visible = not fire_active

	if is_instance_valid(fire_ball_visual):

		if fire_ball_visual.has_method("set_active"):

			fire_ball_visual.set_active(fire_active)

		else:

			fire_ball_visual.visible = fire_active

	base_layer.material = null
	base_scale = Vector2.ONE * (target_diameter / float(maxi(active_texture.get_width(), active_texture.get_height())))
	base_layer.scale = base_scale
	core_layer.visible = false
	glow_layer.material = null
	glow_layer.modulate = glow_color

func setup_warm_palette():

	warm_palette_shader = Shader.new()
	warm_palette_shader.code = WARM_PALETTE_SHADER

	base_layer.material = create_warm_material(
		Color("#FF5A00"),
		Color("#FF8500"),
		Color("#FFB340"),
		0.82
	)
	core_layer.material = create_warm_material(
		Color("#FF8500"),
		Color("#FFB340"),
		Color("#FFF1D6"),
		0.64
	)
	glow_layer.material = create_warm_material(
		Color("#FF5A00"),
		Color("#FF8500"),
		Color("#FFB340"),
		0.90
	)
	orange_trail_material = create_warm_material(
		Color("#FF5A00"),
		Color("#FF8500"),
		Color("#FFB340"),
		0.0
	)


func create_warm_material(shadow_color, mid_color, highlight_color, radial_strength):

	var material = ShaderMaterial.new()
	material.shader = warm_palette_shader
	material.set_shader_parameter("shadow_color", shadow_color)
	material.set_shader_parameter("mid_color", mid_color)
	material.set_shader_parameter("highlight_color", highlight_color)
	material.set_shader_parameter("radial_strength", radial_strength)
	return material


func set_fireball_level(level):

	fireball_level = clampi(level, 0, 3)
	setup_ball_skin()


func update_visual_rotation(delta):

	var base_speed_degrees = IDLE_BASE_ROTATION_SPEED

	if ball.ball_launched:
		var movement_speed_ratio = clampf(
			inverse_lerp(200.0, ball.max_speed, ball.speed),
			0.0,
			1.0
		)
		base_speed_degrees = lerpf(
			MOVING_BASE_ROTATION_MIN,
			MOVING_BASE_ROTATION_MAX,
			movement_speed_ratio
		)

	var base_rotation_step = deg_to_rad(base_speed_degrees) * delta
	base_layer.rotation += base_rotation_step
	core_layer.rotation += base_rotation_step * CORE_ROTATION_RATIO
	glow_layer.rotation += base_rotation_step * GLOW_ROTATION_RATIO


func set_combo_chain_rank(rank_index):

	combo_chain_rank = rank_index

	if is_instance_valid(fire_ball_visual) and fire_ball_visual.has_method("set_combo_rank"):

		fire_ball_visual.set_combo_rank(rank_index)

	if combo_chain_rank >= 0:
		chain_arc_timer = 0.0


func set_pierce_level(level):

	pierce_level = clampi(level, 0, 3)
	setup_ball_skin()
	if not is_instance_valid(pierce_indicator):
		create_pierce_indicator()
	pierce_indicator.visible = pierce_level > 0


func create_pierce_indicator():

	if is_instance_valid(pierce_indicator):
		return

	pierce_indicator = Polygon2D.new()
	pierce_indicator.name = "PierceDirectionIndicator"
	pierce_indicator.polygon = PackedVector2Array([
		Vector2(7.0, 0.0),
		Vector2(-2.0, -2.2),
		Vector2(-5.0, 0.0),
		Vector2(-2.0, 2.2)
	])
	pierce_indicator.color = Color(0.9, 0.98, 1.0, 0.0)
	pierce_indicator.z_index = 2
	pierce_indicator.visible = pierce_level > 0
	add_child(pierce_indicator)


func update_pierce_indicator():

	if not is_instance_valid(pierce_indicator):
		return

	var movement_direction = ball.direction.normalized()
	pierce_indicator.position = movement_direction * 12.0
	pierce_indicator.rotation = movement_direction.angle()
	pierce_indicator.scale = Vector2(1.0 + pierce_level * 0.08, 1.0)
	pierce_indicator.color.a = 0.34 + pierce_level * 0.08


func get_combo_electric_strength():

	if combo_chain_rank <= 1:
		return 0.08
	if combo_chain_rank <= 4:
		return 0.16
	return 0.24


func spawn_ball_electric_arc():

	var arc = Line2D.new()
	arc.width = 1.15
	arc.default_color = Color(0.78, 0.98, 1.0, 0.92)
	arc.antialiased = true
	arc.z_index = 3
	add_child(arc)

	var points = PackedVector2Array()
	var start_angle = randf_range(0.0, TAU)
	var arc_length = randf_range(0.7, 1.3)
	for i in range(5):
		var ratio = float(i) / 4.0
		var angle = start_angle + arc_length * ratio
		var radius = randf_range(10.0, 14.0)
		points.append(Vector2.from_angle(angle) * radius)
	arc.points = points

	var fade = arc.create_tween()
	fade.tween_property(arc, "modulate:a", 0.0, 0.09)
	fade.tween_callback(arc.queue_free)


func play_collision_feedback(hit_type, contact_position, surface_normal):
	if fireball_level > 0 and is_instance_valid(fire_ball_visual) and fire_ball_visual.has_method("play_collision_feedback"):
		fire_ball_visual.play_collision_feedback(hit_type, contact_position, surface_normal)

	var spark_count = 4
	var feedback_duration = 0.07
	var spark_distance = Vector2(10.0, 20.0)
	var spark_size = 1.0
	var spark_lifetime = Vector2(0.10, 0.18)
	var spark_z_index = 8
	var spark_normal = surface_normal

	core_hit_boost = 0.14
	glow_hit_scale = 0.0
	spark_size = 1.25
	spark_lifetime = Vector2(0.12, 0.18)
	spark_z_index = 12

	if hit_type == "paddle":

		spark_count = 7
		feedback_duration = 0.09
		spark_distance = Vector2(16.0, 30.0)
		spark_size = 1.85
		spark_lifetime = Vector2(0.18, 0.25)
		spark_z_index = 12
		spark_normal = (
			surface_normal.normalized()
			+ Vector2.UP * 0.75
		).normalized()
		core_hit_boost = 0.26
		glow_hit_scale = 0.10

	elif hit_type == "brick":

		spark_count = 5
		feedback_duration = 0.08
		spark_distance = Vector2(14.0, 26.0)
		spark_size = 1.65
		spark_lifetime = Vector2(0.18, 0.25)
		spark_z_index = 12
		core_hit_boost = 0.20
		if OS.has_feature("mobile"):
			spark_count = 6
			spark_size *= 1.16
			core_hit_boost *= 1.18
			glow_hit_scale = 0.08

	spawn_contact_sparks(
		contact_position,
		spark_normal,
		spark_count,
		spark_distance,
		spark_size,
		spark_lifetime,
		spark_z_index
	)

	if hit_tween:
		hit_tween.kill()

	hit_tween = create_tween()
	hit_tween.set_parallel(true)
	hit_tween.tween_property(
		self,
		"core_hit_boost",
		0.0,
		feedback_duration
	)
	hit_tween.tween_property(
		self,
		"glow_hit_scale",
		0.0,
		feedback_duration
	)


func spawn_contact_sparks(
	contact_position,
	surface_normal,
	spark_count,
	spark_distance,
	spark_size,
	spark_lifetime,
	spark_z_index
):

	var normal = surface_normal.normalized()

	for i in range(spark_count):

		var spark = Polygon2D.new()
		spark.polygon = PackedVector2Array([
			Vector2(-0.8, -0.5) * spark_size,
			Vector2(2.2, 0) * spark_size,
			Vector2(-0.8, 0.5) * spark_size
		])
		spark.color = Color(
			randf_range(0.55, 0.9),
			randf_range(0.9, 1.0),
			1.0,
			1.0
		)
		spark.modulate.a = 1.0
		spark.z_index = spark_z_index
		get_tree().current_scene.add_child(spark)
		spark.global_position = contact_position

		var direction = normal.rotated(
			randf_range(-0.65, 0.65)
		)
		var distance = randf_range(
			spark_distance.x,
			spark_distance.y
		)
		var duration = randf_range(
			spark_lifetime.x,
			spark_lifetime.y
		)
		spark.rotation = direction.angle()

		var motion = spark.create_tween()
		motion.set_parallel(true)
		motion.set_trans(Tween.TRANS_QUAD)
		motion.set_ease(Tween.EASE_OUT)
		motion.tween_property(
			spark,
			"global_position",
			contact_position + direction * distance,
			duration
		)
		motion.tween_property(
			spark,
			"scale",
			Vector2(0.1, 0.1),
			duration
		)
		motion.tween_property(spark, "modulate:a", 0.0, duration)
		motion.chain().tween_callback(spark.queue_free)








