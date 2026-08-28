extends Node2D

const CORE_ROTATION_SPEED := deg_to_rad(14.0)
const CORE_PULSE_DURATION := 1.25
const CORE_BASE_SCALE := Vector2.ONE * 0.34
const MAIN_FLAME_BASE_SCALE := Vector2(0.24, 0.22)
const SIDE_FLAME_BASE_SCALE := Vector2(0.22, 0.18)
const CORE_MASK_SHADER := """
shader_type canvas_item;
uniform float mask_radius : hint_range(0.1, 0.5) = 0.43;
void fragment() {
	vec4 tex_color = texture(TEXTURE, UV) * COLOR;
	float distance_from_center = length(UV - vec2(0.5));
	tex_color.a *= 1.0 - smoothstep(mask_radius - 0.035, mask_radius, distance_from_center);
	COLOR = tex_color;
}
"""

@onready var ground_glow: Sprite2D = $GroundGlow
@onready var core_container: Node2D = $CoreContainer
@onready var core_glow: Sprite2D = $CoreContainer/CoreGlow
@onready var core: Sprite2D = $CoreContainer/Core
@onready var main_flame: Sprite2D = $FlameLayer/MainFlame
@onready var side_flame: Sprite2D = $FlameLayer/SideFlame
@onready var spark_particles: GPUParticles2D = $SparkParticles

var animation_time := 0.0


func _ready() -> void:
	ground_glow.texture = _make_radial_texture(Color(1.0, 0.20, 0.035, 0.50), Vector2i(512, 224))
	core_glow.texture = _make_radial_texture(Color(1.0, 0.28, 0.04, 0.82), Vector2i(256, 256))
	ground_glow.scale = Vector2(1.32, 0.72)
	core_glow.scale = Vector2.ONE * 1.04
	core.scale = CORE_BASE_SCALE
	main_flame.scale = MAIN_FLAME_BASE_SCALE
	side_flame.scale = SIDE_FLAME_BASE_SCALE
	var core_shader := Shader.new()
	core_shader.code = CORE_MASK_SHADER
	var core_material := ShaderMaterial.new()
	core_material.shader = core_shader
	core_material.set_shader_parameter("mask_radius", 0.43)
	core.material = core_material
	_configure_sparks()


func _process(delta: float) -> void:
	animation_time += delta
	core_container.rotation += CORE_ROTATION_SPEED * delta
	var core_wave := 0.5 + 0.5 * sin(animation_time * TAU / CORE_PULSE_DURATION)
	var ground_wave := 0.5 + 0.5 * sin(animation_time * TAU / CORE_PULSE_DURATION + 0.36)
	core.scale = CORE_BASE_SCALE * (1.0 + core_wave * 0.05)
	core.self_modulate = Color(1.0 + core_wave * 0.25, 1.0 + core_wave * 0.16, 1.0 + core_wave * 0.08, 0.90 + core_wave * 0.10)
	core_glow.modulate.a = lerpf(0.30, 0.72, core_wave)
	ground_glow.modulate.a = lerpf(0.10, 0.20, ground_wave)
	var main_irregular := sin(animation_time * 5.1) * 0.62 + sin(animation_time * 8.7 + 0.8) * 0.38
	var side_irregular := sin(animation_time * 6.4 + 1.7) * 0.58 + sin(animation_time * 10.3 + 0.2) * 0.42
	main_flame.scale = Vector2(
		MAIN_FLAME_BASE_SCALE.x * (1.0 + main_irregular * 0.04),
		MAIN_FLAME_BASE_SCALE.y * (1.0 + main_irregular * 0.08)
	)
	side_flame.scale = Vector2(
		SIDE_FLAME_BASE_SCALE.x * (1.0 + side_irregular * 0.04),
		SIDE_FLAME_BASE_SCALE.y * (1.0 + side_irregular * 0.08)
	)
	main_flame.rotation = deg_to_rad(main_irregular * 1.4)
	side_flame.rotation = deg_to_rad(side_irregular * 2.0)
	main_flame.self_modulate = Color(1.08 + main_irregular * 0.08, 1.02 + main_irregular * 0.05, 1.0, 0.90 + main_irregular * 0.07)
	side_flame.self_modulate = Color(1.08 + side_irregular * 0.08, 1.02 + side_irregular * 0.05, 1.0, 0.86 + side_irregular * 0.08)


func _configure_sparks() -> void:
	spark_particles.amount = 10
	spark_particles.lifetime = 1.15
	spark_particles.randomness = 0.45
	spark_particles.texture = _make_radial_texture(Color(1.0, 0.42, 0.06, 0.95), Vector2i(16, 16))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(230.0, 26.0, 1.0)
	process.direction = Vector3(0.0, -1.0, 0.0)
	process.spread = 18.0
	process.initial_velocity_min = 24.0
	process.initial_velocity_max = 52.0
	process.gravity = Vector3(0.0, -10.0, 0.0)
	process.scale_min = 0.45
	process.scale_max = 1.0
	process.color = Color(1.0, 0.38, 0.05, 0.90)
	spark_particles.process_material = process
	spark_particles.emitting = true


func _make_radial_texture(color: Color, texture_size: Vector2i) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.56, 1.0])
	gradient.colors = PackedColorArray([color, Color(color.r, color.g, color.b, color.a * 0.28), Color(color.r, color.g, color.b, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = texture_size.x
	texture.height = texture_size.y
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture