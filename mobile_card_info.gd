extends Control

# Artwork-facing names only; IDs, effects and level rules remain in CardPool.
const DISPLAY_NAMES := {
	&"fireball": "Ateş Topu", &"pierce": "Delici Top",
	&"plasma": "Plazma Silahı", &"arc_cannon": "Zincir Şimşek",
	&"scatter_cannon": "Saçma Topu", &"railgun": "Ray Silahı",
	&"homing_missile": "Avcı Füzeler", &"pulse_laser": "Darbe Işını",
	&"mortar": "Havan Topu", &"drone_bay": "Saldırı Dronları",
	&"orbital_marker": "Yörünge Saldırısı", &"xp_gain": "XP Takviyesi",
	&"drop_rate": "Ganimet Avcısı", &"magnet_duration": "Güçlü Mıknatıs",
	&"combo_window": "Kombo Ustası", &"crit_hit": "Kritik Vuruş",
	&"salvage_find": "Hurda Avcısı", &"ball_speed": "Hızlı Top",
	&"revive": "İkinci Şans", &"slow_descent": "Yavaş İniş",
}

# Presentation only. Card effects and choice accounting remain in main.gd.
var game: Node
var selected_slot: Button
var info_panel: Panel
var title_label: Label
var description: RichTextLabel
var confirm_button: Button
var hud_suspended := false
var hud_was_visible := false

func configure(owner_game: Node) -> void:
	game = owner_game
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel = Panel.new()
	info_panel.name = "InfoPanel"
	add_child(info_panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.035, 0.065, 0.97)
	style.border_color = Color(0.25, 0.78, 0.90)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	info_panel.add_theme_stylebox_override("panel", style)
	title_label = Label.new()
	title_label.name = "CardName"
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.add_child(title_label)
	description = RichTextLabel.new()
	description.name = "CardDescription"
	description.bbcode_enabled = false
	description.scroll_active = true
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("normal_font_size", 24)
	description.add_theme_color_override("default_color", Color(0.96, 0.98, 1.0))
	info_panel.add_child(description)
	confirm_button = game._make_card_action_button("SEÇ", Color(0.40, 1.0, 0.75))
	confirm_button.name = "ConfirmCard"
	confirm_button.focus_mode = Control.FOCUS_ALL
	confirm_button.add_theme_font_size_override("font_size", 24)
	confirm_button.pressed.connect(_confirm)
	add_child(confirm_button)

func show_hand() -> void:
	visible = not game.visible_cards.is_empty()
	selected_slot = null
	# Reserve the final geometry from the first frame; only fade content in.
	info_panel.show()
	info_panel.modulate.a = 0.0
	title_label.text = ""
	description.text = ""
	confirm_button.show()
	confirm_button.disabled = true
	for card: Button in game.visible_cards:
		card.self_modulate = Color.WHITE
	if not visible:
		return
	if game.get_viewport_rect().size.y > game.get_viewport_rect().size.x:
		if not hud_suspended:
			hud_was_visible = game.get_node("HUD").visible
			hud_suspended = true
		game.get_node("HUD").hide()
		set_process(true)
	layout()

func _process(_delta: float) -> void:
	# Keep the HUD hidden across deferred hand transitions and reward queues.
	# Restore only once the existing coordinator has actually resumed play.
	if not hud_suspended:
		set_process(false)
		return
	if game.choosing_card or GameManager.pending_card_choices > 0 or get_tree().paused:
		game.get_node("HUD").hide()
		return
	if game.game_over or game.main_menu.visible:
		return
	game.get_node("HUD").visible = hud_was_visible
	hud_suspended = false
	set_process(false)

func layout() -> void:
	if not is_instance_valid(game) or not is_instance_valid(confirm_button):
		return
	if game.visible_cards.is_empty():
		return
	var safe: Rect2 = GameManager.get_layout_safe_rect(game.get_viewport_rect().size)
	var margin := 16.0
	var width := safe.size.x - margin * 2.0
	var portrait := safe.size.y > safe.size.x
	var gap := maxf(12.0, width * 0.024)
	var text_width := width - 32.0
	# Fixed text slots: changing the selected card must not move the stack.
	var title_height := title_label.get_theme_font("font").get_height(32)
	var font := description.get_theme_font("normal_font")
	var line_height := font.get_height(24)
	var description_height := line_height * 2.0
	var panel_height := 30.0 + title_height + description_height
	# Reserve space for the expanded information even before focus so cards
	# do not jump/shrink under a finger when their preview opens.
	var reserved_panel_height := 30.0 + title_label.get_theme_font("font").get_height(32) * 2.0 + line_height * 2.0
	var top_space := 24.0 if portrait else 100.0
	var columns := 2 if portrait else 3
	var rows := 2 if portrait else 1
	var card_width := minf((width - gap * (columns - 1)) / columns, maxf(48.0, (safe.size.y - top_space - reserved_panel_height - 158.0 - gap * (rows - 1)) / rows) / 1.5)
	var card_height := card_width * 1.5
	var row_width := card_width * columns + gap * (columns - 1)
	var row_origin := Vector2(safe.position.x + (safe.size.x - row_width) * 0.5, safe.position.y + top_space)
	if portrait:
		var block_height := card_height * rows + gap * (rows - 1) + 12.0 + 52.0
		block_height += panel_height + 10.0 + 56.0 + 10.0
		# Center the whole visible stack inside the safe rectangle, with a
		# slight upward optical bias rather than centering on the raw screen.
		row_origin.y = safe.position.y + maxf(0.0, safe.size.y - block_height) * 0.45
	for i in range(game.visible_cards.size()):
		var slot: Button = game.visible_cards[i]
		slot.position = row_origin + Vector2(i * (card_width + gap), 0)
		if portrait and i == 2:
			slot.position = Vector2(safe.get_center().x - card_width * 0.5, row_origin.y + card_height + gap)
		slot.size = Vector2(card_width, card_height)
		slot.pivot_offset = slot.size * 0.5
		slot.focus_mode = Control.FOCUS_ALL
		game._configure_full_card_art(slot, Rect2(Vector2(4, 4), slot.size - Vector2(8, 8)))
		slot.focus_neighbor_bottom = slot.get_path_to(confirm_button)
		# Explicit navigation follows the visual 2+1 order, including Tab.
		var next_control: Control = game.visible_cards[i + 1] if i + 1 < game.visible_cards.size() else confirm_button
		slot.focus_next = slot.get_path_to(next_control)
		if portrait and game.visible_cards.size() == 3:
			slot.focus_neighbor_bottom = slot.get_path_to(game.visible_cards[2] if i < 2 else confirm_button)
			slot.focus_neighbor_left = slot.get_path_to(game.visible_cards[0])
			slot.focus_neighbor_right = slot.get_path_to(game.visible_cards[1])
			slot.focus_neighbor_top = slot.get_path_to(game.visible_cards[0] if i == 2 else slot)
	if is_instance_valid(game.card_slot_state_label):
		game.card_slot_state_panel.visible = not portrait
		# The label is container-managed: move its panel, not the label itself.
		game._set_mobile_rect(game.card_slot_state_panel, Rect2(safe.position + Vector2(margin, 12), Vector2(width, 76)))
		game.card_slot_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		game.card_slot_state_label.add_theme_font_size_override("font_size", 18)
	var panel_y := row_origin.y + card_height * rows + gap * (rows - 1) + 12.0
	var confirm_y := panel_y + panel_height + 10.0
	var actions_y := confirm_y + 56.0 + 10.0
	game._set_mobile_rect(info_panel, Rect2(safe.position.x + margin, panel_y, width, panel_height))
	game._set_mobile_rect(title_label, Rect2(16, 12, text_width, title_height))
	game._set_mobile_rect(description, Rect2(16, 18 + title_height, text_width, description_height))
	game._set_mobile_rect(confirm_button, Rect2(safe.position.x + margin, confirm_y, width, 56))
	var action_width := (width - 12.0) * 0.5
	game._set_mobile_rect(game.reroll_button, Rect2(safe.position.x + margin, actions_y, action_width, 52))
	game._set_mobile_rect(game.banish_button, Rect2(safe.position.x + margin + action_width + 12.0, actions_y, action_width, 52))
	for button in [game.reroll_button, game.banish_button]:
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 18)
		button.focus_neighbor_top = button.get_path_to(confirm_button if is_instance_valid(selected_slot) else game.visible_cards.back())
	confirm_button.focus_neighbor_bottom = confirm_button.get_path_to(game.reroll_button)
	game.reroll_button.focus_neighbor_right = game.reroll_button.get_path_to(game.banish_button)
	game.banish_button.focus_neighbor_left = game.banish_button.get_path_to(game.reroll_button)
	refresh_action()

func preview(slot: Button) -> void:
	if not game.choosing_card or game.card_selection_committing or slot not in game.visible_cards:
		return
	selected_slot = slot
	var id: StringName = game._get_slot_card_id(slot)
	var current := CardPool.get_display_level(GameManager, id)
	var next := mini(current + 1, CardPool.get_max_level(id))
	title_label.text = DISPLAY_NAMES.get(id, CardPool.get_title(id))
	info_panel.show()
	info_panel.modulate.a = 1.0
	confirm_button.show()
	description.text = CardPool.get_description(id, next)
	description.scroll_to_line(0)
	for card: Button in game.visible_cards:
		card.self_modulate = Color.WHITE if card == slot else Color(0.70, 0.75, 0.82)
	confirm_button.focus_neighbor_top = confirm_button.get_path_to(slot)
	layout()

func refresh_action() -> void:
	confirm_button.text = "YOK ET" if game.banish_arm_active else "SEÇ"
	confirm_button.disabled = not is_instance_valid(selected_slot) or not game.choosing_card or game.card_selection_committing

func _confirm() -> void:
	if confirm_button.disabled or selected_slot not in game.visible_cards:
		return
	confirm_button.disabled = true
	await game._on_card_slot_pressed(selected_slot, true)
	refresh_action()
