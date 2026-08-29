extends Control

const SLOT_IDS: Array[StringName] = [&"top_left", &"top_right", &"middle_left", &"middle_right", &"bottom_left", &"bottom_right"]
const SLOT_POSITIONS := {
	&"top_left": Vector2(0.347, 0.260), &"top_right": Vector2(0.647, 0.260),
	&"middle_left": Vector2(0.233, 0.479), &"middle_right": Vector2(0.767, 0.479),
	&"bottom_left": Vector2(0.340, 0.746), &"bottom_right": Vector2(0.653, 0.746),
}
const SLOT_SIZE := Vector2(0.145, 0.145)
const PART_FACTORY_RUN_REWARDS := [0, 2, 4, 7]
const SHIELD_GENERATOR_CHARGES := [0, 1, 1, 2]
const SIM_CHAMBER_REROLLS := [0, 1, 2, 3]
const DATA_ARCHIVE_XP_PERCENT := [0, 8, 16, 25]
const BUILDING_MAX_LEVEL := 3

# Dokuz bina, alti platform. Tum insa/gelistirme verisi tek kaynakta.
const BUILDINGS := {
	"plasma_lab": {
		"name": "PLAZMA LABORATUVARI",
		"build_cost": 10,
		"upgrade_costs": {1: 20, 2: 35},
	},
	"fire_reactor": {
		"name": "ATEŞ REAKTÖRÜ",
		"build_cost": 20,
		"upgrade_costs": {1: 24, 2: 40},
	},
	"piercing_research": {
		"name": "DELİCİ ARAŞTIRMA MERKEZİ",
		"build_cost": 20,
		"upgrade_costs": {1: 24, 2: 40},
	},
	"part_factory": {
		"name": "PARÇA ÜRETİM TESİSİ",
		"build_cost": 55,
		"upgrade_costs": {1: 30, 2: 50},
	},
	"coin_refinery": {
		"name": "COIN RAFİNERİSİ",
		"build_cost": 35,
		"upgrade_costs": {1: 35, 2: 60},
	},
	"tech_center": {
		"name": "TEKNOLOJİ MERKEZİ",
		"build_cost": 25,
		"upgrade_costs": {1: 40, 2: 65},
	},
	"shield_generator": {
		"name": "KALKAN JENERATÖRÜ",
		"build_cost": 22,
		"upgrade_costs": {1: 44, 2: 70},
	},
	"sim_chamber": {
		"name": "EĞİTİM SİMÜLATÖRÜ",
		"build_cost": 20,
		"upgrade_costs": {1: 40, 2: 68},
	},
	"data_archive": {
		"name": "VERİ ARŞİVİ",
		"build_cost": 16,
		"upgrade_costs": {1: 32, 2: 55},
	},
}

const WORKSHOP_TEXTURE := preload("res://assets/colony/workshop.png")
const PLASMA_LAB_LIVE_SCENE := preload("res://colony/buildings/plasma_lab_live.tscn")
const PLASMA_BODY_TEXTURE := preload("res://assets/colony/buildings/plasma_layers/plasma_body.png")
const FIRE_REACTOR_LIVE_SCENE := preload("res://colony/buildings/fire_reactor_live.tscn")
const FIRE_BODY_TEXTURE := preload("res://assets/colony/buildings/plasma_layers/fire_body.png")
const PIERCING_RESEARCH_LIVE_SCENE := preload("res://colony/buildings/piercing_research_live.tscn")
const PIERCING_BODY_TEXTURE := preload("res://assets/colony/buildings/plasma_layers/piercing_body.png")
const PART_FACTORY_LIVE_SCENE := preload("res://colony/buildings/part_factory_live.tscn")
const PART_FACTORY_BODY_TEXTURE := preload("res://assets/colony/buildings/part_factory_body.png")
const COIN_REFINERY_LIVE_SCENE := preload("res://colony/buildings/coin_refinery_live.tscn")
const COIN_REFINERY_BODY_TEXTURE := preload("res://assets/colony/buildings/coin_refinery_body.png")
const TECH_CENTER_LIVE_SCENE := preload("res://colony/buildings/technology_center_live.tscn")
const TECH_CENTER_BODY_TEXTURE := preload("res://assets/colony/buildings/technology_center_body.png")
const ANDROID_EDGE_FADE_SHADER := """
shader_type canvas_item;
uniform float fade_uv : hint_range(0.0, 0.25) = 0.05;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float top_fade = smoothstep(0.0, fade_uv, UV.y);
	float bottom_fade = 1.0 - smoothstep(1.0 - fade_uv, 1.0, UV.y);
	tex_color.a *= top_fade * bottom_fade;
	COLOR = tex_color;
}
"""
const BUILDING_IDLE_ENERGY_SHADER := """
shader_type canvas_item;

uniform vec4 energy_color : source_color = vec4(0.3, 1.0, 0.8, 1.0);
uniform float pulse_period : hint_range(1.0, 3.0) = 2.0;
uniform float pulse_amount : hint_range(0.0, 0.5) = 0.32;
uniform float phase_offset = 0.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV) * COLOR;
	float max_channel = max(tex_color.r, max(tex_color.g, tex_color.b));
	float min_channel = min(tex_color.r, min(tex_color.g, tex_color.b));
	float saturation = max_channel - min_channel;
	float energy_mask = smoothstep(0.10, 0.52, saturation) * smoothstep(0.10, 0.72, max_channel);
	float wave = 0.5 + 0.5 * sin(TIME * 6.28318530718 / pulse_period + phase_offset);
	float energy = energy_mask * pulse_amount * wave;
	tex_color.rgb *= 1.0 + energy;
	tex_color.rgb += energy_color.rgb * energy * 0.10 * tex_color.a;
	COLOR = tex_color;
}
"""

const BUILDING_AURA_SHADER := """
shader_type canvas_item;
render_mode blend_add;

uniform vec4 energy_color : source_color = vec4(0.3, 1.0, 0.8, 1.0);
uniform float pulse_period = 2.0;
uniform float phase_offset = 0.0;
uniform float alpha_min = 0.15;
uniform float alpha_max = 0.25;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float wave = 0.5 + 0.5 * sin(TIME * 6.28318530718 / pulse_period + phase_offset);
	float alpha = mix(alpha_min, alpha_max, wave) * tex_color.a;
	float detail = 0.72 + 0.28 * max(tex_color.r, max(tex_color.g, tex_color.b));
	COLOR = vec4(energy_color.rgb * detail, alpha);
}
"""
const BUILDING_RADIAL_GLOW_SHADER := """
shader_type canvas_item;
render_mode blend_add;

uniform vec4 energy_color : source_color = vec4(0.3, 1.0, 0.8, 1.0);
uniform float pulse_period = 2.0;
uniform float phase_offset = 0.0;
uniform float alpha_min = 0.10;
uniform float alpha_max = 0.35;
uniform float vertical_scale = 1.0;

void fragment() {
	float wave = 0.5 + 0.5 * sin(TIME * 6.28318530718 / pulse_period + phase_offset);
	vec2 centered = vec2(UV.x - 0.5, (UV.y - 0.5) * vertical_scale);
	float radial = 1.0 - smoothstep(0.0, 0.5, length(centered));
	radial *= radial;
	COLOR = vec4(energy_color.rgb, radial * mix(alpha_min, alpha_max, wave));
}
"""
const PLASMA_CONTACT_SHADOW_SHADER := """
shader_type canvas_item;

uniform float opacity = 0.25;

void fragment() {
	vec2 centered = vec2(UV.x - 0.5, (UV.y - 0.5) * 3.5);
	float shadow = 1.0 - smoothstep(0.0, 0.5, length(centered));
	shadow *= shadow;
	COLOR = vec4(0.004, 0.008, 0.025, shadow * opacity);
}
"""
const PLASMA_CORE_UV := Vector2(0.491, 0.508)

var slots: Dictionary = {}
var visuals: Array[Control] = []
var pending_slot: StringName = &"none"
var selected_mobile: StringName = &"none"
var colony_canvas: Control
var space_fill: TextureRect
var colony_environment: Control
var background: TextureRect
var edge_fade_material: ShaderMaterial
var building_idle_shader: Shader
var building_aura_shader: Shader
var building_radial_glow_shader: Shader
var plasma_contact_shadow_shader: Shader
var idle_layers_by_slot: Dictionary = {}
var building_footprint_center_cache: Dictionary = {}
var world: Control
var buildings: Control
var hud: Control
var popup: Control
var back_button: Button
var title: Label
var parts: Label
var build_panel: Panel
var popup_dim: ColorRect
var status: Label
var panel_title: Label
var panel_level: Label
var panel_description: Label
var building_action_button: Button
var calibrate_button: Button
var build_buttons: Dictionary = {}
var build_button_scroll: ScrollContainer
var build_button_box: VBoxContainer
var panel_mode := ""
var hint_tween: Tween
var feedback: Label
var feedback_timer: Timer
var selection_ring: Panel
var selected_slot: StringName = &"none"
var selection_tween: Tween

func _ready() -> void:
	get_tree().paused = false
	colony_canvas = $ColonyCanvas
	space_fill = $AndroidSpaceFill
	colony_environment = $ColonyCanvas/Background/ColonyEnvironment
	background = $ColonyCanvas/Background/ColonyEnvironment/Background
	world = $ColonyCanvas/ColonyWorld
	buildings = $ColonyCanvas/ColonyBuildings
	hud = $ColonyHUD
	popup = $PopupLayer
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_slots()
	_setup_selection_visuals()
	_setup_hud()
	_setup_popup()
	_refresh()
	_show_first_time_hint()
	get_viewport().size_changed.connect(_layout)
	call_deferred("_layout")

func _setup_slots() -> void:
	for slot_id in SLOT_IDS:
		var button := world.get_node(String(slot_id)) as Button
		slots[slot_id] = button
		button.text = ""
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.focus_mode = Control.FOCUS_NONE if OS.has_feature("mobile") else Control.FOCUS_ALL
		button.add_theme_stylebox_override("normal", _slot_style(false))
		button.add_theme_stylebox_override("hover", _slot_style(true))
		button.add_theme_stylebox_override("focus", _slot_style(true))
		button.add_theme_stylebox_override("pressed", _slot_style(true))
		button.pressed.connect(_slot_pressed.bind(slot_id))

func _setup_selection_visuals() -> void:
	selection_ring = Panel.new()
	selection_ring.name = "BuildingSelectionRing"
	selection_ring.visible = false
	selection_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_ring.z_index = 20
	selection_ring.modulate.a = 0.0
	buildings.add_child(selection_ring)

func _setup_hud() -> void:
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_button = Button.new()
	back_button.text = "ANA MENÜYE DÖN"
	back_button.mouse_filter = Control.MOUSE_FILTER_STOP
	back_button.pressed.connect(_back)
	hud.add_child(back_button)
	title = Label.new()
	title.text = "KOLONİ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.25, 0.95, 1.0))
	hud.add_child(title)
	parts = Label.new()
	parts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	parts.add_theme_font_size_override("font_size", 20)
	parts.add_theme_color_override("font_color", Color(1.0, 0.72, 0.22))
	hud.add_child(parts)

func _setup_popup() -> void:
	# Panelin arkasındaki karartma; dışına dokununca popup kapanır.
	popup_dim = ColorRect.new()
	popup_dim.name = "PopupDim"
	popup_dim.color = Color(0.004, 0.012, 0.035, 0.55)
	popup_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_dim.visible = false
	popup.add_child(popup_dim)
	popup.gui_input.connect(_popup_dim_input)

	build_panel = Panel.new()
	build_panel.visible = false
	build_panel.z_index = 40
	build_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	build_panel.add_theme_stylebox_override("panel", _panel_style())
	popup.add_child(build_panel)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 24
	box.offset_top = 20
	box.offset_right = -24
	box.offset_bottom = -20
	box.add_theme_constant_override("separation", 10)
	build_panel.add_child(box)

	panel_title = Label.new()
	panel_title.text = "PLAZMA LABORATUVARI"
	panel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel_title.add_theme_font_size_override("font_size", 24)
	panel_title.add_theme_color_override("font_color", Color(0.35, 1.0, 0.65))
	box.add_child(panel_title)

	panel_level = Label.new()
	panel_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel_level.add_theme_font_size_override("font_size", 19)
	box.add_child(panel_level)

	panel_description = Label.new()
	panel_description.text = "Plazma Raketinin bonusunu güçlendirir."
	panel_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_description.add_theme_font_size_override("font_size", 17)
	box.add_child(panel_description)

	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_color_override("font_color", Color(1.0, 0.34, 0.28))
	box.add_child(status)

	building_action_button = Button.new()
	building_action_button.custom_minimum_size.y = 48
	building_action_button.pressed.connect(_on_primary_action_pressed)
	box.add_child(building_action_button)

	calibrate_button = Button.new()
	calibrate_button.custom_minimum_size.y = 44
	calibrate_button.visible = false
	calibrate_button.pressed.connect(_on_calibrate_pressed)
	box.add_child(calibrate_button)

	# Dokuz bina bir panele sigmadigi icin insa listesi kaydirilabilir.
	build_button_scroll = ScrollContainer.new()
	build_button_scroll.custom_minimum_size.y = 300
	build_button_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(build_button_scroll)

	build_button_box = VBoxContainer.new()
	build_button_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_button_box.add_theme_constant_override("separation", 6)
	build_button_scroll.add_child(build_button_box)

	for building_id: String in GameManager.COLONY_BUILDING_IDS:
		var build_button := Button.new()
		build_button.custom_minimum_size.y = 48
		build_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		build_button.pressed.connect(_building_action.bind(building_id))
		build_button_box.add_child(build_button)
		build_buttons[building_id] = build_button

	var cancel := Button.new()
	cancel.text = "İPTAL"
	cancel.custom_minimum_size.y = 44
	cancel.pressed.connect(_close_popup)
	box.add_child(cancel)

	feedback = Label.new()
	feedback.visible = false
	feedback.z_index = 45
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.add_theme_font_size_override("font_size", 20)
	popup.add_child(feedback)
	feedback_timer = Timer.new()
	feedback_timer.one_shot = true
	feedback_timer.wait_time = 1.35
	feedback_timer.timeout.connect(func(): feedback.visible = false)
	popup.add_child(feedback_timer)

func _building_footprint_center(texture: Texture2D) -> Vector2:
	var cache_key := texture.resource_path if not texture.resource_path.is_empty() else str(texture.get_instance_id())
	if building_footprint_center_cache.has(cache_key):
		return building_footprint_center_cache[cache_key]
	var image := texture.get_image()
	if image == null or image.is_empty():
		return Vector2(0.5, 0.82)
	var image_width := image.get_width()
	var image_height := image.get_height()
	var sample_step := maxi(1, mini(image_width, image_height) / 320)
	var min_y := image_height
	var max_y := -1
	for y in range(0, image_height, sample_step):
		for x in range(0, image_width, sample_step):
			if image.get_pixel(x, y).a > 0.12:
				min_y = mini(min_y, y)
				max_y = maxi(max_y, y)
	if max_y <= min_y:
		return Vector2(0.5, 0.82)
	# Anten/kule/hologram yerine yalnız görünür gövdenin alt footprint bandını ölç.
	var base_start := int(lerpf(float(min_y), float(max_y), 0.64))
	var sampled_rows: Array[Vector3] = []
	var strongest_row_weight := 0.0
	for y in range(base_start, max_y + 1, sample_step):
		var row_weight := 0.0
		var weighted_x := 0.0
		for x in range(0, image_width, sample_step):
			var alpha := image.get_pixel(x, y).a
			if alpha > 0.12:
				row_weight += alpha
				weighted_x += float(x) * alpha
		if row_weight > 0.0:
			sampled_rows.append(Vector3(weighted_x / row_weight, float(y), row_weight))
			strongest_row_weight = maxf(strongest_row_weight, row_weight)
	var footprint := Vector2(0.5, 0.82)
	if strongest_row_weight > 0.0:
		var total_weight := 0.0
		var center_sum := Vector2.ZERO
		for row in sampled_rows:
			if row.z >= strongest_row_weight * 0.82:
				center_sum += Vector2(row.x, row.y) * row.z
				total_weight += row.z
		if total_weight > 0.0:
			var pixel_center := center_sum / total_weight
			footprint = Vector2(
				pixel_center.x / maxf(float(image_width - 1), 1.0),
				pixel_center.y / maxf(float(image_height - 1), 1.0)
			)
	footprint.x = clampf(footprint.x, 0.30, 0.70)
	footprint.y = clampf(footprint.y, 0.60, 0.96)
	building_footprint_center_cache[cache_key] = footprint
	return footprint


func center_building_on_slot(visual: Control, texture: Texture2D, slot_center: Vector2, visual_size: Vector2) -> Vector2:
	var footprint_center := _building_footprint_center(texture)
	var visual_rect_center := slot_center - (footprint_center - Vector2(0.5, 0.5)) * visual_size
	visual.position = visual_rect_center - visual_size * 0.5
	visual.size = visual_size
	return visual_rect_center


func _layout_plasma_lab_live(visual: Control, visual_size: Vector2) -> void:
	var plasma_live := visual.get_node_or_null("PlasmaLabLive") as Node2D
	if plasma_live == null:
		return
	plasma_live.position = visual_size * 0.5
	var live_scale := visual_size.x / maxf(float(PLASMA_BODY_TEXTURE.get_width()), 1.0)
	plasma_live.scale = Vector2.ONE * live_scale

func _layout_fire_reactor_live(visual: Control, visual_size: Vector2) -> void:
	var fire_live := visual.get_node_or_null("FireReactorLive") as Node2D
	if fire_live == null:
		return
	fire_live.position = visual_size * 0.5
	var live_scale := visual_size.x / maxf(float(FIRE_BODY_TEXTURE.get_width()), 1.0)
	fire_live.scale = Vector2.ONE * live_scale


func _layout_piercing_research_live(visual: Control, visual_size: Vector2) -> void:
	var piercing_live := visual.get_node_or_null("PiercingResearchLive") as Node2D
	if piercing_live == null:
		return
	piercing_live.position = visual_size * 0.5
	var live_scale := visual_size.x / maxf(float(PIERCING_BODY_TEXTURE.get_width()), 1.0)
	piercing_live.scale = Vector2.ONE * live_scale


func _layout_part_factory_live(visual: Control, visual_size: Vector2) -> void:
	var factory_live := visual.get_node_or_null("PartFactoryLive") as Node2D
	if factory_live == null:
		return
	factory_live.position = visual_size * 0.5
	var live_scale := visual_size.x / maxf(float(PART_FACTORY_BODY_TEXTURE.get_width()), 1.0)
	factory_live.scale = Vector2.ONE * live_scale


func _layout_coin_refinery_live(visual: Control, visual_size: Vector2) -> void:
	var refinery_live := visual.get_node_or_null("CoinRefineryLive") as Node2D
	if refinery_live == null:
		return
	refinery_live.position = visual_size * 0.5
	var live_scale := visual_size.x / maxf(float(COIN_REFINERY_BODY_TEXTURE.get_width()), 1.0)
	refinery_live.scale = Vector2.ONE * live_scale


func _layout_technology_center_live(visual: Control, visual_size: Vector2) -> void:
	var technology_live := visual.get_node_or_null("TechnologyCenterLive") as Node2D
	if technology_live == null:
		return
	technology_live.position = visual_size * 0.5
	var live_scale := visual_size.x / maxf(float(TECH_CENTER_BODY_TEXTURE.get_width()), 1.0)
	technology_live.scale = Vector2.ONE * live_scale


func _layout() -> void:
	var viewport_size := get_viewport_rect().size
	var safe := GameManager.refresh_mobile_safe_area(viewport_size)
	var canvas_layout_size := viewport_size
	if OS.has_feature("mobile"):
		# Portrait boşluğunu ayrı uzay dokusu doldurur. ColonyCanvas tek parça
		# ve uniform ölçeklenir; ana koloni görseli asla gerilmez veya kırpılmaz.
		space_fill.visible = true
		space_fill.position = Vector2.ZERO
		space_fill.size = viewport_size
		space_fill.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		var native := Vector2(background.texture.get_size())
		var scale_factor := viewport_size.x / native.x
		colony_canvas.size = native
		colony_canvas.scale = Vector2.ONE * scale_factor
		colony_canvas.position = Vector2(0.0, (viewport_size.y - native.y * scale_factor) * 0.5)
		canvas_layout_size = native
		colony_environment.call("set_background_stretch_mode", TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		_apply_android_edge_fade(35.0 / maxf(native.y * scale_factor, 1.0))
	else:
		space_fill.visible = false
		background.material = null
		colony_canvas.position = Vector2.ZERO
		colony_canvas.size = viewport_size
		colony_canvas.scale = Vector2.ONE
		colony_environment.call("set_background_stretch_mode", TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	$ColonyCanvas/Background.position = Vector2.ZERO
	$ColonyCanvas/Background.size = canvas_layout_size
	world.position = Vector2.ZERO
	world.size = canvas_layout_size
	buildings.position = Vector2.ZERO
	buildings.size = canvas_layout_size
	hud.position = safe.position
	hud.size = safe.size
	var bw := clampf(safe.size.x * 0.24, 138, 190)
	back_button.position = Vector2(10, 8)
	back_button.size = Vector2(bw, 50)
	var pw := clampf(safe.size.x * 0.22, 122, 190)
	parts.position = Vector2(safe.size.x - pw - 12, 15)
	parts.size = Vector2(pw, 40)
	title.position = Vector2(bw + 24, 10)
	title.size = Vector2(maxf(parts.position.x - bw - 32, 80), 48)
	var rect := _display_rect(canvas_layout_size)
	colony_environment.call("configure_layout", rect, SLOT_POSITIONS)
	for id in SLOT_IDS:
		var center: Vector2 = rect.position + rect.size * SLOT_POSITIONS[id]
		var size := rect.size * SLOT_SIZE
		var node := slots[id] as Control
		node.position = center - size * 0.5
		node.size = size
	_update_selection_ring_layout(rect)
	for visual in visuals:
		var id := StringName(String(visual.get_meta("slot_id")))
		var slot_center: Vector2 = rect.position + rect.size * SLOT_POSITIONS[id]
		var center := slot_center
		var building_type := String(visual.get_meta("building_type", ""))
		var uses_real_building_asset := building_type in [
			GameManager.COLONY_BUILDING_PLASMA_LAB,
			GameManager.COLONY_BUILDING_FIRE_REACTOR,
			GameManager.COLONY_BUILDING_PIERCING_RESEARCH,
			GameManager.COLONY_BUILDING_PART_FACTORY,
			GameManager.COLONY_BUILDING_COIN_REFINERY,
			GameManager.COLONY_BUILDING_TECH_CENTER,
		]
		var width_ratio := 0.688 if uses_real_building_asset else 0.82
		var width := rect.size.x * SLOT_SIZE.x * width_ratio
		var size := Vector2(width, rect.size.y * SLOT_SIZE.y * width_ratio)
		var layout_texture: Texture2D = null
		if building_type == GameManager.COLONY_BUILDING_PLASMA_LAB:
			layout_texture = PLASMA_BODY_TEXTURE
		elif building_type == GameManager.COLONY_BUILDING_FIRE_REACTOR:
			layout_texture = FIRE_BODY_TEXTURE
		elif building_type == GameManager.COLONY_BUILDING_PIERCING_RESEARCH:
			layout_texture = PIERCING_BODY_TEXTURE
		elif building_type == GameManager.COLONY_BUILDING_PART_FACTORY:
			layout_texture = PART_FACTORY_BODY_TEXTURE
		elif building_type == GameManager.COLONY_BUILDING_COIN_REFINERY:
			layout_texture = COIN_REFINERY_BODY_TEXTURE
		elif building_type == GameManager.COLONY_BUILDING_TECH_CENTER:
			layout_texture = TECH_CENTER_BODY_TEXTURE
		elif visual is TextureRect:
			layout_texture = (visual as TextureRect).texture
		if layout_texture != null:
			size.y = width * layout_texture.get_height() / layout_texture.get_width()
		if uses_real_building_asset and layout_texture != null:
			center = center_building_on_slot(visual, layout_texture, slot_center, size)
		else:
			visual.position = center - size * 0.5
			visual.size = size
		if building_type == GameManager.COLONY_BUILDING_PLASMA_LAB:
			_layout_plasma_lab_live(visual, size)
		elif building_type == GameManager.COLONY_BUILDING_FIRE_REACTOR:
			_layout_fire_reactor_live(visual, size)
		elif building_type == GameManager.COLONY_BUILDING_PIERCING_RESEARCH:
			_layout_piercing_research_live(visual, size)
		elif building_type == GameManager.COLONY_BUILDING_PART_FACTORY:
			_layout_part_factory_live(visual, size)
		elif building_type == GameManager.COLONY_BUILDING_COIN_REFINERY:
			_layout_coin_refinery_live(visual, size)
		elif building_type == GameManager.COLONY_BUILDING_TECH_CENTER:
			_layout_technology_center_live(visual, size)
		_layout_building_idle_layers(id, center, size, slot_center)
		if visual is Panel:
			var core := visual.get_node("Core") as Control
			core.position = size * 0.30
			core.size = size * 0.40
	var ps := Vector2(minf(470, safe.size.x - 28), minf(570, safe.size.y - 28))
	if OS.has_feature("mobile"):
		build_panel.position = safe.position + Vector2((safe.size.x - ps.x) * 0.5, safe.size.y - ps.y - 12.0)
	else:
		build_panel.position = safe.position + Vector2(safe.size.x - ps.x - 24.0, (safe.size.y - ps.y) * 0.5)
	build_panel.size = ps
	feedback.position = safe.position + Vector2(0, safe.size.y * 0.14)
	feedback.size = Vector2(safe.size.x, 44)

func _idle_energy_parameters(building_type: String) -> Dictionary:
	match building_type:
		GameManager.COLONY_BUILDING_PLASMA_LAB:
			return {"color": Color("39ffc4"), "duration": 1.8, "intensity": 0.38}
		GameManager.COLONY_BUILDING_FIRE_REACTOR:
			return {"color": Color("ff542e"), "duration": 1.35, "intensity": 0.34}
		GameManager.COLONY_BUILDING_PIERCING_RESEARCH:
			return {"color": Color("ffd044"), "duration": 1.9, "intensity": 0.36}
		GameManager.COLONY_BUILDING_PART_FACTORY:
			return {"color": Color("31cfff"), "duration": 2.0, "intensity": 0.30}
		GameManager.COLONY_BUILDING_COIN_REFINERY:
			return {"color": Color("ffd84a"), "duration": 1.6, "intensity": 0.32}
		GameManager.COLONY_BUILDING_TECH_CENTER:
			return {"color": Color("8f70ff"), "duration": 2.4, "intensity": 0.25}
		_:
			return {"color": Color.WHITE, "duration": 2.0, "intensity": 0.0}


func _get_building_idle_shader() -> Shader:
	if building_idle_shader == null:
		building_idle_shader = Shader.new()
		building_idle_shader.code = BUILDING_IDLE_ENERGY_SHADER
	return building_idle_shader


func _apply_building_idle_visual(visual: TextureRect, building_type: String, slot_id: StringName) -> void:
	var parameters := _idle_energy_parameters(building_type)
	var idle_material := ShaderMaterial.new()
	idle_material.shader = _get_building_idle_shader()
	idle_material.set_shader_parameter("energy_color", parameters["color"])
	idle_material.set_shader_parameter("pulse_period", float(parameters["duration"]))
	idle_material.set_shader_parameter("pulse_amount", float(parameters["intensity"]))
	var slot_phase := float(maxi(SLOT_IDS.find(slot_id), 0)) * 0.83
	var building_phase := float(maxi(GameManager.COLONY_BUILDING_IDS.find(building_type), 0)) * 0.41
	idle_material.set_shader_parameter("phase_offset", slot_phase + building_phase)
	visual.material = idle_material

func _get_building_aura_shader() -> Shader:
	if building_aura_shader == null:
		building_aura_shader = Shader.new()
		building_aura_shader.code = BUILDING_AURA_SHADER
	return building_aura_shader


func _get_building_radial_glow_shader() -> Shader:
	if building_radial_glow_shader == null:
		building_radial_glow_shader = Shader.new()
		building_radial_glow_shader.code = BUILDING_RADIAL_GLOW_SHADER
	return building_radial_glow_shader


func _idle_phase(building_type: String, slot_id: StringName) -> float:
	var slot_phase := float(maxi(SLOT_IDS.find(slot_id), 0)) * 0.83
	var building_phase := float(maxi(GameManager.COLONY_BUILDING_IDS.find(building_type), 0)) * 0.41
	return slot_phase + building_phase


func _make_aura_material(parameters: Dictionary, phase: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = _get_building_aura_shader()
	material.set_shader_parameter("energy_color", parameters["color"])
	material.set_shader_parameter("pulse_period", float(parameters["duration"]))
	material.set_shader_parameter("phase_offset", phase)
	material.set_shader_parameter("alpha_min", 0.15)
	material.set_shader_parameter("alpha_max", 0.25)
	return material


func _make_radial_material(parameters: Dictionary, phase: float, alpha_min: float, alpha_max: float, vertical_scale: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = _get_building_radial_glow_shader()
	material.set_shader_parameter("energy_color", parameters["color"])
	material.set_shader_parameter("pulse_period", float(parameters["duration"]))
	material.set_shader_parameter("phase_offset", phase)
	material.set_shader_parameter("alpha_min", alpha_min)
	material.set_shader_parameter("alpha_max", alpha_max)
	material.set_shader_parameter("vertical_scale", vertical_scale)
	return material


func _get_plasma_contact_shadow_shader() -> Shader:
	if plasma_contact_shadow_shader == null:
		plasma_contact_shadow_shader = Shader.new()
		plasma_contact_shadow_shader.code = PLASMA_CONTACT_SHADOW_SHADER
	return plasma_contact_shadow_shader


func _make_plasma_contact_shadow_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = _get_plasma_contact_shadow_shader()
	material.set_shader_parameter("opacity", 0.25)
	return material

func _create_building_idle_layers(visual: TextureRect, building_type: String, slot_id: StringName) -> void:
	var parameters := _idle_energy_parameters(building_type)
	var phase := _idle_phase(building_type, slot_id)
	if building_type == GameManager.COLONY_BUILDING_PLASMA_LAB:
		var contact_shadow := ColorRect.new()
		contact_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contact_shadow.z_index = 1
		contact_shadow.material = _make_plasma_contact_shadow_material()
		buildings.add_child(contact_shadow)
		var platform_light := ColorRect.new()
		platform_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
		platform_light.z_index = 2
		platform_light.material = _make_radial_material(parameters, phase + 0.28, 0.10, 0.18, 2.4)
		buildings.add_child(platform_light)
		var core_parameters := parameters.duplicate()
		core_parameters["duration"] = 1.5
		var energy_core := ColorRect.new()
		energy_core.mouse_filter = Control.MOUSE_FILTER_IGNORE
		energy_core.z_index = 4
		energy_core.material = _make_radial_material(core_parameters, phase, 0.25, 0.65, 1.0)
		buildings.add_child(energy_core)
		idle_layers_by_slot[slot_id] = {
			"prototype": "plasma_integration",
			"shadow": contact_shadow,
			"platform": platform_light,
			"core": energy_core,
		}
		return
	var platform_glow := ColorRect.new()
	platform_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	platform_glow.z_index = 1
	platform_glow.material = _make_radial_material(parameters, phase + 0.35, 0.08, 0.18, 3.4)
	buildings.add_child(platform_glow)
	var aura := TextureRect.new()
	aura.texture = visual.texture
	aura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	aura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aura.z_index = 2
	aura.material = _make_aura_material(parameters, phase)
	buildings.add_child(aura)
	var core_glow := ColorRect.new()
	core_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	core_glow.z_index = 4
	core_glow.material = _make_radial_material(parameters, phase + 0.7, 0.10, 0.35, 1.0)
	buildings.add_child(core_glow)
	idle_layers_by_slot[slot_id] = {
		"platform": platform_glow,
		"aura": aura,
		"core": core_glow,
	}

func _layout_building_idle_layers(slot_id: StringName, building_center: Vector2, building_size: Vector2, slot_center: Vector2) -> void:
	if not idle_layers_by_slot.has(slot_id):
		return
	var layers: Dictionary = idle_layers_by_slot[slot_id]
	if String(layers.get("prototype", "")) == "plasma_integration":
		var shadow := layers["shadow"] as Control
		var shadow_size := Vector2(building_size.x * 0.72, building_size.x * 0.20)
		shadow.position = slot_center - shadow_size * 0.5
		shadow.size = shadow_size
		var platform_light := layers["platform"] as Control
		var platform_light_size := Vector2(building_size.x * 0.66, building_size.x * 0.30)
		platform_light.position = slot_center - platform_light_size * 0.5
		platform_light.size = platform_light_size
		var energy_core := layers["core"] as Control
		var core_center := building_center + (PLASMA_CORE_UV - Vector2(0.5, 0.5)) * building_size
		var core_size := Vector2.ONE * building_size.x * 0.28
		energy_core.position = core_center - core_size * 0.5
		energy_core.size = core_size
		return
	var aura := layers["aura"] as Control
	var aura_size := building_size * 1.05
	aura.position = building_center - aura_size * 0.5
	aura.size = aura_size
	var core := layers["core"] as Control
	var core_size := Vector2.ONE * building_size.x * 0.40
	core.position = slot_center - core_size * 0.5
	core.size = core_size
	var platform := layers["platform"] as Control
	var platform_size := Vector2(building_size.x * 1.10, building_size.x * 0.30)
	var platform_center := slot_center + Vector2(0.0, building_size.x * 0.10)
	platform.position = platform_center - platform_size * 0.5
	platform.size = platform_size

func _make_placeholder_building(building_type: String) -> Control:
	var tone := _building_theme_color(building_type)
	var holder := Panel.new()
	holder.clip_contents = false
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var body := StyleBoxFlat.new()
	body.bg_color = Color(0.02, 0.07, 0.11, 0.94)
	body.border_color = tone
	body.set_border_width_all(3)
	body.corner_radius_top_left = 14
	body.corner_radius_top_right = 14
	body.corner_radius_bottom_left = 4
	body.corner_radius_bottom_right = 4
	body.shadow_color = Color(tone.r, tone.g, tone.b, 0.35)
	body.shadow_size = 16
	holder.add_theme_stylebox_override("panel", body)

	var core := Panel.new()
	core.name = "Core"
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	core.set_anchors_preset(Control.PRESET_CENTER)
	var core_style := StyleBoxFlat.new()
	core_style.bg_color = Color(tone.r, tone.g, tone.b, 0.55)
	core_style.set_corner_radius_all(999)
	core.add_theme_stylebox_override("panel", core_style)
	holder.add_child(core)

	# Yavas nabiz, binanin "canli" durdugunu belli eder.
	var pulse := holder.create_tween().set_loops()
	pulse.tween_property(core, "modulate:a", 0.45, 1.1).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(core, "modulate:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE)
	return holder


func _building_theme_color(building_type: String) -> Color:
	match building_type:
		GameManager.COLONY_BUILDING_PLASMA_LAB:
			return Color("45f5b5")
		GameManager.COLONY_BUILDING_FIRE_REACTOR:
			return Color("ff6038")
		GameManager.COLONY_BUILDING_PIERCING_RESEARCH:
			return Color("ffc83d")
		GameManager.COLONY_BUILDING_PART_FACTORY:
			return Color("39cfff")
		GameManager.COLONY_BUILDING_COIN_REFINERY:
			return Color("ffd34e")
		GameManager.COLONY_BUILDING_TECH_CENTER:
			return Color("9a6dff")
		GameManager.COLONY_BUILDING_SHIELD_GENERATOR:
			return Color("52d8ff")
		GameManager.COLONY_BUILDING_SIM_CHAMBER:
			return Color("7dff9e")
		GameManager.COLONY_BUILDING_DATA_ARCHIVE:
			return Color("c98bff")
		_:
			return Color("62e7ff")


func _selection_ring_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = color
	style.set_border_width_all(3)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(color.r, color.g, color.b, 0.55)
	style.shadow_size = 9
	return style


func _update_selection_ring_layout(rect: Rect2) -> void:
	if selection_ring == null or selected_slot == &"none":
		return
	var center: Vector2 = rect.position + rect.size * SLOT_POSITIONS[selected_slot]
	var ring_size := rect.size * SLOT_SIZE * 1.08
	selection_ring.position = center - ring_size * 0.5
	selection_ring.size = ring_size


func _visual_for_slot(slot_id: StringName) -> Control:
	for visual in visuals:
		if StringName(String(visual.get_meta("slot_id", ""))) == slot_id:
			return visual
	return null


func _set_visual_highlight(slot_id: StringName, active: bool) -> void:
	if slot_id == &"none":
		return
	var visual := _visual_for_slot(slot_id)
	if visual == null:
		return
	var target := Color(1.12, 1.12, 1.12, 1.0) if active else Color.WHITE
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var is_live_building := visual.has_node("PlasmaLabLive") or visual.has_node("FireReactorLive") or visual.has_node("PiercingResearchLive") or visual.has_node("PartFactoryLive") or visual.has_node("CoinRefineryLive") or visual.has_node("TechnologyCenterLive")
	var color_property := "modulate" if is_live_building else "self_modulate"
	tween.tween_property(visual, color_property, target, 0.14)


func _apply_selection(slot_id: StringName, color: Color) -> void:
	selected_slot = slot_id
	selection_ring.add_theme_stylebox_override("panel", _selection_ring_style(color))
	selection_ring.visible = true
	_update_selection_ring_layout(_display_rect(world.size))
	_set_visual_highlight(slot_id, true)


func _select_slot_visual(slot_id: StringName, building_type: String) -> void:
	var color := _building_theme_color(building_type)
	if selection_tween != null and selection_tween.is_valid():
		selection_tween.kill()
	_set_visual_highlight(selected_slot, false)
	selection_tween = create_tween()
	selection_tween.set_trans(Tween.TRANS_SINE)
	if selection_ring.visible:
		selection_tween.set_ease(Tween.EASE_IN)
		selection_tween.tween_property(selection_ring, "modulate:a", 0.0, 0.10)
		selection_tween.tween_callback(_apply_selection.bind(slot_id, color))
	else:
		_apply_selection(slot_id, color)
	selection_tween.set_ease(Tween.EASE_OUT)
	selection_tween.tween_property(selection_ring, "modulate:a", 1.0, 0.16)


func _clear_selection_visual() -> void:
	if selection_ring == null:
		return
	if selection_tween != null and selection_tween.is_valid():
		selection_tween.kill()
	_set_visual_highlight(selected_slot, false)
	selected_slot = &"none"
	selection_tween = create_tween()
	selection_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	selection_tween.tween_property(selection_ring, "modulate:a", 0.0, 0.12)
	selection_tween.tween_callback(func(): selection_ring.visible = false)

func _apply_android_edge_fade(fade_uv: float) -> void:
	if edge_fade_material == null:
		var shader := Shader.new()
		shader.code = ANDROID_EDGE_FADE_SHADER
		edge_fade_material = ShaderMaterial.new()
		edge_fade_material.shader = shader
	background.material = edge_fade_material
	edge_fade_material.set_shader_parameter("fade_uv", clampf(fade_uv, 0.001, 0.24))

func _display_rect(canvas_size: Vector2) -> Rect2:
	if OS.has_feature("mobile"):
		return Rect2(Vector2.ZERO, canvas_size)
	var native := Vector2(background.texture.get_size())
	var scale_value := maxf(canvas_size.x / native.x, canvas_size.y / native.y)
	var size := native * scale_value
	return Rect2((canvas_size - size) * 0.5, size)

func _refresh() -> void:
	for layer_set in idle_layers_by_slot.values():
		for layer in (layer_set as Dictionary).values():
			(layer as Control).queue_free()
	idle_layers_by_slot.clear()
	for visual in visuals:
		visual.queue_free()
	visuals.clear()
	for id in SLOT_IDS:
		var entry := GameManager.get_colony_platform_building(String(id))
		if entry.is_empty():
			continue
		var building_type := String(entry.get("building_type", ""))
		var visual: Control
		if building_type == GameManager.COLONY_BUILDING_PLASMA_LAB:
			var plasma_wrapper := Control.new()
			plasma_wrapper.clip_contents = false
			var plasma_live := PLASMA_LAB_LIVE_SCENE.instantiate() as Node2D
			plasma_live.name = "PlasmaLabLive"
			plasma_wrapper.add_child(plasma_live)
			visual = plasma_wrapper
		elif building_type == GameManager.COLONY_BUILDING_FIRE_REACTOR:
			var fire_wrapper := Control.new()
			fire_wrapper.clip_contents = false
			var fire_live := FIRE_REACTOR_LIVE_SCENE.instantiate() as Node2D
			fire_live.name = "FireReactorLive"
			fire_wrapper.add_child(fire_live)
			visual = fire_wrapper
		elif building_type == GameManager.COLONY_BUILDING_PIERCING_RESEARCH:
			var piercing_wrapper := Control.new()
			piercing_wrapper.clip_contents = false
			var piercing_live := PIERCING_RESEARCH_LIVE_SCENE.instantiate() as Node2D
			piercing_live.name = "PiercingResearchLive"
			piercing_wrapper.add_child(piercing_live)
			visual = piercing_wrapper
		elif building_type == GameManager.COLONY_BUILDING_PART_FACTORY:
			var factory_wrapper := Control.new()
			factory_wrapper.clip_contents = false
			var factory_live := PART_FACTORY_LIVE_SCENE.instantiate() as Node2D
			factory_live.name = "PartFactoryLive"
			factory_wrapper.add_child(factory_live)
			visual = factory_wrapper
		elif building_type == GameManager.COLONY_BUILDING_COIN_REFINERY:
			var refinery_wrapper := Control.new()
			refinery_wrapper.clip_contents = false
			var refinery_live := COIN_REFINERY_LIVE_SCENE.instantiate() as Node2D
			refinery_live.name = "CoinRefineryLive"
			refinery_wrapper.add_child(refinery_live)
			visual = refinery_wrapper
		elif building_type == GameManager.COLONY_BUILDING_TECH_CENTER:
			var technology_wrapper := Control.new()
			technology_wrapper.clip_contents = false
			var technology_live := TECH_CENTER_LIVE_SCENE.instantiate() as Node2D
			technology_live.name = "TechnologyCenterLive"
			technology_wrapper.add_child(technology_live)
			visual = technology_wrapper
		elif building_type == "workshop":
			var workshop := TextureRect.new()
			workshop.texture = WORKSHOP_TEXTURE
			workshop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			workshop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			visual = workshop
		elif building_type in GameManager.COLONY_BUILDING_IDS:
			# Henuz ozel sanati olmayan binalar prosedurel bir yapiyla temsil edilir.
			visual = _make_placeholder_building(building_type)
		else:
			continue
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.set_meta("slot_id", String(id))
		visual.set_meta("building_type", building_type)
		if building_type in GameManager.COLONY_BUILDING_IDS:
			visual.z_index = 3
			if building_type not in [GameManager.COLONY_BUILDING_PLASMA_LAB, GameManager.COLONY_BUILDING_FIRE_REACTOR, GameManager.COLONY_BUILDING_PIERCING_RESEARCH, GameManager.COLONY_BUILDING_PART_FACTORY, GameManager.COLONY_BUILDING_COIN_REFINERY, GameManager.COLONY_BUILDING_TECH_CENTER] and visual is TextureRect:
				_apply_building_idle_visual(visual as TextureRect, building_type, id)
				_create_building_idle_layers(visual as TextureRect, building_type, id)
		buildings.add_child(visual)
		visuals.append(visual)
	parts.text = "PARÇA: %d" % GameManager.total_salvage


func _format_coin_chance_tr(chance: float) -> String:
	return ("%.2f" % (chance * 100.0)).replace(".", ",")


## Codex'in inşa seçeneği render'ı. Buradaki asıl kazanç: yetersiz PARÇA
## durumunda buton kapanıyor ve sebebini yazıyor — eskiden basıp
## "YETERSİZ PARÇA" hatası almak gerekiyordu.
func _configure_build_option(button: Button, building_id: String) -> void:
	var display_name := _building_display_name(building_id)
	var cost := int(BUILDINGS[building_id]["build_cost"])
	var installed := GameManager.get_colony_building_level(building_id) > 0
	var affordable := GameManager.total_salvage >= cost
	var tone := _building_theme_color(building_id)

	button.visible = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 14 if OS.has_feature("mobile") else 15)
	button.add_theme_color_override("font_color", Color(0.88, 0.97, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.58, 0.61, 0.66))
	button.add_theme_stylebox_override("normal", _build_entry_style(Color(tone.r, tone.g, tone.b, 0.72)))
	button.add_theme_stylebox_override("hover", _build_entry_style(Color(tone.r, tone.g, tone.b, 0.96)))
	button.add_theme_stylebox_override("pressed", _build_entry_style(Color(1.0, 0.72, 0.20, 0.92)))
	button.add_theme_stylebox_override("disabled", _build_entry_style(Color(0.22, 0.28, 0.34, 0.46)))

	var state := "KURULDU"
	if not installed:
		state = "KUR — %d PARÇA" % cost if affordable else "YETERSİZ PARÇA (%d)" % cost
	button.text = "%s\n%s\n%s" % [display_name, _building_effect_text(building_id, 1), state]
	button.disabled = installed or not affordable


func _build_entry_style(border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.06, 0.10, 0.92)
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


## Panelin dışına dokunmak popup'ı kapatır (Codex'ten).
func _popup_dim_input(event: InputEvent) -> void:
	if pending_slot == &"none" or not build_panel.visible:
		return
	# Tip cikarimi InputEvent tabanindan yapilamaz; alt tipler acikca ayrilir.
	var point := Vector2.ZERO
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		point = mouse_event.position
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if not touch_event.pressed:
			return
		point = touch_event.position
	else:
		return
	if not build_panel.get_global_rect().has_point(point):
		_close_popup()


func _building_display_name(building_id: String) -> String:
	return String(BUILDINGS.get(building_id, {}).get("name", building_id.to_upper()))


func _building_effect_text(building_id: String, level: int) -> String:
	var capped := clampi(level, 0, BUILDING_MAX_LEVEL)
	match building_id:
		GameManager.COLONY_BUILDING_FIRE_REACTOR:
			# Sayilar GameManager'dan okunur; oyunun uyguladigi degerin aynisi.
			return "Alev Raketi, Alev Topu ile %d ek tuğlayı etkileyebilir." % _fire_extra_targets(capped)
		GameManager.COLONY_BUILDING_PIERCING_RESEARCH:
			return "Delici Raketi, Delici Top ile %d ek tuğla deler." % _pierce_bonus(capped)
		GameManager.COLONY_BUILDING_PART_FACTORY:
			return "Her run sonunda +%d PARÇA." % GameManager.get_colony_run_end_salvage()
		GameManager.COLONY_BUILDING_COIN_REFINERY:
			var chance := GameManager.get_effective_coin_drop_chance(GameManager.COIN_BASE_DROP_CHANCE)
			return "Coin düşme ihtimali: %%%s" % _format_coin_chance_tr(chance)
		GameManager.COLONY_BUILDING_TECH_CENTER:
			var heart_bonus := int(GameManager.TECH_CENTER_FULL_LIFE_HEART_SALVAGE[capped])
			var magnet_percent := int(round(
				(float(GameManager.TECH_CENTER_MAGNET_MULTIPLIERS[capped]) - 1.0) * 100.0
			))
			return "Mıknatıs süresi %%%d daha uzun.
Maksimum candayken Heart: %s" % [
				magnet_percent,
				"+%d PARÇA." % heart_bonus if heart_bonus > 0 else "ek bonus yok."
			]
		GameManager.COLONY_BUILDING_SHIELD_GENERATOR:
			return "Her run başında %d ücretsiz kalkan.\nKalkan bir can kaybını tamamen önler." % GameManager.get_colony_shield_charges()
		GameManager.COLONY_BUILDING_SIM_CHAMBER:
			return "Her run başında +%d yeniden dağıtma hakkı." % GameManager.get_colony_bonus_rerolls()
		GameManager.COLONY_BUILDING_DATA_ARCHIVE:
			return "Toplanan XP %%%d daha fazla." % int(round(GameManager.get_colony_xp_bonus() * 100.0))
	return "Plazma Raketinin bonusunu güçlendirir."


## UI metni raket kimligini varsayar ("Delici Raketi ile"), yani afinite
## carpani dahildir. Oyunun uyguladigi degerle AYNI diziden okunur.
func _pierce_bonus(level: int) -> int:
	return int(GameManager.PIERCING_RESEARCH_BASE_PENETRATION[clampi(level, 0, 3)]) * 2


func _fire_extra_targets(level: int) -> int:
	return int(GameManager.FIRE_REACTOR_BASE_EXTRA_TARGETS[clampi(level, 0, 3)]) * 2


func _calibration_effect_text(building_id: String) -> String:
	match building_id:
		GameManager.COLONY_BUILDING_PLASMA_LAB:
			return "her kalibrasyon: ateş aralığı %2 kısalır"
		GameManager.COLONY_BUILDING_FIRE_REACTOR:
			return "her kalibrasyon: patlama yarıçapı %3 artar"
		GameManager.COLONY_BUILDING_PIERCING_RESEARCH:
			return "her 4 kalibrasyon: +1 delme"
		GameManager.COLONY_BUILDING_PART_FACTORY:
			return "her 2 kalibrasyon: run sonu +1 PARÇA"
		GameManager.COLONY_BUILDING_COIN_REFINERY:
			return "her kalibrasyon: coin şansı artar"
		GameManager.COLONY_BUILDING_TECH_CENTER:
			return "her kalibrasyon: mıknatıs süresi %5 uzar"
		GameManager.COLONY_BUILDING_SHIELD_GENERATOR:
			return "her 3 kalibrasyon: +1 kalkan"
		GameManager.COLONY_BUILDING_SIM_CHAMBER:
			return "her 2 kalibrasyon: +1 yeniden dağıtma"
		GameManager.COLONY_BUILDING_DATA_ARCHIVE:
			return "her kalibrasyon: XP %2 artar"
	return ""


func _slot_pressed(id: StringName) -> void:
	pending_slot = id
	status.text = ""
	var entry := GameManager.get_colony_platform_building(String(id))
	var selected_type := "" if entry.is_empty() else String(entry.get("building_type", ""))
	var theme_color := _building_theme_color(selected_type)
	_select_slot_visual(id, selected_type)
	build_panel.add_theme_stylebox_override("panel", _panel_style(theme_color))
	panel_title.add_theme_color_override("font_color", theme_color)

	if entry.is_empty():
		panel_mode = "build"
		panel_title.text = "YAPI İNŞA ET"
		panel_level.text = ""
		panel_description.text = "Buraya ne inşa etmek istiyorsun?"
		building_action_button.visible = false
		calibrate_button.visible = false
		build_button_scroll.visible = true
		for building_id: String in GameManager.COLONY_BUILDING_IDS:
			_configure_build_option(build_buttons[building_id], building_id)
		_show_build_panel()
		return

	var building_type := String(entry.get("building_type", ""))
	if building_type not in GameManager.COLONY_BUILDING_IDS:
		_show_feedback("YAPI SEÇİLDİ")
		pending_slot = &"none"
		return

	panel_mode = "upgrade"
	var level := clampi(int(entry.get("level", 1)), 1, BUILDING_MAX_LEVEL)
	var calibration := int(entry.get("calibration", 0))
	build_button_scroll.visible = false
	for building_id: String in GameManager.COLONY_BUILDING_IDS:
		(build_buttons[building_id] as Button).visible = false
	building_action_button.visible = true
	panel_title.text = _building_display_name(building_type)
	panel_level.text = "SEVİYE %d" % level
	if calibration > 0:
		panel_level.text += "   ·   KALİBRASYON %d" % calibration
	panel_description.text = _building_effect_text(building_type, level)
	_configure_upgrade_button(level, BUILDING_MAX_LEVEL, BUILDINGS[building_type]["upgrade_costs"])
	_configure_calibrate_button(building_type, level, calibration)
	_show_build_panel()


func _configure_calibrate_button(building_id: String, level: int, calibration: int) -> void:
	# Kalibrasyon yalnizca Lv3'te acilir ve sonsuza kadar tekrarlanabilir.
	if level < BUILDING_MAX_LEVEL:
		calibrate_button.visible = false
		return
	calibrate_button.visible = true
	var cost := GameManager.get_calibration_cost(calibration)
	calibrate_button.text = "KALİBRE ET — %d PARÇA" % cost
	calibrate_button.disabled = GameManager.total_salvage < cost
	var effect := _calibration_effect_text(building_id)
	if effect != "":
		panel_description.text += "\n\nKALİBRASYON %d — %s" % [calibration, effect]


func _on_primary_action_pressed() -> void:
	_building_action("")


func _on_calibrate_pressed() -> void:
	if pending_slot == &"none":
		return
	if not GameManager.calibrate_colony_building(String(pending_slot)):
		status.text = "YETERSİZ PARÇA"
		_show_feedback("YETERSİZ PARÇA", true)
		return
	var entry := GameManager.get_colony_platform_building(String(pending_slot))
	var building_type := String(entry.get("building_type", ""))
	var calibration := int(entry.get("calibration", 0))
	_close_popup()
	_refresh()
	_layout()
	_show_feedback("%s KALİBRE EDİLDİ — %d" % [
		_building_display_name(building_type), calibration
	])


func _show_build_panel() -> void:
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	if is_instance_valid(popup_dim):
		popup_dim.visible = true
	build_panel.visible = true
	build_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(build_panel, "modulate:a", 1.0, 0.18)


func _configure_upgrade_button(level: int, max_level: int, costs: Dictionary) -> void:
	if level >= max_level:
		building_action_button.text = "MAKSİMUM SEVİYE"
		building_action_button.disabled = true
	else:
		building_action_button.text = "GELİŞTİR — %d PARÇA" % int(costs[level])
		building_action_button.disabled = false


func _building_action(requested_building_id: String = "") -> void:
	if pending_slot == &"none":
		return
	var success := false
	var completed_type := requested_building_id

	if panel_mode == "build":
		if requested_building_id not in GameManager.COLONY_BUILDING_IDS:
			return
		success = GameManager.build_colony_building(
			requested_building_id,
			String(pending_slot),
			int(BUILDINGS[requested_building_id]["build_cost"])
		)
	elif panel_mode == "upgrade":
		var entry := GameManager.get_colony_platform_building(String(pending_slot))
		var building_type := String(entry.get("building_type", ""))
		completed_type = building_type
		if building_type not in GameManager.COLONY_BUILDING_IDS:
			return
		var level := int(entry.get("level", 1))
		if level < BUILDING_MAX_LEVEL:
			var costs: Dictionary = BUILDINGS[building_type]["upgrade_costs"]
			success = GameManager.upgrade_colony_building(
				String(pending_slot),
				int(costs[level]),
				BUILDING_MAX_LEVEL
			)

	if not success:
		status.text = "YETERSİZ PARÇA"
		_show_feedback("YETERSİZ PARÇA", true)
		return

	var completed_mode := panel_mode
	_close_popup()
	_refresh()
	_layout()
	_show_feedback("%s %s" % [
		_building_display_name(completed_type),
		"İNŞA EDİLDİ" if completed_mode == "build" else "GELİŞTİRİLDİ"
	])


func _close_popup() -> void:
	build_panel.visible = false
	if is_instance_valid(popup_dim):
		popup_dim.visible = false
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clear_selection_visual()
	pending_slot = &"none"
	status.text = ""
	panel_mode = ""
	building_action_button.disabled = false
	calibrate_button.visible = false
	for building_id: String in GameManager.COLONY_BUILDING_IDS:
		var button: Button = build_buttons[building_id]
		button.disabled = false
		button.visible = true


func _show_first_time_hint() -> void:
	if GameManager.colony_hint_seen:
		return
	GameManager.colony_hint_seen = true
	GameManager.save_meta_progression()
	feedback.text = "Boş platformlara dokunarak kolonini geliştir."
	feedback.add_theme_color_override("font_color", Color(0.55, 1.0, 1.0))
	feedback.modulate.a = 1.0
	feedback.visible = true
	var tween := create_tween()
	tween.tween_interval(2.7)
	tween.tween_property(feedback, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func():
		feedback.visible = false
		feedback.modulate.a = 1.0
	)
func _show_feedback(text: String, error := false) -> void:
	feedback.text = text
	feedback.add_theme_color_override("font_color", Color(1.0, 0.36, 0.28) if error else Color(0.45, 1.0, 1.0))
	feedback.visible = true
	feedback_timer.start()

func _slot_style(_active: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color.TRANSPARENT
	s.border_color = Color.TRANSPARENT
	s.set_border_width_all(0)
	s.set_corner_radius_all(0)
	return s

func _panel_style(theme_color: Color = Color(0.24, 0.94, 0.88, 0.96)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.008, 0.022, 0.052, 0.94)
	s.border_color = theme_color
	s.set_border_width_all(2)
	s.set_corner_radius_all(16)
	s.shadow_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.34)
	s.shadow_size = 10
	return s

func _back() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main.tscn")

func _unhandled_input(event: InputEvent) -> void:
	# COLONY DEBUG - REMOVE BEFORE RELEASE
	if (
		OS.is_debug_build()
		and not OS.has_feature("mobile")
		and event is InputEventKey
	):
		var key_event := event as InputEventKey
		if (
			key_event.pressed
			and not key_event.echo
			and key_event.shift_pressed
			and (key_event.keycode == KEY_P or key_event.physical_keycode == KEY_P)
		):
			GameManager.add_salvage(100)
			parts.text = "PARÇA: %d" % GameManager.total_salvage
			_show_feedback("+100 PARÇA")
			get_viewport().set_input_as_handled()
			return
		if (
			key_event.pressed
			and not key_event.echo
			and key_event.shift_pressed
			and (key_event.keycode == KEY_R or key_event.physical_keycode == KEY_R)
		):
			GameManager.debug_reset_colony_building_progression()
			_close_popup()
			_refresh()
			_layout()
			_show_feedback("KOLONİ BİNALARI SIFIRLANDI")
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel"):
		if build_panel.visible:
			_close_popup()
		else:
			_back()
