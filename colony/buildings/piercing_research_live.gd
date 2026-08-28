extends Node2D

const CORE_OSCILLATION_SPEED := 58.0
const CORE_PULSE_DURATION := 1.15
const CORE_BASE_SCALE := Vector2.ONE * 0.31
const HOLOGRAM_BASE_SCALE := Vector2.ONE * 0.19
const HOLOGRAM_PULSE_DURATION := 2.1
const CORE_SHADER_CODE := """
shader_type canvas_item;
uniform float flow_phase = 0.0;
uniform vec2 mask_scale = vec2(0.30, 0.42);
void fragment() {
	vec2 centered = (UV - vec2(0.5)) / mask_scale;
	float chamber_mask = 1.0 - smoothstep(0.86, 1.0, length(centered));
	vec4 tex_color = texture(TEXTURE, UV) * COLOR;
	float ring_a = 0.5 + 0.5 * sin((length(centered) * 20.0) - flow_phase * 6.28318);
	float ring_b = 0.5 + 0.5 * sin((length(centered) * 14.0) + flow_phase * 5.15);
	float energy = ring_a * 0.13 + ring_b * 0.08;
	tex_color.rgb += vec3(1.0, 0.66, 0.08) * energy * chamber_mask;
	tex_color.a *= chamber_mask;
	COLOR = tex_color;
}
"""
const HOLOGRAM_SHADER_CODE := """
shader_type canvas_item;
uniform float scan_phase = 0.0;
void fragment() {
	vec4 tex_color = texture(TEXTURE, UV) * COLOR;
	float scan = 0.80 + 0.20 * sin((UV.y * 42.0 - scan_phase * 6.28318));
	float soft_mask = 1.0 - smoothstep(0.43, 0.51, length((UV - vec2(0.5)) * vec2(1.0, 1.35)));
	tex_color.rgb *= scan;
	tex_color.a *= soft_mask;
	COLOR = tex_color;
}
"""

@onready var ground_glow: Sprite2D = $GroundGlow
@onready var core_pivot: Node2D = $CoreClip/CorePivot
@onready var core_glow: Sprite2D = $CoreClip/CorePivot/CoreGlow
@onready var core: Sprite2D = $CoreClip/CorePivot/Core
@onready var energy_beam: Line2D = $EnergyBeam
@onready var hologram: Sprite2D = $HologramPivot/Hologram
@onready var particles: GPUParticles2D = $EnergyParticles

var animation_time := 0.0
var core_material: ShaderMaterial
var hologram_material: ShaderMaterial

func _ready() -> void:
	ground_glow.texture = _make_radial_texture(Color(1.0, 0.66, 0.06, 0.46), Vector2i(512, 224))
	core_glow.texture = _make_radial_texture(Color(1.0, 0.72, 0.10, 0.86), Vector2i(256, 256))
	ground_glow.scale = Vector2(1.22, 0.66)
	core_glow.scale = Vector2.ONE * 0.92
	core.scale = CORE_BASE_SCALE
	hologram.scale = HOLOGRAM_BASE_SCALE
	core_material = ShaderMaterial.new()
	var core_shader := Shader.new()
	core_shader.code = CORE_SHADER_CODE
	core_material.shader = core_shader
	core.material = core_material
	hologram_material = ShaderMaterial.new()
	var hologram_shader := Shader.new()
	hologram_shader.code = HOLOGRAM_SHADER_CODE
	hologram_material.shader = hologram_shader
	hologram.material = hologram_material
	_configure_particles()

func _process(delta: float) -> void:
	animation_time += delta
	var core_phase := animation_time / CORE_PULSE_DURATION
	var core_wave := 0.5 + 0.5 * sin(core_phase * TAU)
	core_pivot.rotation = deg_to_rad(sin(animation_time * deg_to_rad(CORE_OSCILLATION_SPEED) * 3.8) * 3.2)
	core.self_modulate = Color(1.0 + core_wave * 0.20, 1.0 + core_wave * 0.14, 1.0 + core_wave * 0.03, 0.92 + core_wave * 0.08)
	core_glow.modulate.a = lerpf(0.28, 0.68, core_wave)
	core_material.set_shader_parameter("flow_phase", fmod(core_phase, 1.0))
	var light_wave := 0.5 + 0.5 * sin(core_phase * TAU + 0.30)
	ground_glow.modulate.a = lerpf(0.11, 0.20, light_wave)
	energy_beam.modulate.a = lerpf(0.52, 0.88, core_wave)
	var hologram_phase := animation_time / HOLOGRAM_PULSE_DURATION
	var hologram_wave := 0.5 + 0.5 * sin(hologram_phase * TAU + 1.1)
	hologram.scale = HOLOGRAM_BASE_SCALE * lerpf(0.96, 1.02, hologram_wave)
	hologram.self_modulate = Color(1.08, 0.90, 0.34, lerpf(0.50, 0.68, hologram_wave))
	hologram_material.set_shader_parameter("scan_phase", fmod(hologram_phase, 1.0))

func _configure_particles() -> void:
	particles.amount = 8
	particles.lifetime = 1.0
	particles.randomness = 0.50
	particles.texture = _make_radial_texture(Color(1.0, 0.72, 0.12, 0.94), Vector2i(12, 12))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 42.0
	process.direction = Vector3(0.0, -1.0, 0.0)
	process.spread = 42.0
	process.initial_velocity_min = 16.0
	process.initial_velocity_max = 38.0
	process.gravity = Vector3(0.0, -6.0, 0.0)
	process.scale_min = 0.35
	process.scale_max = 0.85
	process.color = Color(1.0, 0.68, 0.08, 0.90)
	particles.process_material = process
	particles.emitting = true

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
