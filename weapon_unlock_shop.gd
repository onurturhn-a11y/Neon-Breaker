extends CanvasLayer
const CATALOG = preload("res://weapons/weapon_unlock_prices.gd")
const BUTTON_ART = preload("res://assets/ui/buttons/weapons_button.png")
# Shop-only artwork. These two filenames intentionally cross the weapon IDs.
const WEAPON_ART := {
	&"plasma": "res://assets/cards/plazma.png",
	&"arc_cannon": "res://assets/cards/scatter.png",
	&"scatter_cannon": "res://assets/cards/arc_cannon.png",
	&"railgun": "res://assets/cards/railgun.png",
	&"homing_missile": "res://assets/cards/homing.png",
	&"pulse_laser": "res://assets/cards/pulse.png",
	&"mortar": "res://assets/cards/mortar.png",
	&"drone_bay": "res://assets/cards/drone_bay.png",
	&"orbital_marker": "res://assets/cards/orbital.png",
}
var game: Node
var menu: CanvasLayer
var menu_button: Button
var panel: PanelContainer
var grid: GridContainer
var coin_label: Label
var feedback: Label
var back: Button
var entries: Dictionary = {}
var locked_material: ShaderMaterial

class LockMark extends Control:
	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c, 30.0, Color(0.01,0.025,0.04,0.9))
		draw_arc(c + Vector2(0,-6), 12, PI, TAU, 20, Color(0.7,0.92,1), 4,true)
		draw_rect(Rect2(c + Vector2(-17,-6),Vector2(34,26)),Color(0.7,0.92,1))
		draw_circle(c + Vector2(0,4),3,Color(0.03,0.07,0.1))
		draw_line(c + Vector2(0,5),c + Vector2(0,12),Color(0.03,0.07,0.1),3)

func _ready() -> void:
	game = get_parent()
	menu = game.get_node("MainMenu")
	layer = 55
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_create_menu_button()
	_build_screen()
	panel.resized.connect(_deferred_layout)
	panel.minimum_size_changed.connect(_deferred_layout)
	hide()
	GameManager.total_coins_changed.connect(_on_coins_changed)
	get_viewport().size_changed.connect(_deferred_layout)
	call_deferred("_layout")

func _create_menu_button() -> void:
	var box := menu.get_node("VBoxContainer") as VBoxContainer
	menu_button = Button.new()
	menu_button.name = "WeaponsButton"
	menu_button.tooltip_text = "Silahlar — kalıcı hesap seviyeleri"
	menu_button.custom_minimum_size = Vector2(320,84)
	menu_button.flat = true
	for state in ["normal","hover","pressed","focus","disabled"]:
		menu_button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	box.add_child(menu_button)
	box.move_child(menu_button,box.get_node("ShopButton").get_index()+1)
	var art := TextureRect.new()
	art.name = "Artwork"
	art.texture = BUTTON_ART
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_button.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_button.mouse_entered.connect(func(): art.modulate = Color(1.15,1.15,1.15))
	menu_button.mouse_exited.connect(func(): art.modulate = Color.WHITE)
	menu_button.focus_entered.connect(func(): art.modulate = Color(1.15,1.15,1.15))
	menu_button.focus_exited.connect(func(): art.modulate = Color.WHITE)
	menu_button.pressed.connect(open_shop)

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color(0.86,0.96,1))
	return label

func _build_screen() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.006,0.018,0.035,0.98)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	panel.name = "WeaponPanel"
	add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018,0.04,0.075)
	style.border_color = Color(0.1,0.65,0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel",style)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",8)
	panel.add_child(layout)
	layout.add_child(_label("SİLAHLAR",30))
	coin_label = _label("",22)
	coin_label.add_theme_color_override("font_color",Color(1,0.78,0.18))
	layout.add_child(coin_label)
	var note := _label("Kalıcı hesap seviyeleri • Silahlar run içinde kartla alınır.",16)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(note)
	var scroll := ScrollContainer.new()
	scroll.name = "WeaponScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.scroll_deadzone = 12
	layout.add_child(scroll)
	grid = GridContainer.new()
	grid.name = "Weapons"
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	scroll.add_child(grid)
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float g=dot(c.rgb,vec3(0.299,0.587,0.114)); COLOR=vec4(mix(vec3(g),c.rgb,0.08)*0.30,c.a); }"
	locked_material = ShaderMaterial.new()
	locked_material.shader = shader
	for id: StringName in CATALOG.PRICES:
		_create_entry(id)
	feedback = _label("",16)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.custom_minimum_size.y = 24
	layout.add_child(feedback)
	back = Button.new()
	back.text = "GERİ"
	back.custom_minimum_size.y = 48
	back.add_theme_font_size_override("font_size",20)
	back.pressed.connect(close_shop)
	layout.add_child(back)

func _create_entry(id: StringName) -> void:
	var card := PanelContainer.new()
	card.name = String(id)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025,0.065,0.10)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel",style)
	grid.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation",6)
	card.add_child(col)
	var art_slot := Control.new()
	art_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_slot.custom_minimum_size.y = 210
	col.add_child(art_slot)
	var art := TextureRect.new()
	art.texture = load(WEAPON_ART[id])
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_slot.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var lock := LockMark.new()
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_slot.add_child(lock)
	lock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title := _label(CATALOG.TITLES[id],20)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.y = 52
	col.add_child(title)
	var buttons: Array[Button] = []
	for level in range(1,4):
		var button := Button.new()
		# Let native ScrollContainer dragging cancel the press after its deadzone.
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.custom_minimum_size.y = 46
		button.add_theme_font_size_override("font_size",18)
		button.pressed.connect(_purchase.bind(id,level))
		col.add_child(button)
		buttons.append(button)
	entries[id] = {"art":art,"lock":lock,"buttons":buttons,"title":title,"art_slot":art_slot}

func refresh() -> void:
	coin_label.text = "%d COIN" % GameManager.total_coins
	for id: StringName in entries:
		var entry: Dictionary = entries[id]
		var maximum := GameManager.get_card_unlock_level(id)
		entry.art.material = locked_material if maximum == 0 else null
		entry.lock.visible = maximum == 0
		for level in range(1,4):
			var button: Button = entry.buttons[level-1]
			var price := CATALOG.get_price(id,level)
			if level <= maximum:
				button.text = "LV%d  ✓" % level
				button.disabled = true
				button.tooltip_text = "Hesabında açık"
			elif level != maximum + 1:
				button.text = "LV%d  — KİLİTLİ" % level
				button.disabled = true
				button.tooltip_text = "Önce LV%d açılmalı" % (level-1)
			else:
				button.text = "LV%d — %d COIN" % [level,price]
				button.disabled = not GameManager.can_purchase_weapon_level(id,level)
				button.tooltip_text = "Yetersiz Coin / kayıt kullanılamıyor" if button.disabled else "Kalıcı seviyeyi aç"

func _purchase(id: StringName, level: int) -> void:
	var purchased := GameManager.purchase_weapon_level(id,level)
	feedback.text = "%s LV%d AÇILDI" % [CATALOG.TITLES[id],level] if purchased else "Satın alınamadı. Coin ve seviye koşullarını kontrol et."
	refresh()

func _on_coins_changed(_total: int) -> void:
	if visible: refresh()

func open_shop() -> void:
	if not menu.visible: return
	menu.hide()
	game._refresh_coin_debug_visibility()
	feedback.text = ""
	refresh()
	show()
	_layout()
	back.grab_focus()

func close_shop() -> void:
	hide()
	menu.show()
	game._refresh_coin_debug_visibility()
	menu_button.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_shop()
	# This modal owns unhandled keys; do not trigger gameplay/debug keys below it.
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_shop()
		get_viewport().set_input_as_handled()

func _deferred_layout() -> void:
	call_deferred("_layout")

func _layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var safe := GameManager.get_layout_safe_rect(viewport_size)
	var portrait := viewport_size.y > viewport_size.x
	var ui_scale := clampf(safe.size.x / 720.0, 1.0, 2.0) if portrait else 1.0
	var width := safe.size.x-32*ui_scale if portrait else minf(1120.0,safe.size.x-32)
	var height := safe.size.y-64*ui_scale
	panel.position = safe.position + (safe.size-Vector2(width,height))*0.5
	panel.size = Vector2(width,height)
	grid.columns = (1 if width < 580*ui_scale else 2) if portrait else (2 if width < 960 else 3)
	var layout := panel.get_child(0) as VBoxContainer
	(layout.get_child(0) as Label).add_theme_font_size_override("font_size",roundi(30*ui_scale))
	(layout.get_child(2) as Label).add_theme_font_size_override("font_size",roundi(16*ui_scale))
	coin_label.add_theme_font_size_override("font_size",roundi(22*ui_scale))
	feedback.add_theme_font_size_override("font_size",roundi(16*ui_scale))
	feedback.custom_minimum_size.y = 44*ui_scale
	back.custom_minimum_size.y = 48*ui_scale
	back.add_theme_font_size_override("font_size",roundi(20*ui_scale))
	for entry: Dictionary in entries.values():
		entry.art_slot.custom_minimum_size.y = 210*ui_scale if portrait else clampf(height-466.0,96.0,210.0)
		entry.title.custom_minimum_size.y = 52*ui_scale
		entry.title.add_theme_font_size_override("font_size",roundi(20*ui_scale))
		entry.lock.queue_redraw()
		for button: Button in entry.buttons:
			button.custom_minimum_size.y = 46*ui_scale
			button.add_theme_font_size_override("font_size",roundi(18*ui_scale))
	# Fit the six-button menu as one group; preserve each artwork's aspect ratio.
	var box := menu.get_node("VBoxContainer") as VBoxContainer
	if not OS.has_feature("mobile"):
		box.scale = Vector2.ONE
		var minimum := box.get_combined_minimum_size()
		var fit := minf(1.0,(safe.size.y-112.0)/maxf(minimum.y,1.0))
		box.scale = Vector2.ONE * fit
		box.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		box.size = minimum
		box.position = safe.position + (safe.size-minimum*fit)*0.5
