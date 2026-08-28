extends Node2D

const CORE_ROTATION_SPEED := deg_to_rad(10.0)
const RING_ROTATION_SPEED := deg_to_rad(-21.0)
const CORE_PULSE_DURATION := 1.6
const CORE_BASE_SCALE := Vector2.ONE * 0.32
const RING_BASE_SCALE := Vector2.ONE * 0.38

@onready var contact_shadow: Sprite2D = $ContactShadow
@onready var platform_glow: Sprite2D = $PlatformGlow
@onready var core_pivot: Node2D = $CorePivot
@onready var core_glow: Sprite2D = $CorePivot/CoreGlow
@onready var core: Sprite2D = $CorePivot/Core
@onready var ring_pivot: Node2D = $RingPivot
@onready var ring: Sprite2D = $RingPivot/Ring

var animation_time := 0.0


func _ready() -> void:
	contact_shadow.texture = _make_radial_texture(Color(0.004, 0.008, 0.025, 0.28), Vector2i(512, 192))
	platform_glow.texture = _make_radial_texture(Color(0.12, 1.0, 0.72, 0.42), Vector2i(512, 224))
	core_glow.texture = _make_radial_texture(Color(0.18, 1.0, 0.82, 0.85), Vector2i(256, 256))
	contact_shadow.scale = Vector2(1.45, 0.72)
	platform_glow.scale = Vector2(1.30, 0.72)
	core_glow.scale = Vector2.ONE * 1.08
	core.scale = CORE_BASE_SCALE
	ring.scale = RING_BASE_SCALE


func _process(delta: float) -> void:
	animation_time += delta
	core_pivot.rotation += CORE_ROTATION_SPEED * delta
	ring_pivot.rotation += RING_ROTATION_SPEED * delta
	var core_wave := 0.5 + 0.5 * sin(animation_time * TAU / CORE_PULSE_DURATION)
	var light_wave := 0.5 + 0.5 * sin(animation_time * TAU / CORE_PULSE_DURATION + 0.28)
	core.scale = CORE_BASE_SCALE * (1.0 + core_wave * 0.04)
	core.self_modulate = Color(1.0 + core_wave * 0.10, 1.0 + core_wave * 0.10, 1.0 + core_wave * 0.10, 0.88 + core_wave * 0.12)
	core_glow.modulate.a = lerpf(0.25, 0.65, core_wave)
	ring.self_modulate = Color(1.0 + core_wave * 0.07, 1.0 + core_wave * 0.07, 1.0 + core_wave * 0.07, 0.92 + core_wave * 0.08)
	platform_glow.modulate.a = lerpf(0.10, 0.18, light_wave)


func _make_radial_texture(color: Color, texture_size: Vector2i) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.58, 1.0])
	gradient.colors = PackedColorArray([color, Color(color.r, color.g, color.b, color.a * 0.30), Color(color.r, color.g, color.b, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = texture_size.x
	texture.height = texture_size.y
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture