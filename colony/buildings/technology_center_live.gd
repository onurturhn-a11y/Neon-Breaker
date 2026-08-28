extends Node2D

const RESEARCH_CYCLE_DURATION := 5.2
const RESEARCH_PEAK_TIME := 2.8
const CORE_ROTATION_SPEED := deg_to_rad(11.0)
const CORE_PULSE_DURATION := 2.4
const CORE_BASE_POSITION := Vector2(0.0, 18.0)
const CORE_BASE_SCALE := Vector2.ONE * 0.31
const HOLOGRAM_ROTATION_SPEED := deg_to_rad(-24.0)
const HOLOGRAM_PULSE_DURATION := 2.0
const HOLOGRAM_BASE_POSITION := Vector2(2.0, -360.0)
const HOLOGRAM_BASE_SCALE := Vector2.ONE * 0.19
const CORE_SHADER_CODE := """
shader_type canvas_item;
uniform float orbit_phase = 0.0;
uniform float research_boost = 0.0;
void fragment() {
	vec2 p = (UV - vec2(0.5)) / vec2(0.36, 0.42);
	float chamber_mask = 1.0 - smoothstep(0.88, 1.0, length(p));
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float radius = length(p);
	float angle = atan(p.y, p.x);
	float orbit_a = 0.5 + 0.5 * sin(angle * 3.0 - orbit_phase * 6.28318 + radius * 13.0);
	float orbit_b = 0.5 + 0.5 * sin(angle * -2.0 + orbit_phase * 4.8 + radius * 18.0);
	vec3 tech_color = mix(vec3(0.15, 0.82, 1.0), vec3(0.82, 0.16, 1.0), orbit_a);
	c.rgb += tech_color * (orbit_a * 0.07 + orbit_b * 0.055 + research_boost * 0.16) * chamber_mask;
	c.a *= chamber_mask;
	COLOR = c;
}
"""
const HOLOGRAM_SHADER_CODE := """
shader_type canvas_item;
uniform float scan_phase = 0.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float scanline = 0.84 + 0.16 * sin(UV.y * 48.0 - scan_phase * 6.28318);
	float edge = 1.0 - smoothstep(0.43, 0.51, length((UV - vec2(0.5)) * vec2(1.0, 1.28)));
	c.rgb *= scanline;
	c.a *= edge;
	COLOR = c;
}
"""

@onready var ground_glow: Sprite2D = $GroundGlow
@onready var core_pivot: Node2D = $CoreClip/CorePivot
@onready var core: Sprite2D = $CoreClip/CorePivot/Core
@onready var body: Sprite2D = $Body
@onready var hologram_pivot: Node2D = $TopHologramPivot
@onready var hologram: Sprite2D = $TopHologramPivot/TopHologram
@onready var left_screen: Polygon2D = $ScreenEffects/LeftScreen
@onready var right_screen: Polygon2D = $ScreenEffects/RightScreen
@onready var energy_pulse: Line2D = $EnergyPulse
@onready var particles: GPUParticles2D = $DigitalParticles

var cycle_time := 0.0
var previous_time := 0.0
var research_boost := 0.0
var core_material: ShaderMaterial
var hologram_material: ShaderMaterial

func _ready() -> void:
	ground_glow.texture = _make_radial_texture(Color(0.50, 0.12, 1.0, 0.42), Vector2i(512, 224))
	ground_glow.scale = Vector2(1.22, 0.68)
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
	_configure_screens()
	_configure_particles()

func _process(delta: float) -> void:
	previous_time = cycle_time
	cycle_time = fmod(cycle_time + delta, RESEARCH_CYCLE_DURATION)
	if cycle_time < previous_time:
		previous_time = 0.0
	if previous_time < RESEARCH_PEAK_TIME and cycle_time >= RESEARCH_PEAK_TIME:
		_trigger_research_peak()
	research_boost = move_toward(research_boost, 0.0, delta * 2.9)
	_update_core(delta)
	_update_hologram(delta)
	_update_screen_activity()
	_update_energy_pulse()
	_update_ground_glow()

func _update_core(delta: float) -> void:
	core_pivot.rotation += CORE_ROTATION_SPEED * delta
	var phase := cycle_time / CORE_PULSE_DURATION
	var wave := 0.5 + 0.5 * sin(phase * TAU)
	core_pivot.position = CORE_BASE_POSITION + Vector2(0.0, lerpf(-2.0, 2.0, wave))
	core.scale = CORE_BASE_SCALE * lerpf(0.985, 1.025, wave)
	var gain := lerpf(0.95, 1.15, wave) + research_boost * 0.18
	core.self_modulate = Color(gain, gain, 1.0 + research_boost * 0.08, 0.94 + wave * 0.06)
	core_material.set_shader_parameter("orbit_phase", fmod(phase, 1.0))
	core_material.set_shader_parameter("research_boost", research_boost)

func _update_hologram(delta: float) -> void:
	hologram_pivot.rotation += HOLOGRAM_ROTATION_SPEED * delta
	var phase := cycle_time / HOLOGRAM_PULSE_DURATION
	var wave := 0.5 + 0.5 * sin(phase * TAU + 0.9)
	hologram_pivot.position = HOLOGRAM_BASE_POSITION + Vector2(0.0, lerpf(-3.0, 3.0, wave))
	hologram.scale = HOLOGRAM_BASE_SCALE * lerpf(0.97, 1.04, wave)
	var alpha := lerpf(0.65, 0.90, wave) + research_boost * 0.07
	hologram.self_modulate = Color(0.92 + research_boost * 0.10, 0.72 + research_boost * 0.08, 1.08, minf(alpha, 0.98))
	hologram_material.set_shader_parameter("scan_phase", fmod(phase, 1.0))

func _update_screen_activity() -> void:
	var ambient := 0.5 + 0.5 * sin(cycle_time * TAU / 3.1)
	var data_flash := research_boost * research_boost
	left_screen.modulate.a = 0.08 + ambient * 0.07 + data_flash * 0.34
	right_screen.modulate.a = 0.07 + (1.0 - ambient) * 0.08 + data_flash * 0.30

func _update_energy_pulse() -> void:
	energy_pulse.modulate.a = research_boost * 0.78
	energy_pulse.width = lerpf(2.0, 6.0, research_boost)

func _update_ground_glow() -> void:
	var ambient := 0.09 + (0.5 + 0.5 * sin(cycle_time * TAU / CORE_PULSE_DURATION + 0.35)) * 0.07
	ground_glow.modulate.a = ambient + research_boost * 0.022

func _trigger_research_peak() -> void:
	research_boost = 1.0
	particles.restart()

func _configure_screens() -> void:
	left_screen.polygon = PackedVector2Array([Vector2(-402,-54),Vector2(-258,-86),Vector2(-246,16),Vector2(-390,40)])
	right_screen.polygon = PackedVector2Array([Vector2(258,-86),Vector2(402,-54),Vector2(390,40),Vector2(246,16)])
	left_screen.color = Color(0.12, 0.86, 1.0, 1.0)
	right_screen.color = Color(0.78, 0.16, 1.0, 1.0)

func _configure_particles() -> void:
	particles.amount = 8
	particles.lifetime = 0.64
	particles.one_shot = true
	particles.explosiveness = 0.76
	particles.texture = _make_radial_texture(Color(0.60, 0.28, 1.0, 0.96), Vector2i(10, 10))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 104.0
	process.direction = Vector3(0.0, -1.0, 0.0)
	process.spread = 48.0
	process.initial_velocity_min = 16.0
	process.initial_velocity_max = 38.0
	process.gravity = Vector3(0.0, -4.0, 0.0)
	process.scale_min = 0.28
	process.scale_max = 0.62
	process.color = Color(0.54, 0.34, 1.0, 0.90)
	particles.process_material = process

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
