extends Node2D

const CORE_ROTATION_SPEED := deg_to_rad(28.0)
const RING_ROTATION_SPEED := deg_to_rad(-66.0)
const VISUAL_SPIN_FACTOR := 0.75
const VISUAL_SPIN_MIN_SPEED := 220.0
const VISUAL_SPIN_MAX_SPEED := 500.0
const CORE_PULSE_DURATION := 0.95
const BODY_SCALE := Vector2.ONE * (40.0 / 1295.0)
const CORE_SCALE := Vector2.ONE * (34.0 / 1280.0)
const RING_SCALE := Vector2.ONE * (37.0 / 1278.0)
const CORE_MASK_SHADER := """
shader_type canvas_item;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 p = (UV - vec2(0.5)) / vec2(0.39, 0.39);
	float mask = 1.0 - smoothstep(0.90, 1.0, length(p));
	vec4 c = texture(TEXTURE, UV) * COLOR;
	c.rgb += vec3(1.0, 0.27, 0.02) * intensity * 0.22 * mask;
	c.a *= mask;
	COLOR = c;
}
"""

@onready var ball: Node = get_parent().get_parent()
@onready var glow: Sprite2D = $Glow
@onready var core_pivot: Node2D = $CorePivot
@onready var core: Sprite2D = $CorePivot/Core
@onready var ring_pivot: Node2D = $RingPivot
@onready var ring: Sprite2D = $RingPivot/Ring
@onready var body: Sprite2D = $Body
@onready var trail: Line2D = $FireTrail
@onready var embers: GPUParticles2D = $Embers
@onready var impact_particles: GPUParticles2D = $ImpactParticles

var animation_time := 0.0
var combo_rank := -1
var visual_intensity := 0.0
var target_intensity := 0.0
var hit_boost := 0.0
var core_material: ShaderMaterial
var ember_material: ParticleProcessMaterial
var impact_material: ParticleProcessMaterial

func _ready() -> void:
	body.scale = BODY_SCALE
	core.scale = CORE_SCALE
	ring.scale = RING_SCALE
	glow.texture = _make_radial_texture(Color(1.0, 0.20, 0.025, 0.66), Vector2i(128, 128))
	glow.scale = Vector2.ONE * 0.46
	core_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = CORE_MASK_SHADER
	core_material.shader = shader
	core.material = core_material
	_configure_trail()
	_configure_embers()
	_configure_impacts()

func _process(delta: float) -> void:
	animation_time += delta
	_update_visual_spin(delta)
	visual_intensity = move_toward(visual_intensity, target_intensity, delta * 3.8)
	hit_boost = move_toward(hit_boost, 0.0, delta * 8.5)
	core_pivot.rotation += CORE_ROTATION_SPEED * delta
	ring_pivot.rotation += RING_ROTATION_SPEED * delta
	var pulse := 0.5 + 0.5 * sin(animation_time * TAU / CORE_PULSE_DURATION)
	core.scale = CORE_SCALE * (1.0 + pulse * 0.06)
	var energy := clampf(visual_intensity + hit_boost, 0.0, 1.35)
	var core_gain := 1.0 + pulse * 0.10 + energy * 0.25
	core.self_modulate = Color(core_gain, 1.0 + pulse * 0.05 + energy * 0.10, 1.0, 1.0)
	ring.self_modulate = Color(1.0 + energy * 0.20, 1.0 + energy * 0.08, 1.0, 0.88 + energy * 0.12)
	glow.modulate.a = lerpf(0.26, 0.58, visual_intensity) + hit_boost * 0.16
	glow.scale = Vector2.ONE * lerpf(0.44, 0.54, visual_intensity)
	core_material.set_shader_parameter("intensity", energy)
	_update_trail()
	_update_embers()

func set_combo_rank(rank_index: int) -> void:
	combo_rank = rank_index
	if rank_index < 0:
		target_intensity = 0.0
	elif rank_index <= 2:
		target_intensity = 0.28
	elif rank_index <= 5:
		target_intensity = 0.62
	else:
		target_intensity = 1.0

func play_collision_feedback(_hit_type: String, _contact_position: Vector2, surface_normal: Vector2) -> void:
	hit_boost = 0.34
	var local_normal := surface_normal.rotated(-global_rotation)
	impact_material.direction = Vector3(local_normal.x, local_normal.y, 0.0)
	impact_particles.restart()

func _update_visual_spin(delta: float) -> void:
	if not is_instance_valid(ball) or not ball.ball_launched:
		return
	var movement_speed: float = ball.velocity.length()
	if movement_speed <= 0.01:
		return
	var spin_speed := clampf(
		movement_speed * VISUAL_SPIN_FACTOR,
		VISUAL_SPIN_MIN_SPEED,
		VISUAL_SPIN_MAX_SPEED
	)
	rotation += deg_to_rad(spin_speed) * delta
func _update_trail() -> void:
	if not is_instance_valid(ball) or ball.direction.length_squared() <= 0.0:
		trail.visible = false
		return
	trail.visible = true
	var backwards: Vector2 = (-ball.direction.normalized()).rotated(-global_rotation)
	var trail_length := lerpf(18.0, 27.0, visual_intensity)
	var side := backwards.orthogonal()
	trail.points = PackedVector2Array([
		backwards * 6.0,
		backwards * trail_length * 0.52 + side * sin(animation_time * 11.0) * 1.3,
		backwards * trail_length,
	])
	trail.width = lerpf(5.0, 7.0, visual_intensity)
	trail.modulate.a = lerpf(0.58, 0.86, visual_intensity)

func _update_embers() -> void:
	if not is_instance_valid(ball) or ball.direction.length_squared() <= 0.0:
		embers.emitting = false
		return
	embers.emitting = true
	var backwards: Vector2 = (-ball.direction.normalized()).rotated(-global_rotation)
	ember_material.direction = Vector3(backwards.x, backwards.y, 0.0)
	embers.amount_ratio = lerpf(0.52, 1.0, visual_intensity)

func set_active(active: bool) -> void:
	visible = active
	set_process(active)
	embers.emitting = active
	if not active:
		impact_particles.emitting = false

func _configure_trail() -> void:
	var trail_gradient := Gradient.new()
	trail_gradient.offsets = PackedFloat32Array([0.0, 0.34, 0.72, 1.0])
	trail_gradient.colors = PackedColorArray([
		Color(1.0, 0.94, 0.68, 0.96),
		Color(1.0, 0.48, 0.04, 0.90),
		Color(0.96, 0.10, 0.015, 0.52),
		Color(0.72, 0.025, 0.01, 0.0),
	])
	trail.gradient = trail_gradient
func _configure_embers() -> void:
	embers.amount = 12
	embers.lifetime = 0.30
	embers.randomness = 0.45
	embers.texture = _make_radial_texture(Color(1.0, 0.34, 0.025, 0.95), Vector2i(10, 10))
	ember_material = ParticleProcessMaterial.new()
	ember_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	ember_material.emission_sphere_radius = 5.0
	ember_material.spread = 18.0
	ember_material.initial_velocity_min = 32.0
	ember_material.initial_velocity_max = 58.0
	ember_material.gravity = Vector3.ZERO
	ember_material.scale_min = 0.22
	ember_material.scale_max = 0.58
	ember_material.color = Color(1.0, 0.30, 0.025, 0.88)
	embers.process_material = ember_material

func _configure_impacts() -> void:
	impact_particles.amount = 4
	impact_particles.lifetime = 0.11
	impact_particles.one_shot = true
	impact_particles.explosiveness = 1.0
	impact_particles.texture = _make_radial_texture(Color(1.0, 0.68, 0.08, 0.98), Vector2i(10, 10))
	impact_material = ParticleProcessMaterial.new()
	impact_material.spread = 48.0
	impact_material.initial_velocity_min = 38.0
	impact_material.initial_velocity_max = 72.0
	impact_material.gravity = Vector3.ZERO
	impact_material.scale_min = 0.28
	impact_material.scale_max = 0.70
	impact_material.color = Color(1.0, 0.58, 0.06, 0.95)
	impact_particles.process_material = impact_material

func _make_radial_texture(color: Color, texture_size: Vector2i) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.46, 1.0])
	gradient.colors = PackedColorArray([Color(1.0, 0.94, 0.68, color.a), color, Color(color.r, color.g, color.b, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = texture_size.x
	texture.height = texture_size.y
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture




