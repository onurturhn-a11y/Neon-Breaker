extends Control


const MINI_CARD_SIZE := Vector2(64.0, 76.0)
const PLASMA_TEXTURE := preload("res://assets/cards/plasma_card.png")
const BALL_TEXTURE := preload("res://assets/cards/ball_card.png")

@onready var upgrade_list: GridContainer = $UpgradeList

var entries: Dictionary = {}
var displayed_levels: Dictionary = {}
var displayed_states: Dictionary = {}


func refresh_from_run_state(animate_changes: bool = true) -> void:
	var upgrades: Array[Dictionary] = [
		_make_upgrade(
			&"plasma", GameManager.get_weapon_level(GameManager.WEAPON_PLASMA), PLASMA_TEXTURE, Rect2(0, 0, 768, 610),
			"Lv.%d", _plasma_display_text(), GameManager.plasma_evolution
		),
		_make_upgrade(&"pierce", GameManager.pierce_level, BALL_TEXTURE, Rect2(0, 0, 768, 610)),
		_make_upgrade(
			&"fireball", GameManager.fireball_level, BALL_TEXTURE, Rect2(0, 0, 768, 610),
			"Lv.%d", _fireball_display_text(), GameManager.fireball_evolution
		),
	]
	# Pasif kartlar da build ozetinde gorunsun.
	for card_id: StringName in CardPool.get_ids():
		if CardPool.is_weapon(card_id):
			continue
		var passive_level: int = GameManager.get_card_level(card_id)
		if passive_level <= 0:
			continue
		var icon := _get_passive_icon(card_id)
		if icon == null:
			continue
		upgrades.append(_make_upgrade(
			card_id, passive_level, icon, Rect2(Vector2.ZERO, icon.get_size())
		))
	var active_ids: Array[StringName] = []

	for upgrade in upgrades:
		var upgrade_id: StringName = upgrade.id
		var level: int = upgrade.level
		if level <= 0:
			continue

		active_ids.append(upgrade_id)
		if not entries.has(upgrade_id):
			_add_entry(upgrade, animate_changes)
		elif (
			displayed_levels.get(upgrade_id, -1) != level
			or displayed_states.get(upgrade_id, &"none") != upgrade.state
		):
			_update_entry(
				upgrade_id, level, upgrade.level_format,
				upgrade.display_text, upgrade.state, animate_changes
			)

	for upgrade_id in entries.keys():
		if upgrade_id not in active_ids:
			var entry: Control = entries[upgrade_id]
			entry.queue_free()
			entries.erase(upgrade_id)
			displayed_levels.erase(upgrade_id)
			displayed_states.erase(upgrade_id)

	visible = not entries.is_empty()


var passive_icon_cache: Dictionary = {}


func _get_passive_icon(card_id: StringName) -> Texture2D:
	if passive_icon_cache.has(card_id):
		return passive_icon_cache[card_id]
	var path := CardPool.get_icon_path(card_id)
	var texture: Texture2D = null
	if path != "" and ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	passive_icon_cache[card_id] = texture
	return texture


func _make_upgrade(
	upgrade_id: StringName,
	level: int,
	atlas_texture: Texture2D,
	region: Rect2,
	level_format: String = "Lv.%d",
	display_text: String = "",
	state: StringName = &"none"
) -> Dictionary:
	return {
		"id": upgrade_id,
		"level": level,
		"texture": _make_atlas_texture(atlas_texture, region),
		"level_format": level_format,
		"display_text": display_text,
		"state": state,
	}


func _plasma_display_text() -> String:
	match GameManager.plasma_evolution:
		&"overcharge":
			return "PLASMA\nOVERCHARGE"
		&"ricochet":
			return "PLASMA\nRICOCHET"
	return ""


func _fireball_display_text() -> String:
	match GameManager.fireball_evolution:
		&"inferno":
			return "FIREBALL\nINFERNO"
		&"napalm":
			return "FIREBALL\nNAPALM"
	return ""


func _make_atlas_texture(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas


func _add_entry(upgrade: Dictionary, animate_entry: bool) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(88.0, 72.0) if OS.has_feature("mobile") else MINI_CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _make_card_style())

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 0)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(content)

	var image := TextureRect.new()
	image.custom_minimum_size = Vector2(84.0, 45.0) if OS.has_feature("mobile") else Vector2(60.0, 53.0)
	image.texture = upgrade.texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(image)

	var level_label := Label.new()
	level_label.name = "LevelLabel"
	level_label.custom_minimum_size = Vector2(84.0, 23.0) if OS.has_feature("mobile") else Vector2(60.0, 19.0)
	level_label.text = (
		upgrade.display_text
		if not upgrade.display_text.is_empty()
		else _mobile_level_text(upgrade.id, upgrade.level, upgrade.level_format)
	)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_color_override("font_color", Color("d9f8ff"))
	level_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.12, 0.28, 0.95))
	level_label.add_theme_constant_override("shadow_offset_x", 1)
	level_label.add_theme_constant_override("shadow_offset_y", 1)
	level_label.add_theme_font_size_override("font_size", 10 if OS.has_feature("mobile") else 12)
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(level_label)

	upgrade_list.add_child(card)
	entries[upgrade.id] = card
	displayed_levels[upgrade.id] = upgrade.level
	displayed_states[upgrade.id] = upgrade.state

	if animate_entry:
		call_deferred("_animate_new_entry", card)


func _mobile_level_text(upgrade_id: StringName, level: int, level_format: String) -> String:
	if not OS.has_feature("mobile"):
		return level_format % level
	var roman: String = ["", "I", "II", "III"][clampi(level, 0, 3)]
	match upgrade_id:
		&"plasma": return "PLASMA " + roman
		&"pierce": return "PIERCING " + roman
		&"fireball": return "FIREBALL " + roman
	return level_format % level


func _update_entry(
	upgrade_id: StringName,
	level: int,
	level_format: String,
	display_text: String,
	state: StringName,
	animate_update: bool
) -> void:
	var card: PanelContainer = entries[upgrade_id]
	var level_label: Label = card.get_node("Content/LevelLabel")
	level_label.text = (
		display_text
		if not display_text.is_empty()
		else _mobile_level_text(upgrade_id, level, level_format)
	)
	displayed_levels[upgrade_id] = level
	displayed_states[upgrade_id] = state
	if animate_update:
		call_deferred("_pulse_entry", card)


func _animate_new_entry(card: Control) -> void:
	if not is_instance_valid(card):
		return
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.78, 0.78)
	card.modulate.a = 0.0
	var tween := card.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2.ONE, 0.24)
	tween.tween_property(card, "modulate:a", 1.0, 0.16)


func _pulse_entry(card: Control) -> void:
	if not is_instance_valid(card):
		return
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2.ONE
	var tween := card.create_tween()
	tween.tween_property(card, "scale", Vector2(1.12, 1.12), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func _make_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.055, 0.11, 0.9)
	style.border_color = Color(0.15, 0.82, 1.0, 0.68)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(0.0, 0.65, 1.0, 0.2)
	style.shadow_size = 3
	style.content_margin_left = 2.0
	style.content_margin_top = 2.0
	style.content_margin_right = 2.0
	style.content_margin_bottom = 2.0
	return style
