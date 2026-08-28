extends Node2D

const CYCLE_DURATION := 4.4
const CONTACT_TIME := 2.0
const CORE_BASE_SCALE := Vector2.ONE * 0.31
const MACHINE_BASE_SCALE := Vector2.ONE * 0.34
const MACHINE_HOME := Vector2(-330.0, 72.0)
const MACHINE_WORK := Vector2(-292.0, 112.0)
const BOX_START := Vector2(-480.0, 224.0)
const BOX_WORK := Vector2(-300.0, 150.0)
const BOX_EXIT := Vector2(-92.0, 82.0)
const CORE_SHADER_CODE := """
shader_type canvas_item;
uniform float flow_phase = 0.0;
uniform float boost = 0.0;
void fragment() {
	vec2 p = (UV - vec2(0.5)) / vec2(0.34, 0.43);
	float chamber_mask = 1.0 - smoothstep(0.88, 1.0, length(p));
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float bands = 0.5 + 0.5 * sin(UV.y * 34.0 - flow_phase * 6.28318);
	c.rgb += vec3(0.08, 0.82, 1.0) * (bands * 0.10 + boost * 0.22) * chamber_mask;
	c.a *= chamber_mask;
	COLOR = c;
}
"""

@onready var ground_glow: Sprite2D = $GroundGlow
@onready var core: Sprite2D = $CoreClip/Core
@onready var body: Sprite2D = $Body
@onready var robot_arm: Sprite2D = $RobotArmPivot/RobotArm
@onready var robot_pivot: Node2D = $RobotArmPivot
@onready var box_one: Polygon2D = $ConveyorVisuals/ConveyorBox1
@onready var box_two: Polygon2D = $ConveyorVisuals/ConveyorBox2
@onready var production_flash: Sprite2D = $ProductionFlash
@onready var sparks: GPUParticles2D = $Sparks

var cycle_time := 0.0
var previous_phase := 0.0
var production_boost := 0.0
var core_material: ShaderMaterial

func _ready() -> void:
	ground_glow.texture = _make_radial_texture(Color(0.04, 0.72, 1.0, 0.42), Vector2i(512, 224))
	production_flash.texture = _make_radial_texture(Color(0.55, 0.96, 1.0, 0.96), Vector2i(128, 128))
	ground_glow.scale = Vector2(1.24, 0.68)
	production_flash.scale = Vector2.ONE * 0.62
	production_flash.modulate.a = 0.0
	core.scale = CORE_BASE_SCALE
	robot_arm.scale = MACHINE_BASE_SCALE
	robot_pivot.position = MACHINE_HOME
	core_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = CORE_SHADER_CODE
	core_material.shader = shader
	core.material = core_material
	_configure_sparks()
	_configure_boxes()

func _process(delta: float) -> void:
	previous_phase = cycle_time
	cycle_time = fmod(cycle_time + delta, CYCLE_DURATION)
	if cycle_time < previous_phase:
		previous_phase = 0.0
	if previous_phase < CONTACT_TIME and cycle_time >= CONTACT_TIME:
		_trigger_production_contact()
	production_boost = move_toward(production_boost, 0.0, delta * 5.8)
	_update_core()
	_update_conveyor()
	_update_robot_arm()
	_update_flash_and_light()

func _update_core() -> void:
	var ambient_wave := 0.5 + 0.5 * sin(cycle_time * TAU / 2.15)
	core.position = Vector2(72.0, -20.0 + lerpf(-3.0, 3.0, ambient_wave))
	core.scale = CORE_BASE_SCALE * lerpf(0.98, 1.02, ambient_wave)
	var gain := 0.90 + ambient_wave * 0.20 + production_boost * 0.24
	core.self_modulate = Color(gain, gain, gain, 0.94 + ambient_wave * 0.06)
	core_material.set_shader_parameter("flow_phase", fmod(cycle_time / 2.15, 1.0))
	core_material.set_shader_parameter("boost", production_boost)

func _update_conveyor() -> void:
	if cycle_time < 1.55:
		box_one.visible = true
		box_one.position = BOX_START.lerp(BOX_WORK, _smooth_ratio(cycle_time / 1.55))
	elif cycle_time < 2.45:
		box_one.visible = true
		box_one.position = BOX_WORK
	elif cycle_time < 3.62:
		box_one.visible = true
		box_one.position = BOX_WORK.lerp(BOX_EXIT, _smooth_ratio((cycle_time - 2.45) / 1.17))
	else:
		box_one.visible = false
	var second_time := fmod(cycle_time + 2.35, CYCLE_DURATION)
	box_two.visible = second_time < 1.25
	if box_two.visible:
		box_two.position = BOX_START.lerp(BOX_WORK, _smooth_ratio(second_time / 1.25))

func _update_robot_arm() -> void:
	var approach := 0.0
	if cycle_time >= 1.50 and cycle_time < 2.0:
		approach = _smooth_ratio((cycle_time - 1.50) / 0.50)
	elif cycle_time >= 2.0 and cycle_time < 2.22:
		approach = 1.0
	elif cycle_time >= 2.22 and cycle_time < 2.80:
		approach = 1.0 - _smooth_ratio((cycle_time - 2.22) / 0.58)
	robot_pivot.position = MACHINE_HOME.lerp(MACHINE_WORK, approach)
	robot_pivot.rotation = deg_to_rad(lerpf(-2.0, 3.0, approach))
	robot_arm.scale = MACHINE_BASE_SCALE * lerpf(1.0, 1.012, approach)

func _update_flash_and_light() -> void:
	var flash_alpha := clampf(production_boost * 1.45, 0.0, 1.0)
	production_flash.modulate.a = flash_alpha
	production_flash.scale = Vector2.ONE * lerpf(0.52, 0.72, flash_alpha)
	var ambient_light := 0.10 + (0.5 + 0.5 * sin(cycle_time * TAU / 2.15 + 0.35)) * 0.06
	ground_glow.modulate.a = ambient_light + production_boost * 0.035

func _trigger_production_contact() -> void:
	production_boost = 1.0
	sparks.restart()

func _configure_boxes() -> void:
	var shape := PackedVector2Array([
		Vector2(-22.0, -12.0), Vector2(15.0, -16.0),
		Vector2(22.0, 8.0), Vector2(-14.0, 14.0),
	])
	box_one.polygon = shape
	box_two.polygon = shape
	box_one.color = Color(0.12, 0.88, 1.0, 0.88)
	box_two.color = Color(0.08, 0.66, 0.94, 0.66)
	box_one.scale = Vector2.ONE
	box_two.scale = Vector2.ONE * 0.82

func _configure_sparks() -> void:
	sparks.amount = 5
	sparks.lifetime = 0.16
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.texture = _make_radial_texture(Color(0.45, 0.96, 1.0, 0.98), Vector2i(10, 10))
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, -1.0, 0.0)
	process.spread = 62.0
	process.initial_velocity_min = 44.0
	process.initial_velocity_max = 82.0
	process.gravity = Vector3(0.0, 34.0, 0.0)
	process.scale_min = 0.35
	process.scale_max = 0.72
	process.color = Color(0.42, 0.94, 1.0, 0.96)
	sparks.process_material = process

func _smooth_ratio(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _make_radial_texture(color: Color, texture_size: Vector2i) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.54, 1.0])
	gradient.colors = PackedColorArray([color, Color(color.r, color.g, color.b, color.a * 0.26), Color(color.r, color.g, color.b, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = texture_size.x
	texture.height = texture_size.y
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture
