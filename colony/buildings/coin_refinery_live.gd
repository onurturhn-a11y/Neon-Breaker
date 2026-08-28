extends Node2D

const CYCLE_DURATION := 4.2
const PEAK_TIME := 2.25
const CORE_BASE_POSITION := Vector2(36.0, -22.0)
const CORE_BASE_SCALE := Vector2.ONE * 0.31
const HOLOGRAM_BASE_POSITION := Vector2(246.0, -326.0)
const HOLOGRAM_BASE_SCALE := Vector2.ONE * 0.20
const HOLOGRAM_ROTATION_SPEED := deg_to_rad(20.0)
const COIN_PATH_START := Vector2(-188.0, 150.0)
const COIN_PATH_MIDDLE := Vector2(4.0, 232.0)
const COIN_PATH_END := Vector2(202.0, 302.0)
const CORE_SHADER_CODE := """
shader_type canvas_item;
uniform float energy_phase = 0.0;
uniform float peak_boost = 0.0;
void fragment() {
	vec2 p = (UV - vec2(0.5)) / vec2(0.35, 0.42);
	float chamber_mask = 1.0 - smoothstep(0.88, 1.0, length(p));
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float flow_a = 0.5 + 0.5 * sin(length(p) * 18.0 - energy_phase * 6.28318);
	float flow_b = 0.5 + 0.5 * sin((UV.y + UV.x * 0.35) * 24.0 + energy_phase * 4.7);
	c.rgb += vec3(1.0, 0.64, 0.05) * (flow_a * 0.09 + flow_b * 0.05 + peak_boost * 0.18) * chamber_mask;
	c.a *= chamber_mask;
	COLOR = c;
}
"""

@onready var ground_glow: Sprite2D = $GroundGlow
@onready var core_pivot: Node2D = $CoreClip/CorePivot
@onready var core: Sprite2D = $CoreClip/CorePivot/Core
@onready var body: Sprite2D = $Body
@onready var hologram_pivot: Node2D = $HologramPivot
@onready var hologram: Sprite2D = $HologramPivot/Hologram
@onready var coin_nodes := [$ConveyorCoins/Coin1, $ConveyorCoins/Coin2, $ConveyorCoins/Coin3]
@onready var sparkles: GPUParticles2D = $Sparkles

var cycle_time := 0.0
var previous_time := 0.0
var peak_boost := 0.0
var core_material: ShaderMaterial

func _ready() -> void:
	ground_glow.texture = _make_radial_texture(Color(1.0, 0.66, 0.04, 0.44), Vector2i(512, 224))
	ground_glow.scale = Vector2(1.20, 0.66)
	core.scale = CORE_BASE_SCALE
	hologram.scale = HOLOGRAM_BASE_SCALE
	core_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = CORE_SHADER_CODE
	core_material.shader = shader
	core.material = core_material
	_configure_coins()
	_configure_sparkles()

func _process(delta: float) -> void:
	previous_time = cycle_time
	cycle_time = fmod(cycle_time + delta, CYCLE_DURATION)
	if cycle_time < previous_time:
		previous_time = 0.0
	if previous_time < PEAK_TIME and cycle_time >= PEAK_TIME:
		_trigger_refinery_peak()
	peak_boost = move_toward(peak_boost, 0.0, delta * 3.8)
	_update_core()
	_update_hologram(delta)
	_update_conveyor_coins()
	_update_ground_glow()

func _update_core() -> void:
	var phase := cycle_time / 2.1
	var wave := 0.5 + 0.5 * sin(phase * TAU)
	core_pivot.position = CORE_BASE_POSITION + Vector2(0.0, lerpf(-2.0, 2.0, wave))
	core.scale = CORE_BASE_SCALE * lerpf(0.99, 1.02, wave)
	var gain := 1.0 + wave * 0.18 + peak_boost * 0.18
	core.self_modulate = Color(gain, 1.0 + wave * 0.11 + peak_boost * 0.10, 1.0, 0.94 + wave * 0.06)
	core_material.set_shader_parameter("energy_phase", fmod(phase, 1.0))
	core_material.set_shader_parameter("peak_boost", peak_boost)

func _update_hologram(delta: float) -> void:
	hologram_pivot.rotation += HOLOGRAM_ROTATION_SPEED * delta
	var holo_wave := 0.5 + 0.5 * sin(cycle_time * TAU / 2.0 + 0.75)
	hologram_pivot.position = HOLOGRAM_BASE_POSITION + Vector2(0.0, lerpf(-2.0, 2.0, holo_wave))
	hologram.scale = HOLOGRAM_BASE_SCALE * lerpf(0.985, 1.015, holo_wave)
	var alpha := lerpf(0.60, 0.85, holo_wave) + peak_boost * 0.08
	hologram.self_modulate = Color(1.08 + peak_boost * 0.10, 0.92 + peak_boost * 0.06, 0.34, minf(alpha, 0.94))

func _update_conveyor_coins() -> void:
	for index in range(coin_nodes.size()):
		var coin := coin_nodes[index] as Polygon2D
		var progress := fmod(cycle_time / CYCLE_DURATION + float(index) / 3.0, 1.0)
		coin.position = _coin_path_position(progress)
		coin.rotation = progress * TAU * 1.35 + float(index) * 0.7
		var edge_fade := minf(clampf(progress / 0.12, 0.0, 1.0), clampf((1.0 - progress) / 0.14, 0.0, 1.0))
		coin.modulate.a = edge_fade * lerpf(0.72, 1.0, peak_boost)
		coin.scale = Vector2.ONE * lerpf(0.74, 1.08, progress)

func _coin_path_position(progress: float) -> Vector2:
	if progress < 0.52:
		return COIN_PATH_START.lerp(COIN_PATH_MIDDLE, _smooth_ratio(progress / 0.52))
	return COIN_PATH_MIDDLE.lerp(COIN_PATH_END, _smooth_ratio((progress - 0.52) / 0.48))

func _update_ground_glow() -> void:
	var ambient := 0.10 + (0.5 + 0.5 * sin(cycle_time * TAU / 2.1 + 0.25)) * 0.07
	ground_glow.modulate.a = ambient + peak_boost * 0.025

func _trigger_refinery_peak() -> void:
	peak_boost = 1.0
	sparkles.restart()

func _configure_coins() -> void:
	var coin_shape := PackedVector2Array()
	for point_index in range(12):
		coin_shape.append(Vector2.from_angle(float(point_index) / 12.0 * TAU) * Vector2(14.0, 9.0))
	for index in range(coin_nodes.size()):
		var coin := coin_nodes[index] as Polygon2D
		coin.polygon = coin_shape
		coin.color = Color(1.0, 0.70 + float(index) * 0.04, 0.10, 0.94)

func _configure_sparkles() -> void:
	sparkles.amount = 6
	sparkles.lifetime = 0.42
	sparkles.one_shot = true
	sparkles.explosiveness = 0.82
	sparkles.texture = _make_radial_texture(Color(1.0, 0.82, 0.18, 0.98), Vector2i(10, 10))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 86.0
	process.direction = Vector3(0.0, -1.0, 0.0)
	process.spread = 55.0
	process.initial_velocity_min = 18.0
	process.initial_velocity_max = 42.0
	process.gravity = Vector3(0.0, -5.0, 0.0)
	process.scale_min = 0.30
	process.scale_max = 0.68
	process.color = Color(1.0, 0.72, 0.08, 0.92)
	sparkles.process_material = process

func _smooth_ratio(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

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
