extends Control
const DESIGN_SIZE := Vector2(1672.0, 941.0)
const CYCLE_DURATION := 6.4
const PULSE_TRAVEL_DURATION := 1.35
const PATH_STAGGERS := [0.0, 0.08, 0.16, 0.24, 0.32, 0.40]
const SLOT_IDS: Array[StringName] = [&"top_left", &"top_right", &"middle_left", &"middle_right", &"bottom_left", &"bottom_right"]
@onready var background: TextureRect = $Background
@onready var crystal_layer: TextureRect = $CrystalLayer
@onready var energy_network: Node2D = $EnergyNetwork
@onready var platform_glow_layer: Node2D = $PlatformGlowLayer
@onready var center_core: Node2D = $CenterCore
@onready var core_sprite: Sprite2D = $CenterCore/CoreSprite
@onready var ambient_particles: GPUParticles2D = $AmbientParticles
@onready var planet_glow: Sprite2D = $PlanetGlow
var _paths: Array[Path2D] = []
var _path_lines: Array[Line2D] = []
var _pulse_follows: Array[PathFollow2D] = []
var _platform_glows: Array[Sprite2D] = []
var _cycle_time := 0.0
var _layout_rect := Rect2(Vector2.ZERO, DESIGN_SIZE)
var _radial_texture: GradientTexture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radial_texture = _make_radial_texture()
	planet_glow.texture = _radial_texture
	ambient_particles.texture = _radial_texture
	_create_energy_network()
	_create_platform_glows()
	configure_layout(Rect2(Vector2.ZERO, size), {})

func _process(delta: float) -> void:
	_cycle_time = fmod(_cycle_time + delta, CYCLE_DURATION)
	var core_wave := 0.5 + 0.5 * sin(_cycle_time * TAU / 2.35)
	planet_glow.modulate.a = lerpf(0.035, 0.085, 0.5 + 0.5 * sin(_cycle_time * TAU / 5.8 + 1.1))
	for index in _pulse_follows.size():
		var local_time := _cycle_time - 0.72 - float(PATH_STAGGERS[index])
		if local_time < 0.0: local_time += CYCLE_DURATION
		var active := local_time <= PULSE_TRAVEL_DURATION
		var follow := _pulse_follows[index]
		follow.visible = active
		var arrival := 0.0
		if active:
			var t := clampf(local_time / PULSE_TRAVEL_DURATION, 0.0, 1.0)
			follow.progress_ratio = smoothstep(0.0, 1.0, t)
			arrival = smoothstep(0.78, 1.0, t)
		var idle_wave := 0.5 + 0.5 * sin(_cycle_time * TAU / 2.8 + float(index) * 0.71)
		_platform_glows[index].modulate.a = 0.035 + idle_wave * 0.025 + arrival * 0.20

func configure_layout(display_rect: Rect2, slot_positions: Dictionary) -> void:
	if not is_node_ready(): return
	_layout_rect = display_rect
	var scale_value := display_rect.size.x / DESIGN_SIZE.x
	center_core.position = display_rect.position + display_rect.size * Vector2(0.5, 0.505)
	center_core.scale = Vector2.ONE * scale_value * 0.16
	planet_glow.position = display_rect.position + display_rect.size * Vector2(0.655, 0.095)
	planet_glow.scale = Vector2(display_rect.size.x * 0.00022, display_rect.size.x * 0.00013)
	ambient_particles.position = display_rect.position + display_rect.size * 0.5
	var ambient_material := ambient_particles.process_material as ParticleProcessMaterial
	if ambient_material != null:
		ambient_material.emission_box_extents = Vector3(display_rect.size.x * 0.47, display_rect.size.y * 0.43, 0.0)
	for index in SLOT_IDS.size():
		var slot_id := SLOT_IDS[index]
		var normalized: Vector2 = slot_positions.get(slot_id, _fallback_slot_position(slot_id))
		var target := display_rect.position + display_rect.size * normalized
		_configure_path(index, center_core.position, target, slot_id)
		_platform_glows[index].position = target
		_platform_glows[index].scale = Vector2(display_rect.size.x * 0.00017, display_rect.size.x * 0.000085)

func set_background_stretch_mode(mode: int) -> void:
	background.stretch_mode = mode
	crystal_layer.stretch_mode = mode

func _create_energy_network() -> void:
	for index in SLOT_IDS.size():
		var path := Path2D.new()
		path.name = "EnergyPath_%s" % String(SLOT_IDS[index])
		energy_network.add_child(path)
		var line := Line2D.new()
		line.name = "PathGlow"
		line.width = 2.2
		line.default_color = Color(0.42, 0.35, 1.0, 0.24)
		line.antialiased = true
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		path.add_child(line)
		var follow := PathFollow2D.new()
		follow.name = "EnergyPulse"
		follow.loop = false
		follow.rotates = false
		path.add_child(follow)
		var pulse := Sprite2D.new()
		pulse.texture = _radial_texture
		pulse.modulate = Color(0.45, 0.92, 1.0, 0.88)
		pulse.scale = Vector2(0.055, 0.055)
		follow.add_child(pulse)
		_paths.append(path); _path_lines.append(line); _pulse_follows.append(follow)

func _create_platform_glows() -> void:
	for index in SLOT_IDS.size():
		var glow := Sprite2D.new()
		glow.name = "PlatformGlow_%s" % String(SLOT_IDS[index])
		glow.texture = _radial_texture
		glow.modulate = Color(0.38, 0.55, 1.0, 0.05)
		platform_glow_layer.add_child(glow)
		_platform_glows.append(glow)

func _configure_path(index: int, start: Vector2, target: Vector2, slot_id: StringName) -> void:
	var curve := Curve2D.new()
	curve.add_point(start)
	var vertical_sign := -1.0 if String(slot_id).begins_with("top") else (1.0 if String(slot_id).begins_with("bottom") else 0.0)
	var horizontal_sign := -1.0 if String(slot_id).ends_with("left") else 1.0
	var span := target - start
	curve.add_point(start + Vector2(span.x * 0.28, vertical_sign * _layout_rect.size.y * 0.025))
	curve.add_point(start + Vector2(span.x * 0.62, span.y * 0.68) + Vector2(horizontal_sign * _layout_rect.size.x * 0.012, 0.0))
	curve.add_point(target)
	_paths[index].curve = curve
	_path_lines[index].points = curve.get_baked_points()

func _fallback_slot_position(slot_id: StringName) -> Vector2:
	match slot_id:
		&"top_left": return Vector2(0.347, 0.260)
		&"top_right": return Vector2(0.647, 0.260)
		&"middle_left": return Vector2(0.233, 0.479)
		&"middle_right": return Vector2(0.767, 0.479)
		&"bottom_left": return Vector2(0.340, 0.746)
		_: return Vector2(0.653, 0.746)

func _make_radial_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1,1,1,1), Color(1,1,1,0)])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256; texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5,0.5); texture.fill_to = Vector2(1.0,0.5)
	return texture
