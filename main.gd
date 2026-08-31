extends Node2D


const MENU_BACKGROUND_TEXTURE: Texture2D = preload("res://assets/menu/menu_background.png")
const MENU_LOGO_TEXTURE: Texture2D = preload("res://assets/menu/neon_break_logo.png")
const MENU_NEW_GAME_TEXTURE: Texture2D = preload("res://assets/menu/new_game_button.png")
const MENU_SHOP_TEXTURE: Texture2D = preload("res://assets/menu/shop_button.png")
const MENU_MUSIC_ON_TEXTURE: Texture2D = preload("res://assets/menu/music_button.png")
const MENU_MUSIC_OFF_TEXTURE: Texture2D = preload("res://assets/menu/music_off_button.png")
const MENU_QUIT_TEXTURE: Texture2D = preload("res://assets/menu/quit_button.png")
const MENU_COLONY_TEXTURE: Texture2D = preload("res://assets/ui/buttons/colony_button.png")
const MENU_COLONY_VISIBLE_REGION := Rect2(120.0, 96.0, 1772.0, 556.0)
# Codex silah kontrolcüleri
const ARC_CANNON_CONTROLLER_SCRIPT := preload("res://arc_cannon_controller.gd")
const SCATTER_CANNON_CONTROLLER_SCRIPT := preload("res://scatter_cannon_controller.gd")
const RAILGUN_CONTROLLER_SCRIPT := preload("res://railgun_controller.gd")
const HOMING_MISSILE_CONTROLLER_SCRIPT := preload("res://homing_missile_controller.gd")
const PULSE_LASER_CONTROLLER_SCRIPT := preload("res://pulse_laser_controller.gd")


var bricks_left = 0
var game_over = false

var choosing_card = false

var ball_scene = preload("res://ball.tscn")
var xp_orb_scene = preload("res://exp_orb.tscn")
var heart_pickup_scene = preload("res://heart_pickup.tscn")
var magnet_pickup_scene = preload("res://magnet_pickup.tscn")
var coin_pickup_scene = preload("res://coin_pickup.tscn")
var building_part_pickup_scene = preload("res://building_part_pickup.tscn")
var temporary_power_pickup_scene = preload("res://temporary_power_pickup.tscn")
var desktop_gameplay_camera: Camera2D
var brick_field_scene = preload("res://continuous_brick_field.gd")
const FIREBALL_BASE_RADII := [0.0, 70.0, 95.0, 125.0]
const FIREBALL_RADIUS_MULTIPLIERS := [1.0, 0.80, 0.83, 0.85]
var boss_core_scene = preload("res://boss_core.tscn")
var boss_sentinel_scene = preload("res://boss_sentinel.tscn")
var boss_celestial_scene = preload("res://boss_celestial.tscn")
var boss_void_scene = preload("res://boss_void.tscn")
var boss_void_sovereign_scene = preload("res://boss_void_sovereign.tscn")
var boss_void_architect_scene = preload("res://boss_void_architect.tscn")
var boss_chronoform_scene = preload("res://boss_chronoform.tscn")
var napalm_field_scene = preload("res://napalm_field.tscn")
var brick_field
var active_boss: Node
var boss_active := false
var boss_pending := false
var first_boss_defeated := false
var second_boss_defeated := false
var third_boss_defeated := false
var fourth_boss_defeated := false
var fifth_boss_defeated := false
var sixth_boss_defeated := false
var seventh_boss_defeated := false
var pending_boss_type: StringName = &"none"
var active_boss_type: StringName = &"none"
var active_boss_is_progression := false
var boss_warning_running := false

const FIRST_BOSS_MILESTONE_DEPTH := 8
const FIRST_POST_BOSS_DEPTH := 9
const SECOND_BOSS_MILESTONE_DEPTH := 16
const SECOND_POST_BOSS_DEPTH := 17
const THIRD_BOSS_MILESTONE_DEPTH := 24
const THIRD_POST_BOSS_DEPTH := 25
const FOURTH_BOSS_MILESTONE_DEPTH := 32
const FOURTH_POST_BOSS_DEPTH := 33
const FIFTH_BOSS_MILESTONE_DEPTH := 40
const FIFTH_POST_BOSS_DEPTH := 41
const SIXTH_BOSS_MILESTONE_DEPTH := 48
const SIXTH_POST_BOSS_DEPTH := 49
const SEVENTH_BOSS_MILESTONE_DEPTH := 56
const SEVENTH_POST_BOSS_DEPTH := 57
const MOBILE_PORTRAIT_REFERENCE := Vector2i(648, 1152)
const MOBILE_CARD_SIZE := Vector2(236.0, 310.0)
const PIERCING_CARD_TEXTURE: Texture2D = preload("res://assets/cards/piercing_card.png")
const SHOP_NEUTRAL_PADDLE_TEXTURE: Texture2D = preload("res://assets/paddles/paddle_blue.png")
const SHOP_PLASMA_PADDLE_TEXTURE: Texture2D = preload("res://assets/paddles/plasma_paddle.png")
const SHOP_PIERCING_PADDLE_TEXTURE: Texture2D = preload("res://assets/paddles/piercing_paddle.png")
const SHOP_FIRE_PADDLE_TEXTURE: Texture2D = preload("res://assets/paddles/fireball_paddle.png")
const SHOP_NEON_CORE_PADDLE_TEXTURE: Texture2D = preload("res://assets/paddles/neon_core/paddle_body.png")

# Ödül ve rekor ikonları. Hepsi beyaz/şeffaf SVG; renk modulate ile veriliyor.
const ICON_SALVAGE: Texture2D = preload("res://assets/items/icons/cog.svg")
const ICON_COIN: Texture2D = preload("res://assets/items/icons/two-coins.svg")
const ICON_LIFE: Texture2D = preload("res://assets/items/icons/hearts.svg")
const ICON_WIDE_PADDLE: Texture2D = preload("res://assets/items/icons/horizontal-flip.svg")
const ICON_EXTRA_BALL: Texture2D = preload("res://assets/items/icons/striking-balls.svg")
const ICON_TROPHY: Texture2D = preload("res://assets/items/icons/trophy.svg")
const ICON_DEPTH: Texture2D = preload("res://assets/items/icons/stairs.svg")
const SFX_BOSS_REWARD: AudioStream = preload("res://assets/audio/sfx/ui/boss_reward.wav")
const SFX_BONUS_REWARD: AudioStream = preload("res://assets/audio/sfx/ui/bonus_reward.wav")
const SFX_NEW_RECORD: AudioStream = preload("res://assets/audio/sfx/ui/new_record.wav")

@export_range(0.0, 1.0, 0.01) var exp_orb_drop_chance = 0.20
@export_range(0.0, 1.0, 0.005) var heart_drop_chance = 0.06
@export_range(0.0, 1.0, 0.01) var magnet_drop_chance = 0.03
@export_range(0.0, 1.0, 0.001) var coin_drop_chance = 0.006
@export_range(0.0, 1.0, 0.005) var wide_paddle_pickup_drop_chance = 0.015
## 0.015'ten 0.005'e dusuruldu. Eski deger "+1 gecici top" icindi; artik
## guclendirme sahnedeki topu IKIYE KATLIYOR ve aktifken de dusuyor, yani
## etkisi cok daha buyuk.
##
## Olculdu (zafer run'i, ~5264 tugla, ~400 tuglada bir top kaybi varsayimi):
##   %1.5 -> ort. 3.5 top, run'in %58'i tavanda, ilk katlama 66. tuglada
##   %0.5 -> ort. 2.7 top, run'in %26'si tavanda, ilk katlama 203. tuglada
## Ilki guclendirmeyi varsayilan duruma cevirıyordu.
@export_range(0.0, 1.0, 0.005) var extra_ball_pickup_drop_chance = 0.005
const TEMPORARY_PICKUP_DURATION := 12.0
const SIDE_WAVE_DROP_MULTIPLIER := 0.35


# ==================================================
# HUD
# ==================================================

@onready var lives_label = $HUD/Layout/LivesPanel/LivesLabel
@onready var lives_panel = $HUD/Layout/LivesPanel
@onready var xp_bar = $HUD/Layout/XPPanel/XPBar
@onready var level_label = $HUD/Layout/XPPanel/LevelLabel
@onready var xp_label = $HUD/Layout/XPPanel/XPBar/XPValueLabel
@onready var depth_label = $HUD/Layout/DepthLabel
@onready var total_coin_counter: Control = $HUD/Layout/CoinCounter
@onready var total_coin_label: Label = $HUD/Layout/CoinCounter/TotalLabel
@onready var magnet_aura = $Paddle/MagnetAura
@onready var build_hud = $HUD/BuildHUD
@onready var boss_hp_panel: Control = $HUD/BossHP
@onready var boss_hp_bar: ProgressBar = $HUD/BossHP/HPBar
@onready var boss_name_label: Label = $HUD/BossHP/BossName
@onready var boss_warning: Control = $HUD/BossWarning
@onready var boss_warning_label: Label = $HUD/BossWarning/WarningLabel


# ==================================================
# ANA MENÃƒÆ’Ã…â€œ
# ==================================================

@onready var main_menu = $MainMenu

@onready var new_game_button = (
	$MainMenu/VBoxContainer/NewGameButton
)

@onready var shop_button: Button = $MainMenu/VBoxContainer/ShopButton
@onready var colony_button: Button = $MainMenu/VBoxContainer/ColonyButton
@onready var music_button: Button = $MainMenu/VBoxContainer/MusicButton
@onready var quit_button = (
	$MainMenu/VBoxContainer/QuitButton
)
@onready var menu_version_label: Label = $MainMenu/VersionLabel
@onready var music_controller: Node = $HUD/Layout/LivesPanel/LivesLabel
@onready var pause_button: Button = $HUD/PauseButton
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var pause_panel: Control = $PauseMenu/Panel
@onready var pause_resume_button: Button = $PauseMenu/Panel/VBoxContainer/ResumeButton
@onready var pause_main_menu_button: Button = $PauseMenu/Panel/VBoxContainer/MainMenuButton
@onready var sector_transition: Control = $HUD/SectorTransition
@onready var sector_label: Label = $HUD/SectorTransition/SectorLabel
@onready var sector_threat_label: Label = $HUD/SectorTransition/ThreatLabel
@onready var space_nebula_background: TextureRect = $BackgroundLayer/SpaceNebulaBackground
@onready var animated_starfield: Node2D = $BackgroundLayer/AnimatedStarfield




# ==================================================
# GAME OVER
# ==================================================

@onready var game_over_screen = $GameOverScreen
@onready var run_summary_stats_label: Label = $GameOverScreen/VBoxContainer/StatsLabel
@onready var run_summary_build_label: Label = $GameOverScreen/VBoxContainer/FinalBuildLabel

@onready var retry_button = (
	$GameOverScreen/VBoxContainer/RetryButton
)

@onready var main_menu_button = (
	$GameOverScreen/VBoxContainer/MainMenuButton
)


# ==================================================
# KARTLAR
# ==================================================

@onready var card_screen = $CardScreen
@onready var card_panel = $CardScreen/CardPanel

@onready var plasma_card = (
	$CardScreen/CardPanel/PlasmaCard
)

@onready var pierce_card = (
	$CardScreen/CardPanel/PierceCard
)

@onready var fireball_card = $CardScreen/CardPanel/FireballCard

@onready var card_move_sfx: AudioStreamPlayer = $CardScreen/CardMoveSFX
@onready var card_select_sfx: AudioStreamPlayer = $CardScreen/CardSelectSFX
@onready var evolution_screen: CanvasLayer = $EvolutionScreen
@onready var evolution_panel: Control = $EvolutionScreen/Panel
@onready var overcharge_card: Button = $EvolutionScreen/Panel/OverchargeCard
@onready var ricochet_card: Button = $EvolutionScreen/Panel/RicochetCard
@onready var evolution_subtitle: Label = $EvolutionScreen/Panel/Subtitle
@onready var evolution_left_title: Label = $EvolutionScreen/Panel/OverchargeCard/Title
@onready var evolution_left_description: Label = $EvolutionScreen/Panel/OverchargeCard/Description
@onready var evolution_left_image: TextureRect = $EvolutionScreen/Panel/OverchargeCard/CardImage
@onready var evolution_right_title: Label = $EvolutionScreen/Panel/RicochetCard/Title
@onready var evolution_right_description: Label = $EvolutionScreen/Panel/RicochetCard/Description
@onready var evolution_right_image: TextureRect = $EvolutionScreen/Panel/RicochetCard/CardImage


@onready var paddle = $Paddle


var visible_cards = []
var slot_card_ids: Array = []
var card_icon_cache: Dictionary = {}
var reroll_button: Button
var banish_button: Button
var banish_arm_active := false
const MAX_ACTIVE_BALLS = 4
var xp_bar_value_tween: Tween
var xp_bar_pulse_tween: Tween
var magnet_pulse_time = 0.0
var wide_paddle_pickup_time_remaining := 0.0
## Ekstra top artik sureli degil: katlanan toplar kalici, dogal yoldan
## (rakete carpamayip dusunce) azaliyorlar. Bu yuzden sure/gecici-top
## takibi kaldirildi.
var xp_level_up_sequence_active = false
var card_selection_committing := false
var enemy_projectile_damage_locked = false
var enemy_hit_feedback_tween: Tween
var last_focused_card: Control
var last_card_move_sound_msec := -1000
var card_select_sound_played := false
var evolution_selection_active := false
var pause_menu_active := false
var current_sector := 1
var pending_sector_transition := 0
var sector_transition_playing := false
var sector_transition_tween: Tween
var run_elapsed_seconds := 0.0
var run_bricks_destroyed := 0
var run_destroyed_brick_ids: Dictionary = {}
var highest_combo_rank_index := -1
var run_progression_boss_kills := 0
var run_coins_collected := 0
var run_colony_parts_bonus := 0
var run_boss_salvage_reward := 0
var run_salvage_earned := 0
var run_salvage_rescued := 0
var run_salvage_lost := 0
var run_colony_bonus_awarded := false
var paddle_shop: CanvasLayer
var paddle_shop_panel: Panel
var paddle_shop_coin_label: Label
var paddle_shop_status_label: Label
var paddle_shop_buttons: Dictionary = {}
var paddle_shop_images: Dictionary = {}
var paddle_shop_text_labels: Dictionary = {}
var coin_debug_overlay: CanvasLayer
var coin_debug_button: Button
var sector_background_tween: Tween
var menu_records_label: HBoxContainer
var menu_records_icon: TextureRect
var menu_records_text: Label
var ascension_row: HBoxContainer
var ascension_label: Label
var reward_sfx_player: AudioStreamPlayer
# Codex: silah kontrolcüleri ve PARÇA sayacı
var arc_cannon_controller: Node
var scatter_cannon_controller: Node
var railgun_controller: Node
var homing_missile_controller: Node
var pulse_laser_controller: Node
var building_part_counter: Control
var building_part_label: Label
var colony_button_visual_tween: Tween
var boss_reward_screen: CanvasLayer
var boss_reward_title: Label
var boss_reward_subtitle: Label
var boss_reward_row: HBoxContainer
var boss_reward_buttons: Array[Button] = []
var boss_reward_options: Array = []
var boss_reward_active := false
var run_victory := false
var active_evolution_card: StringName = &"none"
var boss_hp_tween: Tween
var sentinel_left_indicator: Label
var sentinel_right_indicator: Label
var sentinel_shield_indicator: Label
var sentinel_feedback_label: Label
var sentinel_feedback_tween: Tween
var mobile_safe_area_refresh_timer := 0.0
var build_identity_panel: PanelContainer
var build_identity_core_label: Label
var build_identity_slots_label: Label
var card_slot_state_panel: PanelContainer
var card_slot_state_label: Label
var hud_status_toast: Label
var hud_status_toast_tween: Tween
var danger_line_visual: Line2D
var ui_feedback_refresh_left := 0.0
var last_build_identity_signature := ""
var sentinel_hint_shown := false
const CARD_MOVE_SOUND_COOLDOWN_MSEC := 70
const UI_FEEDBACK_REFRESH_INTERVAL := 0.10


# ==================================================
# BAÃƒâ€¦Ã‚ÂLANGIÃƒÆ’Ã¢â‚¬Â¡
# ==================================================

func _enter_tree() -> void:
	if OS.has_feature("mobile"):
		GameManager.PLAYFIELD_TOP = 190.0
		var game_window := get_window()
		game_window.content_scale_size = MOBILE_PORTRAIT_REFERENCE
		game_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		game_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	else:
		GameManager.PLAYFIELD_TOP = 62.0


func _set_mobile_rect(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size


func _is_full_card_art(_card: Button) -> bool:
	# Her slot artik havuzdaki herhangi bir karti gosterebildigi icin
	# tum slotlar ayni standart yerlesimi kullanir.
	return false


func _configure_full_card_art(card: Button, image_rect: Rect2) -> void:
	var image := card.get_node_or_null("CardImage") as TextureRect
	if is_instance_valid(image):
		image.visible = true
		image.texture = PIERCING_CARD_TEXTURE
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_set_mobile_rect(image, image_rect)

	var title_panel := card.get_node_or_null("TitlePanel") as Control
	if is_instance_valid(title_panel):
		title_panel.visible = false
	var description := card.get_node_or_null("Description") as Label
	if is_instance_valid(description):
		description.visible = false
	var piercing_icon := card.get_node_or_null("PiercingIcon") as Control
	if is_instance_valid(piercing_icon):
		piercing_icon.visible = false

func _configure_mobile_card_visual(card: Button) -> void:
	card.size = MOBILE_CARD_SIZE
	if _is_full_card_art(card):
		_configure_full_card_art(card, Rect2(4, 4, MOBILE_CARD_SIZE.x - 8.0, MOBILE_CARD_SIZE.y - 8.0))
		return
	var image := card.get_node_or_null("CardImage") as Control
	if is_instance_valid(image):
		_set_mobile_rect(image, Rect2(6, 6, MOBILE_CARD_SIZE.x - 12.0, 176.0))
	var title_panel := card.get_node_or_null("TitlePanel") as Control
	if is_instance_valid(title_panel):
		_set_mobile_rect(title_panel, Rect2(6, 184, MOBILE_CARD_SIZE.x - 12.0, 43.0))
		var title := title_panel.get_node_or_null("Title") as Label
		if is_instance_valid(title):
			title.add_theme_font_size_override("font_size", 19)
	var description := card.get_node_or_null("Description") as Label
	if is_instance_valid(description):
		_set_mobile_rect(description, Rect2(13, 232, MOBILE_CARD_SIZE.x - 26.0, 68.0))
		_fit_card_description(description, 13, 11)


func _setup_card_presentation() -> void:
	for card in [plasma_card, pierce_card, fireball_card]:
		if _is_full_card_art(card):
			_configure_full_card_art(card, Rect2(4, 4, card.size.x - 8.0, card.size.y - 8.0))
			continue
		var image := card.get_node_or_null("CardImage") as Control
		if is_instance_valid(image):
			_set_mobile_rect(image, Rect2(5, 5, 206, 166))
		var title_panel := card.get_node_or_null("TitlePanel") as Control
		if is_instance_valid(title_panel):
			_set_mobile_rect(title_panel, Rect2(5, 174, 206, 42))
			var title := title_panel.get_node_or_null("Title") as Label
			if is_instance_valid(title):
				title.add_theme_font_size_override("font_size", 16)
		var description := card.get_node_or_null("Description") as Label
		if not is_instance_valid(description):
			description = Label.new()
			description.name = "Description"
			description.mouse_filter = Control.MOUSE_FILTER_IGNORE
			description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			description.add_theme_color_override("font_color", Color(0.78, 0.84, 0.94, 1.0))
			card.add_child(description)
		description.clip_text = true
		_set_mobile_rect(description, Rect2(11, 219, 194, 59))
		_fit_card_description(description, 11, 9)

	# Evolution aÃƒÆ’Ã‚Â§Ãƒâ€Ã‚Â±klamalarÃƒâ€Ã‚Â± iki platformda da gÃƒÆ’Ã‚Â¼venli biÃƒÆ’Ã‚Â§imde sarÃƒâ€Ã‚Â±lsÃƒâ€Ã‚Â±n.
	for evolution_description in [evolution_left_description, evolution_right_description]:
		evolution_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		evolution_description.clip_text = true
	$EvolutionScreen/Panel/Title.text = "EVR\u0130M"

func _apply_mobile_portrait_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var safe_rect := GameManager.refresh_mobile_safe_area(viewport_size)
	var safe_right := safe_rect.position.x + safe_rect.size.x
	GameManager.PLAYFIELD_TOP = safe_rect.position.y + 190.0
	paddle.global_position.x = safe_rect.position.x + safe_rect.size.x * 0.5
	paddle.velocity.x = 0.0

	# DÃƒÆ’Ã‚Â¼nya sÃƒâ€Ã‚Â±nÃƒâ€Ã‚Â±rÃƒâ€Ã‚Â± ve tam ekran gÃƒÆ’Ã‚Â¶rsel katmanlar.
	$PlayfieldTopWall.position.y = GameManager.PLAYFIELD_TOP - 4.0
	var top_shape := $PlayfieldTopWall/CollisionShape2D as CollisionShape2D
	top_shape.position.x = safe_rect.position.x + safe_rect.size.x * 0.5
	if top_shape.shape is RectangleShape2D:
		(top_shape.shape as RectangleShape2D).size.x = safe_rect.size.x
	for background_path in [
		"BackgroundLayer/Background", "BackgroundLayer/SpaceNebulaBackground", "BackgroundLayer/ProceduralNebula",
		"MainMenu/MenuBackground", "MainMenu/MenuAssetBackground", "GameOverScreen/GameOverBackground"
	]:
		var background := get_node_or_null(background_path) as Control
		if is_instance_valid(background):
			_set_mobile_rect(background, Rect2(Vector2.ZERO, viewport_size))

	# Portrait HUD: iki kompakt ÃƒÆ’Ã‚Â¼st satÃƒâ€Ã‚Â±r ve altÃƒâ€Ã‚Â±nda yatay build grid.
	_set_mobile_rect(lives_panel, Rect2(safe_rect.position + Vector2(12, 12), Vector2(150, 44)))
	var xp_panel := $HUD/Layout/XPPanel as Control
	_set_mobile_rect(xp_panel, Rect2(
		safe_rect.position + Vector2(174, 12),
		Vector2(maxf(safe_rect.size.x - 246.0, 220.0), 52)
	))
	_set_mobile_rect(pause_button, Rect2(safe_right - 60.0, safe_rect.position.y + 12.0, 48.0, 48.0))
	_set_mobile_rect(pause_panel, Rect2(
		safe_rect.position.x + (safe_rect.size.x - 360.0) * 0.5,
		safe_rect.position.y + (safe_rect.size.y - 264.0) * 0.5,
		360.0,
		264.0
	))
	_set_mobile_rect(level_label, Rect2(10, 10, 78, 32))
	_set_mobile_rect(xp_bar, Rect2(92, 11, xp_panel.size.x - 102.0, 30))
	lives_label.add_theme_font_size_override("font_size", 27)
	level_label.add_theme_font_size_override("font_size", 18)
	xp_label.add_theme_font_size_override("font_size", 16)
	xp_bar.pivot_offset = xp_bar.size * 0.5
	lives_panel.pivot_offset = lives_panel.size * 0.5
	_set_mobile_rect(depth_label, Rect2(safe_rect.position + Vector2(12, 66), Vector2(188, 48)))
	depth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	depth_label.add_theme_font_size_override("font_size", 14)
	_set_mobile_rect(total_coin_counter, Rect2(safe_rect.position.x + safe_rect.size.x * 0.5 - 65.0, safe_rect.position.y + 66.0, 130.0, 38.0))
	total_coin_label.add_theme_font_size_override("font_size", 18)


	_set_mobile_rect(build_hud, Rect2(safe_rect.position + Vector2(12, 150), Vector2(safe_rect.size.x - 24.0, 38)))
	var build_title := $HUD/BuildHUD/Title as Control
	_set_mobile_rect(build_title, Rect2(0, 0, 42, 16))
	(build_title as Label).add_theme_font_size_override("font_size", 9)
	var build_list := $HUD/BuildHUD/UpgradeList as GridContainer
	_set_mobile_rect(build_list, Rect2(44, 0, maxf(safe_rect.size.x - 238.0, 260.0), 38))
	build_list.columns = 8
	build_list.add_theme_constant_override("h_separation", 4)
	build_list.add_theme_constant_override("v_separation", 3)

	var combo_rank := $HUD/ComboManager/RankLabel as Control
	_set_mobile_rect(combo_rank, Rect2(safe_right - 170.0, safe_rect.position.y + 112.0, 145, 58))
	_layout_readability_ui()

	_set_mobile_rect(boss_hp_panel, Rect2(safe_rect.position.x + 64.0, GameManager.PLAYFIELD_TOP + 12.0, safe_rect.size.x - 128.0, 54))
	_set_mobile_rect(boss_hp_bar, Rect2(10, 27, boss_hp_panel.size.x - 20.0, 18))
	var sector_width := minf(420.0, safe_rect.size.x - 32.0)
	_set_mobile_rect(sector_transition, Rect2(
		viewport_size.x * 0.5 - sector_width * 0.5,
		viewport_size.y * 0.5 - 56.0,
		sector_width,
		112.0
	))
	sector_label.add_theme_font_size_override("font_size", 34)
	sector_threat_label.add_theme_font_size_override("font_size", 17)
	var warning_label := $HUD/BossWarning/WarningLabel as Control
	_set_mobile_rect(warning_label, Rect2(
		safe_rect.position.x + 14.0,
		safe_rect.position.y + (safe_rect.size.y - 84.0) * 0.5,
		safe_rect.size.x - 28.0,
		84
	))

	# Portrait seÃƒÆ’Ã‚Â§im ekranlarÃƒâ€Ã‚Â±: ÃƒÆ’Ã‚Â¼ÃƒÆ’Ã‚Â§ normal kart 2+1, evolution kartlarÃƒâ€Ã‚Â± iki kolon.
	var evolution_title := $EvolutionScreen/Panel/Title as Control
	var evolution_subtitle_control := $EvolutionScreen/Panel/Subtitle as Control
	_set_mobile_rect(evolution_title, Rect2(safe_rect.position.x + 74.0, safe_rect.position.y + 150.0, safe_rect.size.x - 148.0, 48))
	_set_mobile_rect(evolution_subtitle_control, Rect2(safe_rect.position.x + 54.0, safe_rect.position.y + 202.0, safe_rect.size.x - 108.0, 34))
	_set_mobile_rect(overcharge_card, Rect2(safe_rect.position.x + 54.0, safe_rect.position.y + 286.0, 260, 332))
	_set_mobile_rect(ricochet_card, Rect2(safe_right - 314.0, safe_rect.position.y + 286.0, 260, 332))
	(evolution_title as Label).add_theme_font_size_override("font_size", 38)
	(evolution_subtitle_control as Label).add_theme_font_size_override("font_size", 19)
	for evolution_card in [overcharge_card, ricochet_card]:
		var option_title := evolution_card.get_node("Title") as Label
		var option_description := evolution_card.get_node("Description") as Label
		option_title.add_theme_font_size_override("font_size", 24)
		option_description.add_theme_font_size_override("font_size", 16)

	for mobile_card in [plasma_card, pierce_card, fireball_card]:
		_configure_mobile_card_visual(mobile_card)

	var game_over_box := $GameOverScreen/VBoxContainer as Control
	var summary_width := minf(520.0, safe_rect.size.x - 32.0)
	var summary_height := minf(650.0, safe_rect.size.y - 40.0)
	_set_mobile_rect(game_over_box, Rect2(
		safe_rect.position.x + (safe_rect.size.x - summary_width) * 0.5,
		safe_rect.position.y + (safe_rect.size.y - summary_height) * 0.5,
		summary_width,
		summary_height
	))
	$GameOverScreen/VBoxContainer/GameOverLabel.add_theme_font_size_override("font_size", 34)
	run_summary_stats_label.add_theme_font_size_override("font_size", 18)
	run_summary_build_label.add_theme_font_size_override("font_size", 17)
	var main_menu_box := get_node_or_null("MainMenu/VBoxContainer") as VBoxContainer
	if is_instance_valid(main_menu_box):
		var menu_width := minf(safe_rect.size.x * 0.90, 620.0)
		var button_height := clampf(menu_width * 0.21, 96.0, 122.0)
		var logo_height := clampf(menu_width * 0.42, 190.0, 250.0)
		var menu_height := logo_height + button_height * 5.0 + 60.0
		_set_mobile_rect(main_menu_box, Rect2(
			safe_rect.position.x + (safe_rect.size.x - menu_width) * 0.5,
			safe_rect.position.y + (safe_rect.size.y - menu_height) * 0.5,
			menu_width,
			menu_height
		))
		# YATAY ORTALAMA safe_rect'e GUVENMEZ.
		#
		# Cihazda menu sola dayali cikiyordu. Sebep: yatay konum
		# safe_rect.size.x'ten hesaplaniyor, o da _ready aninda
		# DisplayServer.get_display_safe_area()'dan geliyor. Android'de bu
		# deger ekran yonu oturmadan once eksik/yanlis donebiliyor ve bir
		# daha guncellenmiyorsa menu yanlis yerde kaliyor.
		#
		# Dikey konum safe_rect'e bagli kalabilir (centik/durum cubugu
		# gercekten dikeyde onemli). Yatayda portrait'te safe alan simetrik,
		# o yuzden viewport merkezine ANCHOR'lamak hem dogru hem de olcumun
		# bayat olmasindan etkilenmez.
		main_menu_box.anchor_left = 0.5
		main_menu_box.anchor_right = 0.5
		main_menu_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
		main_menu_box.offset_left = -menu_width * 0.5
		main_menu_box.offset_right = menu_width * 0.5
		if OS.is_debug_build():
			print("MENU LAYOUT | viewport=%.0fx%.0f safe=%.0f,%.0f %.0fx%.0f | menu=%.0fx%.0f ust=%.0f" % [
				get_viewport_rect().size.x, get_viewport_rect().size.y,
				safe_rect.position.x, safe_rect.position.y,
				safe_rect.size.x, safe_rect.size.y,
				menu_width, menu_height,
				safe_rect.position.y + (safe_rect.size.y - menu_height) * 0.5
			])
		var mobile_title := main_menu_box.get_node_or_null("TitleLabel") as Label
		if is_instance_valid(mobile_title):
			mobile_title.custom_minimum_size = Vector2(menu_width, logo_height)
		for button_name in ["NewGameButton", "ShopButton", "ColonyButton", "MusicButton", "QuitButton"]:
			var mobile_menu_button := main_menu_box.get_node_or_null(button_name) as Button
			if is_instance_valid(mobile_menu_button):
				mobile_menu_button.custom_minimum_size = Vector2(menu_width, button_height)
	if is_instance_valid(paddle_shop_panel):
		_layout_paddle_shop()
	_set_mobile_rect(menu_version_label, Rect2(
		safe_rect.end.x - 252.0,
		safe_rect.end.y - 38.0,
		240.0,
		24.0
	))
	if is_instance_valid(menu_records_label):
		_set_mobile_rect(menu_records_label, Rect2(
			safe_rect.position.x + 18.0,
			safe_rect.end.y - 66.0,
			safe_rect.size.x - 36.0,
			24.0
		))


func _on_mobile_viewport_size_changed() -> void:
	call_deferred("_refresh_mobile_safe_layout")


func _refresh_mobile_safe_layout() -> void:
	if not OS.has_feature("mobile") or not is_inside_tree():
		return
	_apply_mobile_portrait_layout()
	if is_instance_valid(brick_field) and brick_field.has_method("refresh_safe_area_layout"):
		brick_field.refresh_safe_area_layout()


func _setup_main_menu_assets() -> void:
	var menu_layer := get_node_or_null("MainMenu") as CanvasLayer
	if not is_instance_valid(menu_layer):
		return

	var background := menu_layer.get_node_or_null("MenuAssetBackground") as TextureRect
	if not is_instance_valid(background):
		background = TextureRect.new()
		background.name = "MenuAssetBackground"
		menu_layer.add_child(background)
		menu_layer.move_child(background, 0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.texture = MENU_BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	var menu_box := menu_layer.get_node_or_null("VBoxContainer") as VBoxContainer
	if not is_instance_valid(menu_box):
		return

	var title_label := menu_box.get_node_or_null("TitleLabel") as Label
	if is_instance_valid(title_label):
		title_label.text = ""
		title_label.custom_minimum_size = Vector2(300.0, 150.0)
		var logo := title_label.get_node_or_null("LogoTexture") as TextureRect
		if not is_instance_valid(logo):
			logo = TextureRect.new()
			logo.name = "LogoTexture"
			title_label.add_child(logo)
		logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		logo.texture = MENU_LOGO_TEXTURE
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var menu_new_game := menu_box.get_node_or_null("NewGameButton") as Button
	var menu_shop := menu_box.get_node_or_null("ShopButton") as Button
	var menu_colony := menu_box.get_node_or_null("ColonyButton") as Button
	var menu_music := menu_box.get_node_or_null("MusicButton") as Button
	var menu_quit := menu_box.get_node_or_null("QuitButton") as Button
	if is_instance_valid(menu_new_game):
		_apply_menu_button_texture(menu_new_game, MENU_NEW_GAME_TEXTURE)
	if is_instance_valid(menu_shop):
		_apply_menu_button_texture(menu_shop, MENU_SHOP_TEXTURE)
	if is_instance_valid(menu_colony):
		_apply_colony_menu_button_texture(menu_colony)
	if is_instance_valid(menu_music):
		_apply_menu_button_texture(menu_music, MENU_MUSIC_ON_TEXTURE)
	if is_instance_valid(menu_quit):
		_apply_menu_button_texture(menu_quit, MENU_QUIT_TEXTURE)

	_ensure_menu_records_label(menu_layer)
	_ensure_ascension_selector(menu_layer)


func _ensure_menu_records_label(menu_layer: CanvasLayer) -> void:
	if is_instance_valid(menu_records_label):
		return
	menu_records_label = menu_layer.get_node_or_null("RecordsRow") as HBoxContainer
	if not is_instance_valid(menu_records_label):
		menu_records_label = HBoxContainer.new()
		menu_records_label.name = "RecordsRow"
		menu_layer.add_child(menu_records_label)
	menu_records_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_records_label.add_theme_constant_override("separation", 8)
	menu_records_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	menu_records_label.position = Vector2(18.0, -44.0)
	menu_records_label.size = Vector2(460.0, 26.0)

	var records_tone := Color(0.45, 0.72, 0.80, 0.78)
	menu_records_icon = TextureRect.new()
	menu_records_icon.texture = ICON_TROPHY
	menu_records_icon.custom_minimum_size = Vector2(18.0, 18.0)
	menu_records_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_records_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	menu_records_icon.modulate = records_tone
	menu_records_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu_records_label.add_child(menu_records_icon)

	menu_records_text = Label.new()
	menu_records_text.add_theme_font_size_override("font_size", 14)
	menu_records_text.add_theme_color_override("font_color", records_tone)
	menu_records_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	menu_records_label.add_child(menu_records_text)

	refresh_menu_records_label()


func _ensure_ascension_selector(menu_layer: CanvasLayer) -> void:
	# Ascension yalnızca oyun en az bir kez bitirildiyse görünür.
	if GameManager.highest_ascension_cleared < 0:
		return
	if is_instance_valid(ascension_row):
		return
	ascension_row = HBoxContainer.new()
	ascension_row.name = "AscensionRow"
	# Ana menu duraklatilmisken gosterilir; butonlarin girdi alabilmesi gerekir.
	ascension_row.process_mode = Node.PROCESS_MODE_ALWAYS
	ascension_row.add_theme_constant_override("separation", 10)
	ascension_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	ascension_row.position = Vector2(18.0, -74.0)
	ascension_row.size = Vector2(420.0, 28.0)
	menu_layer.add_child(ascension_row)

	var tone := Color(1.0, 0.62, 0.24, 1.0)
	var down := Button.new()
	down.text = "\u25C0"
	down.focus_mode = Control.FOCUS_NONE
	down.add_theme_color_override("font_color", tone)
	down.pressed.connect(_on_ascension_changed.bind(-1))
	ascension_row.add_child(down)

	ascension_label = Label.new()
	ascension_label.add_theme_font_size_override("font_size", 14)
	ascension_label.add_theme_color_override("font_color", tone)
	ascension_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ascension_row.add_child(ascension_label)

	var up := Button.new()
	up.text = "\u25B6"
	up.focus_mode = Control.FOCUS_NONE
	up.add_theme_color_override("font_color", tone)
	up.pressed.connect(_on_ascension_changed.bind(1))
	ascension_row.add_child(up)

	_refresh_ascension_label()


func _on_ascension_changed(delta: int) -> void:
	GameManager.set_ascension_level(GameManager.ascension_level + delta)
	_refresh_ascension_label()


func _refresh_ascension_label() -> void:
	if not is_instance_valid(ascension_label):
		return
	ascension_label.text = "ASCENSION %d / %d" % [
		GameManager.ascension_level, GameManager.get_max_selectable_ascension()
	]


func refresh_menu_records_label() -> void:
	if not is_instance_valid(menu_records_text):
		return
	if GameManager.total_runs <= 0:
		menu_records_icon.texture = ICON_DEPTH
		menu_records_text.text = "İLK RUN SENİ BEKLİYOR"
		return
	menu_records_icon.texture = ICON_TROPHY
	menu_records_text.text = "EN İYİ DEPTH %d   ·   %d RUN   ·   %d BOSS" % [
		GameManager.best_depth,
		GameManager.total_runs,
		GameManager.lifetime_boss_kills,
	]


# ==================================================
# CODEX BÖLÜMÜ — silah kontrolcüleri, PARÇA HUD'u, koloni butonu
# ==================================================

func _setup_building_part_hud() -> void:
	if is_instance_valid(building_part_counter):
		return
	building_part_counter = Control.new()
	building_part_counter.name = "BuildingPartCounter"
	building_part_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	building_part_counter.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	building_part_counter.offset_left = -258.0
	building_part_counter.offset_top = 32.0
	building_part_counter.offset_right = -128.0
	building_part_counter.offset_bottom = 70.0
	$HUD/Layout.add_child(building_part_counter)

	var icon_root := Node2D.new()
	icon_root.name = "Icon"
	icon_root.position = Vector2(18.0, 19.0)
	building_part_counter.add_child(icon_root)
	var sheet := load("res://assets/items/building_part_gear_sheet.png") as Texture2D
	var regions: Array[Rect2] = [
		Rect2(14, 0, 742, 724),
		Rect2(790, 49, 593, 604),
		Rect2(1522, 128, 489, 457),
	]
	var layer_names := ["Base", "Energy", "Core"]
	for index in regions.size():
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = regions[index]
		atlas.filter_clip = true
		var layer := Sprite2D.new()
		layer.name = layer_names[index]
		layer.texture = atlas
		layer.scale = Vector2.ONE * 0.032
		icon_root.add_child(layer)

	building_part_label = Label.new()
	building_part_label.name = "TotalLabel"
	building_part_label.position = Vector2(36.0, 3.0)
	building_part_label.size = Vector2(92.0, 32.0)
	building_part_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	building_part_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	building_part_label.add_theme_font_size_override("font_size", 17)
	building_part_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.34, 1.0))
	building_part_label.add_theme_color_override("font_shadow_color", Color(0.38, 0.20, 0.01, 0.85))
	building_part_label.add_theme_constant_override("shadow_offset_x", 1)
	building_part_label.add_theme_constant_override("shadow_offset_y", 1)
	building_part_counter.add_child(building_part_label)


func _on_total_salvage_changed(total: int) -> void:
	if is_instance_valid(building_part_label):
		building_part_label.text = str(total)


func _make_readability_panel_style(tone: Color, alpha := 0.90) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.035, 0.075, alpha)
	style.border_color = Color(tone.r, tone.g, tone.b, 0.70)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(tone.r, tone.g, tone.b, 0.16)
	style.shadow_size = 5
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style


func _setup_readability_ui() -> void:
	if is_instance_valid(build_identity_panel):
		return
	build_identity_panel = PanelContainer.new()
	build_identity_panel.name = "BuildIdentity"
	build_identity_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_identity_panel.add_theme_stylebox_override(
		"panel", _make_readability_panel_style(Color(0.32, 0.91, 1.0, 1.0))
	)
	$HUD.add_child(build_identity_panel)
	var identity_lines := VBoxContainer.new()
	identity_lines.add_theme_constant_override("separation", 0)
	identity_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_identity_panel.add_child(identity_lines)
	build_identity_core_label = Label.new()
	build_identity_core_label.add_theme_color_override("font_color", Color(0.62, 0.96, 1.0, 1.0))
	build_identity_core_label.add_theme_font_size_override("font_size", 13)
	build_identity_core_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity_lines.add_child(build_identity_core_label)
	build_identity_slots_label = Label.new()
	build_identity_slots_label.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0, 0.96))
	build_identity_slots_label.add_theme_font_size_override("font_size", 12)
	build_identity_slots_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity_lines.add_child(build_identity_slots_label)

	card_slot_state_panel = PanelContainer.new()
	card_slot_state_panel.name = "WeaponSlotState"
	card_slot_state_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	card_slot_state_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_slot_state_panel.add_theme_stylebox_override(
		"panel", _make_readability_panel_style(Color(0.54, 0.60, 1.0, 1.0), 0.94)
	)
	card_panel.add_child(card_slot_state_panel)
	card_slot_state_label = Label.new()
	card_slot_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_slot_state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_slot_state_label.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0, 1.0))
	card_slot_state_label.add_theme_font_size_override("font_size", 12)
	card_slot_state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_slot_state_panel.add_child(card_slot_state_label)

	hud_status_toast = Label.new()
	hud_status_toast.name = "RunStatusToast"
	hud_status_toast.z_index = 120
	hud_status_toast.visible = false
	hud_status_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_status_toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_status_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_status_toast.add_theme_font_size_override("font_size", 15 if OS.has_feature("mobile") else 17)
	hud_status_toast.add_theme_stylebox_override(
		"normal", _make_readability_panel_style(Color(0.45, 0.94, 1.0, 1.0), 0.95)
	)
	$HUD.add_child(hud_status_toast)

	danger_line_visual = Line2D.new()
	danger_line_visual.name = "DangerLineVisual"
	danger_line_visual.z_index = 4
	danger_line_visual.width = 1.25
	danger_line_visual.antialiased = true
	danger_line_visual.visible = false
	add_child(danger_line_visual)
	_layout_readability_ui()


func _layout_readability_ui() -> void:
	if not is_instance_valid(build_identity_panel):
		return
	var viewport_size := get_viewport_rect().size
	if OS.has_feature("mobile"):
		var safe_rect := GameManager.get_layout_safe_rect(viewport_size)
		var identity_width := maxf(280.0, safe_rect.size.x - 194.0)
		_set_mobile_rect(build_identity_panel, Rect2(
			safe_rect.position + Vector2(12.0, 112.0), Vector2(identity_width, 36.0)
		))
		build_identity_core_label.add_theme_font_size_override("font_size", 10)
		build_identity_slots_label.add_theme_font_size_override("font_size", 9)
		var state_width := minf(520.0, safe_rect.size.x - 28.0)
		_set_mobile_rect(card_slot_state_panel, Rect2(
			Vector2(safe_rect.get_center().x - state_width * 0.5, safe_rect.position.y + 184.0),
			Vector2(state_width, 40.0)
		))
		_set_mobile_rect(hud_status_toast, Rect2(
			Vector2(safe_rect.position.x + 24.0, GameManager.PLAYFIELD_TOP + 66.0),
			Vector2(safe_rect.size.x - 48.0, 38.0)
		))
	else:
		_set_mobile_rect(build_identity_panel, Rect2(
			Vector2(viewport_size.x - 432.0, 84.0), Vector2(414.0, 58.0)
		))
		build_identity_core_label.add_theme_font_size_override("font_size", 13)
		build_identity_slots_label.add_theme_font_size_override("font_size", 12)
		_set_mobile_rect(card_slot_state_panel, Rect2(
			Vector2(viewport_size.x * 0.5 - 270.0, 116.0), Vector2(540.0, 48.0)
		))
		_set_mobile_rect(hud_status_toast, Rect2(
			Vector2(viewport_size.x * 0.5 - 300.0, 148.0), Vector2(600.0, 42.0)
		))


func _weapon_short_name(weapon_id: StringName) -> String:
	match weapon_id:
		&"PLASMA": return "PLASMA"
		&"ARC_CANNON": return "ARC"
		&"SCATTER_CANNON": return "SCATTER"
		&"RAILGUN": return "RAIL"
		&"HOMING_MISSILE": return "HOMING"
		&"PULSE_LASER": return "PULSE"
		&"MORTAR": return "MORTAR"
		&"DRONE_BAY": return "DRONE"
		&"ORBITAL_MARKER": return "ORBITAL"
	return String(weapon_id).replace("_", " ")


func _weapon_slot_text(slot_index: int, compact := false) -> String:
	if slot_index < 0 or slot_index >= GameManager.weapon_slots.size():
		return "S%d EMPTY" % (slot_index + 1)
	var slot: Dictionary = GameManager.weapon_slots[slot_index]
	var weapon_id := StringName(slot.get("weapon_id", &""))
	if weapon_id == &"":
		return "S%d EMPTY" % (slot_index + 1)
	var level := clampi(int(slot.get("level", 0)), 0, GameManager.MAX_WEAPON_LEVEL)
	var max_suffix := " MAX" if level >= GameManager.MAX_WEAPON_LEVEL else ""
	var level_prefix := "L" if compact else "Lv"
	return "S%d %s %s%d%s" % [slot_index + 1, _weapon_short_name(weapon_id), level_prefix, level, max_suffix]


func _active_core_text() -> String:
	if GameManager.fireball_level > 0:
		return "FIREBALL Lv%d" % GameManager.fireball_level
	if GameManager.pierce_level > 0:
		return "PIERCING Lv%d" % GameManager.pierce_level
	return "EMPTY"


func _refresh_build_identity_hud(force := false) -> void:
	if not is_instance_valid(build_identity_panel):
		return
	var resonance_text := (
		"READY" if GameManager.is_core_resonance_ready()
		else "%d/%d" % [GameManager.core_resonance_charge, GameManager.CORE_RESONANCE_MAX_CHARGE]
	)
	var signature := "%s|%s|%s|%s|%d" % [
		_active_core_text(), _weapon_slot_text(0), _weapon_slot_text(1),
		resonance_text, GameManager.colony_shield_charges
	]
	if not force and signature == last_build_identity_signature:
		return
	last_build_identity_signature = signature
	build_identity_core_label.text = "CORE %s   ·   REZONANS %s" % [_active_core_text(), resonance_text]
	build_identity_core_label.modulate = (
		Color(1.0, 0.78, 0.28, 1.0) if GameManager.is_core_resonance_ready()
		else Color.WHITE
	)
	build_identity_slots_label.text = "%s   ·   %s   ·   KALKAN %d" % [
		_weapon_slot_text(0, OS.has_feature("mobile")),
		_weapon_slot_text(1, OS.has_feature("mobile")),
		GameManager.colony_shield_charges,
	]


func _refresh_card_slot_state() -> void:
	if not is_instance_valid(card_slot_state_label):
		return
	var slots_text := "%s    ·    %s" % [_weapon_slot_text(0), _weapon_slot_text(1)]
	if not GameManager.has_empty_weapon_slot():
		slots_text += "\nYUVALAR DOLU — YALNIZ YÜKSELTMELER"
	card_slot_state_label.text = slots_text


func _show_hud_status(message: String, tone := Color(0.45, 0.94, 1.0, 1.0), duration := 1.45) -> void:
	if not is_instance_valid(hud_status_toast):
		return
	if is_instance_valid(hud_status_toast_tween):
		hud_status_toast_tween.kill()
	hud_status_toast.text = message
	hud_status_toast.add_theme_color_override("font_color", tone)
	hud_status_toast.modulate = Color.WHITE
	hud_status_toast.scale = Vector2(0.94, 0.94)
	hud_status_toast.pivot_offset = hud_status_toast.size * 0.5
	hud_status_toast.visible = true
	hud_status_toast_tween = hud_status_toast.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	hud_status_toast_tween.tween_property(hud_status_toast, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hud_status_toast_tween.tween_interval(duration)
	hud_status_toast_tween.tween_property(hud_status_toast, "modulate:a", 0.0, 0.22)
	hud_status_toast_tween.tween_callback(func() -> void: hud_status_toast.visible = false)


func _update_danger_line_feedback() -> void:
	if not is_instance_valid(danger_line_visual) or not is_instance_valid(brick_field):
		return
	var should_show: bool = not main_menu.visible and not game_over and not boss_active and not boss_pending
	danger_line_visual.visible = should_show
	if not should_show:
		return
	var danger_y := float(brick_field.get("danger_line_y"))
	var gameplay_rect := GameManager.get_gameplay_rect(get_viewport_rect().size)
	danger_line_visual.points = PackedVector2Array([
		Vector2(gameplay_rect.position.x + 14.0, danger_y),
		Vector2(gameplay_rect.end.x - 14.0, danger_y),
	])
	var closest_distance := 9999.0
	for brick: Node2D in get_tree().get_nodes_in_group("game_brick"):
		if not is_instance_valid(brick) or brick.is_queued_for_deletion():
			continue
		var brick_bottom := brick.global_position.y + 18.0
		if brick_field.has_method("get_brick_bottom"):
			brick_bottom = float(brick_field.call("get_brick_bottom", brick))
		closest_distance = minf(closest_distance, danger_y - brick_bottom)
	var pressure := 1.0 - clampf((closest_distance - 20.0) / 150.0, 0.0, 1.0)
	var calm := Color(0.30, 0.88, 1.0, 0.12 if OS.has_feature("mobile") else 0.16)
	var danger := Color(1.0, 0.28, 0.12, 0.42 if OS.has_feature("mobile") else 0.52)
	danger_line_visual.default_color = calm.lerp(danger, pressure)
	danger_line_visual.width = lerpf(1.0, 2.0, pressure)


func _apply_colony_menu_button_texture(button: Button) -> void:
	button.text = ""
	button.icon = null
	button.flat = true
	button.clip_contents = false
	button.custom_minimum_size = Vector2(320.0, 84.0)
	var empty_style := StyleBoxEmpty.new()
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(state, empty_style)
	var visual := button.get_node_or_null("ColonyButtonVisual") as TextureRect
	if not is_instance_valid(visual):
		visual = TextureRect.new()
		visual.name = "ColonyButtonVisual"
		button.add_child(visual)
	var cropped_texture := AtlasTexture.new()
	cropped_texture.atlas = MENU_COLONY_TEXTURE
	cropped_texture.region = MENU_COLONY_VISIBLE_REGION
	visual.texture = cropped_texture
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.pivot_offset = button.custom_minimum_size * 0.5
	visual.scale = Vector2.ONE
	visual.modulate = Color.WHITE


func _animate_colony_button_visual(target_scale: Vector2, target_modulate: Color, duration: float) -> void:
	var visual := colony_button.get_node_or_null("ColonyButtonVisual") as TextureRect
	if not is_instance_valid(visual):
		return
	if colony_button_visual_tween != null and colony_button_visual_tween.is_valid():
		colony_button_visual_tween.kill()
	colony_button_visual_tween = visual.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	colony_button_visual_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	colony_button_visual_tween.parallel().tween_property(visual, "scale", target_scale, duration)
	colony_button_visual_tween.parallel().tween_property(visual, "modulate", target_modulate, duration)


func _restore_colony_button_visual() -> void:
	var target_scale := Vector2.ONE * 1.03 if colony_button.is_hovered() else Vector2.ONE
	var target_modulate := Color(1.08, 1.08, 1.08, 1.0) if colony_button.is_hovered() else Color.WHITE
	_animate_colony_button_visual(target_scale, target_modulate, 0.10)


func _setup_arc_cannon_controller() -> void:
	arc_cannon_controller = ARC_CANNON_CONTROLLER_SCRIPT.new()
	arc_cannon_controller.name = "ArcCannonController"
	add_child(arc_cannon_controller)
	arc_cannon_controller.configure(self, paddle, $ChainLightningManager)


func _setup_scatter_cannon_controller() -> void:
	scatter_cannon_controller = SCATTER_CANNON_CONTROLLER_SCRIPT.new()
	scatter_cannon_controller.name = "ScatterCannonController"
	add_child(scatter_cannon_controller)
	scatter_cannon_controller.configure(self, paddle)


func _setup_railgun_controller() -> void:
	railgun_controller = RAILGUN_CONTROLLER_SCRIPT.new()
	railgun_controller.name = "RailgunController"
	add_child(railgun_controller)
	railgun_controller.configure(self, paddle)


func _setup_homing_missile_controller() -> void:
	homing_missile_controller = HOMING_MISSILE_CONTROLLER_SCRIPT.new()
	homing_missile_controller.name = "HomingMissileController"
	add_child(homing_missile_controller)
	homing_missile_controller.configure(self, paddle)


func _setup_pulse_laser_controller() -> void:
	pulse_laser_controller = PULSE_LASER_CONTROLLER_SCRIPT.new()
	pulse_laser_controller.name = "PulseLaserController"
	add_child(pulse_laser_controller)
	pulse_laser_controller.configure(self, paddle)


func _apply_menu_button_texture(button: Button, texture: Texture2D) -> void:
	button.text = ""
	button.icon = texture
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.flat = true
	button.custom_minimum_size = Vector2(320.0, 84.0)

func _apply_colony_menu_button_style(button: Button) -> void:
	button.text = "KOLON\u0130"
	button.icon = null
	button.flat = false
	button.custom_minimum_size = Vector2(320.0, 84.0)
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color(0.76, 1.0, 0.98))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.015, 0.08, 0.13, 0.94)
	normal.border_color = Color(0.08, 0.72, 1.0, 0.92)
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(14)
	normal.shadow_color = Color(0.0, 0.6, 1.0, 0.30)
	normal.shadow_size = 10
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = Color(0.42, 1.0, 0.96)
	hover.shadow_size = 15
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.025, 0.16, 0.22, 0.98)
	button.add_theme_stylebox_override("pressed", pressed)

func _setup_desktop_gameplay_camera(gameplay_enabled: bool) -> void:
	if OS.has_feature("mobile"):
		return
	desktop_gameplay_camera = Camera2D.new()
	desktop_gameplay_camera.name = "DesktopGameplayCamera"
	desktop_gameplay_camera.set_as_top_level(true)
	desktop_gameplay_camera.position_smoothing_enabled = false
	add_child(desktop_gameplay_camera)
	desktop_gameplay_camera.enabled = gameplay_enabled
	_refresh_desktop_gameplay_layout()
	get_viewport().size_changed.connect(_refresh_desktop_gameplay_layout)


func _refresh_desktop_gameplay_layout() -> void:
	if OS.has_feature("mobile"):
		return
	var viewport_size := get_viewport_rect().size
	var visible_world_rect := GameManager.get_desktop_visible_world_rect(viewport_size)
	if is_instance_valid(desktop_gameplay_camera):
		desktop_gameplay_camera.global_position = visible_world_rect.get_center()
		desktop_gameplay_camera.zoom = Vector2.ONE * GameManager.DESKTOP_GAMEPLAY_CAMERA_ZOOM
	if is_instance_valid(paddle) and paddle.has_method("set_desktop_bottom_margin"):
		paddle.set_desktop_bottom_margin(viewport_size.y, GameManager.DESKTOP_PADDLE_BOTTOM_MARGIN)
	if is_instance_valid(brick_field) and brick_field.has_method("refresh_desktop_layout"):
		brick_field.refresh_desktop_layout()

func _ready():
	_setup_card_presentation()
	_setup_main_menu_assets()
	_setup_building_part_hud()
	_setup_readability_ui()
	if not GameManager.total_salvage_changed.is_connected(_on_total_salvage_changed):
		GameManager.total_salvage_changed.connect(_on_total_salvage_changed)
	_setup_arc_cannon_controller()
	_setup_scatter_cannon_controller()
	_setup_railgun_controller()
	_setup_homing_missile_controller()
	_setup_pulse_laser_controller()
	if not GameManager.total_coins_changed.is_connected(_on_total_coins_changed):
		GameManager.total_coins_changed.connect(_on_total_coins_changed)
	_on_total_coins_changed(GameManager.total_coins)
	xp_bar.process_mode = Node.PROCESS_MODE_ALWAYS
	xp_bar.pivot_offset = xp_bar.size * 0.5
	lives_panel.pivot_offset = lives_panel.size * 0.5
	$PlayfieldTopWall.position.y = GameManager.PLAYFIELD_TOP - 4.0
	$HUD/ComboManager.rank_changed.connect(_on_combo_rank_changed)
	update_magnet_aura_feedback(0.0)
	boss_hp_panel.visible = false
	boss_warning.visible = false
	if OS.has_feature("mobile"):
		_apply_mobile_portrait_layout()
		get_viewport().size_changed.connect(_on_mobile_viewport_size_changed)
	else:
		_setup_desktop_gameplay_camera(GameManager.start_directly)

	# --------------------------------------------------
	# PAUSE SIRASINDA MENÃƒÆ’Ã…â€œLER ÃƒÆ’Ã¢â‚¬Â¡ALIÃƒâ€¦Ã‚ÂABÃƒâ€Ã‚Â°LSÃƒâ€Ã‚Â°N
	# --------------------------------------------------

	main_menu.process_mode = (
		Node.PROCESS_MODE_WHEN_PAUSED
	)

	game_over_screen.process_mode = (
		Node.PROCESS_MODE_WHEN_PAUSED
	)

	card_screen.process_mode = (
		Node.PROCESS_MODE_WHEN_PAUSED
	)
	evolution_screen.process_mode = Node.PROCESS_MODE_WHEN_PAUSED


	# --------------------------------------------------
	# LEVEL OLUÃƒâ€¦Ã‚ÂTUR
	# --------------------------------------------------

	brick_field = brick_field_scene.new()
	brick_field.name = "BrickField"
	add_child(brick_field)
	brick_field.initialize(self)
	update_depth_debug_label()


	# --------------------------------------------------
	# EKRANLAR
	# --------------------------------------------------

	card_panel.visible = false
	evolution_panel.visible = false
	game_over_screen.visible = false
	pause_menu.visible = false
	sector_transition.visible = false
	_apply_sector_background(1, false)
	pause_button.visible = OS.has_feature("mobile")
	_create_coin_debug_overlay()


	# --------------------------------------------------
	# ANA MENÃƒÆ’Ã…â€œ BUTONLARI
	# --------------------------------------------------

	new_game_button.pressed.connect(
		start_new_game
	)
	shop_button.pressed.connect(_open_paddle_shop)
	colony_button.pressed.connect(_open_colony)
	music_button.pressed.connect(toggle_music)
	_create_paddle_shop()
	_refresh_shop_button_text()
	_setup_main_menu_button_feedback()
	_refresh_music_button_text()

	quit_button.pressed.connect(
		quit_game
	)
	pause_button.pressed.connect(toggle_pause_menu)
	pause_resume_button.pressed.connect(resume_from_pause_menu)
	pause_main_menu_button.pressed.connect(return_to_main_menu_from_pause)


	# --------------------------------------------------
	# GAME OVER BUTONLARI
	# --------------------------------------------------

	retry_button.pressed.connect(
		retry_game
	)

	main_menu_button.pressed.connect(
		return_to_main_menu
	)


	# --------------------------------------------------
	# KART BUTONLARI
	# --------------------------------------------------

	for card_slot: Button in _get_card_slots():
		card_slot.pressed.connect(_on_card_slot_pressed.bind(card_slot))
	overcharge_card.pressed.connect(_select_active_evolution.bind(0))
	ricochet_card.pressed.connect(_select_active_evolution.bind(1))
	for card in _get_card_slots():
		card.focus_entered.connect(_on_card_focus_entered.bind(card))
	_setup_card_action_buttons()
	for evolution_card in [overcharge_card, ricochet_card]:
		evolution_card.focus_entered.connect(_on_card_focus_entered.bind(evolution_card))


	update_labels()
	build_hud.refresh_from_run_state(false)
	_refresh_build_identity_hud(true)
	paddle.apply_run_upgrades(
		GameManager.plasma_level,
		GameManager.plasma_evolution
	)
	set_plasma_launch_paused(
		not get_tree().get_nodes_in_group("manual_launch_waiting").is_empty()
	)


	# ==================================================
	# SAHNE NASIL AÃƒÆ’Ã¢â‚¬Â¡ILACAK?
	# ==================================================

	# DEBUG / TEST: Sadece tek bir boss'u denemek icin dogrudan arena.
	# Kullanim:  godot --path . -- --boss=celestial
	var rehearsal_boss: StringName = _get_debug_boss_request()
	if rehearsal_boss != &"none":
		GameManager.start_directly = false
		main_menu.visible = false
		_refresh_coin_debug_visibility()
		$HUD.visible = true
		game_over_screen.visible = false
		get_tree().paused = false
		call_deferred("_begin_boss_rehearsal", rehearsal_boss)
		return

	if GameManager.start_directly:

		# Level geÃƒÆ’Ã‚Â§iÃƒâ€¦Ã…Â¸i veya Tekrar Oyna.
		# Ana menÃƒÆ’Ã‚Â¼yÃƒÆ’Ã‚Â¼ atla.

		GameManager.start_directly = false

		main_menu.visible = false
		_refresh_coin_debug_visibility()
		$HUD.visible = true

		game_over_screen.visible = false

		get_tree().paused = false


		call_deferred("_try_resolve_pending_rewards")


	else:

		# Oyunun ilk aÃƒÆ’Ã‚Â§Ãƒâ€Ã‚Â±lÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸Ãƒâ€Ã‚Â±.

		main_menu.visible = true
		_refresh_coin_debug_visibility()
		$HUD.visible = false

		if OS.has_feature("mobile"):
			for menu_button: Button in [new_game_button, shop_button, colony_button, music_button, quit_button]:
				menu_button.focus_mode = Control.FOCUS_NONE
		else:
			new_game_button.grab_focus()

		get_tree().paused = true


# ==================================================
# DEBUG / TEST: LEVEL ATLAMA KISAYOLU
# ==================================================

func _get_debug_boss_request() -> StringName:
	if not OS.is_debug_build() or OS.has_feature("release"):
		return &"none"
	var candidates: Array[String] = []
	candidates.append_array(OS.get_cmdline_user_args())
	candidates.append_array(OS.get_cmdline_args())
	for arg: String in candidates:
		if not arg.begins_with("--boss="):
			continue
		var value := arg.trim_prefix("--boss=").strip_edges().to_lower()
		if value in ["core", "sentinel", "celestial", "void", "sovereign", "architect", "chronoform"]:
			return StringName(value)
		push_warning("Bilinmeyen --boss degeri: %s" % value)
	return &"none"


func _begin_boss_rehearsal(boss_type: StringName) -> void:
	# Brick field'in ilk satirlari yerlesip top firlatilabilsin diye kisa bekle.
	await get_tree().create_timer(0.8).timeout
	if game_over:
		return
	print("BOSS REHEARSAL: %s" % _get_boss_display_name(boss_type))
	start_boss_encounter(false, boss_type)


func _unhandled_key_input(event):

	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_C
		and OS.is_debug_build()
		and not OS.has_feature("release")
	):
		_debug_add_test_coins()
		get_viewport().set_input_as_handled()
		return

	if not (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and not game_over
		and not choosing_card
		and not evolution_selection_active
		and not main_menu.visible
	):
		return


	if event.keycode == KEY_ESCAPE:
		toggle_pause_menu()
		get_viewport().set_input_as_handled()
		return


	if not OS.is_debug_build() or OS.has_feature("release"):
		return

	if event.keycode == KEY_F2:

		# DEBUG / TEST: Eski level skip yerine continuous run depth artÃƒâ€Ã‚Â±rÃƒâ€Ã‚Â±r.
		if is_instance_valid(brick_field):
			brick_field.debug_advance_depth()


	# DEBUG / TEST: Plazma kartÃƒâ€Ã‚Â±nÃƒâ€Ã‚Â± garanti eden kart ekranÃƒâ€Ã‚Â±.
	elif event.keycode == KEY_F3:

		show_card_selection(true)


	# DEBUG / TEST: Normal XP akÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸Ãƒâ€Ã‚Â± ÃƒÆ’Ã‚Â¼zerinden bir level-up tetikler.
	elif event.keycode == KEY_F4:

		add_xp(
			GameManager.xp_required
			- GameManager.current_xp,
			false
		)


	# DEBUG / TEST: GerÃƒÆ’Ã‚Â§ek Heart pickup akÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸Ãƒâ€Ã‚Â±nÃƒâ€Ã‚Â± paddle ÃƒÆ’Ã‚Â¼zerinde test eder.
	elif event.keycode == KEY_F7:

		spawn_heart_pickup(paddle.global_position + Vector2(0, -45))



	# DEBUG / TEST: Basit THE CORE boss encounter'ini baÃƒâ€¦Ã…Â¸latÃƒâ€Ã‚Â±r.
	elif event.keycode == KEY_B:

		# B = debug boss, Shift+B = gerÃƒÆ’Ã‚Â§ek progression/reward akÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸Ãƒâ€Ã‚Â±.
		start_boss_encounter(event.shift_pressed)


	# DEBUG / TEST: Aktif THE CORE'u normal defeated akÃƒâ€Ã‚Â±Ãƒâ€¦Ã…Â¸Ãƒâ€Ã‚Â±yla anÃƒâ€Ã‚Â±nda ÃƒÆ’Ã‚Â¶ldÃƒÆ’Ã‚Â¼rÃƒÆ’Ã‚Â¼r.
	elif event.keycode == KEY_N:

		start_boss_encounter(event.shift_pressed, &"sentinel")


	# DEBUG / TEST: 3. progression boss THE CELESTIAL encounter'ini baslatir.
	elif event.keycode == KEY_M:

		start_boss_encounter(event.shift_pressed, &"celestial")


	# DEBUG / TEST: 4. progression boss THE VOID ENTITY encounter'ini baslatir.
	elif event.keycode == KEY_V:

		start_boss_encounter(event.shift_pressed, &"void")


	# DEBUG / TEST: 5. progression boss THE VOID SOVEREIGN encounter'ini baslatir.
	elif event.keycode == KEY_J:

		start_boss_encounter(event.shift_pressed, &"sovereign")


	# DEBUG / TEST: 6. progression boss THE VOID ARCHITECT encounter'ini baslatir.
	elif event.keycode == KEY_H:

		start_boss_encounter(event.shift_pressed, &"architect")


	# DEBUG / TEST: 7. progression boss THE CHRONOFORM encounter'ini baslatir.
	elif event.keycode == KEY_G:

		start_boss_encounter(event.shift_pressed, &"chronoform")


	elif event.keycode == KEY_K:

		if boss_active and is_instance_valid(active_boss):
			active_boss.debug_instant_kill()


func on_continuous_row_spawned(row_depth: int) -> void:
	_queue_sector_transition_for_depth(row_depth)
	if boss_pending or boss_active:
		return
	if row_depth == FIRST_BOSS_MILESTONE_DEPTH and not first_boss_defeated:
		pending_boss_type = &"core"
	elif row_depth == SECOND_BOSS_MILESTONE_DEPTH and not second_boss_defeated:
		pending_boss_type = &"sentinel"
	elif row_depth == THIRD_BOSS_MILESTONE_DEPTH and not third_boss_defeated:
		pending_boss_type = &"celestial"
	elif row_depth == FOURTH_BOSS_MILESTONE_DEPTH and not fourth_boss_defeated:
		pending_boss_type = &"void"
	elif row_depth == FIFTH_BOSS_MILESTONE_DEPTH and not fifth_boss_defeated:
		pending_boss_type = &"sovereign"
	elif row_depth == SIXTH_BOSS_MILESTONE_DEPTH and not sixth_boss_defeated:
		pending_boss_type = &"architect"
	elif row_depth == SEVENTH_BOSS_MILESTONE_DEPTH and not seventh_boss_defeated:
		pending_boss_type = &"chronoform"
	else:
		return
	boss_pending = true
	_cleanup_side_attacker_for_boss_transition()
	if is_instance_valid(brick_field):
		brick_field.begin_boss_board_drain()
	call_deferred("_try_start_pending_boss")


func _get_sector_for_depth(depth: int) -> int:
	return SectorModifiers.get_sector_for_depth(depth)


func _queue_sector_transition_for_depth(depth: int) -> void:
	var next_sector := _get_sector_for_depth(depth)
	if next_sector <= 1 or next_sector <= current_sector or next_sector <= pending_sector_transition:
		return
	pending_sector_transition = next_sector


func _try_play_pending_sector_transition() -> void:
	if pending_sector_transition <= current_sector or sector_transition_playing:
		return
	if (
		game_over or main_menu.visible or pause_menu_active
		or choosing_card or evolution_selection_active
		or boss_active or boss_pending or boss_warning_running
	):
		return
	_play_sector_transition(pending_sector_transition)


func _play_sector_transition(sector: int) -> void:
	sector_transition_playing = true
	pending_sector_transition = 0
	current_sector = sector
	var roman: String = ["I", "II", "III", "IV", "V", "VI", "VII"][sector - 1]
	sector_label.text = "SEKT\u00D6R %s \u2014 %s" % [roman, SectorModifiers.get_sector_name(sector)]
	sector_threat_label.text = SectorModifiers.get_tagline(sector)
	# Sektör aktifken tüm sistemler modifier'ı buradan okur.
	GameManager.current_sector = sector
	refresh_dynamic_build_difficulty()
	for ball in get_tree().get_nodes_in_group("game_ball"):
		if ball.has_method("refresh_card_modifiers"):
			ball.refresh_card_modifiers()
	print("SECTOR %d: %s | inis=%.2f dolum=+%.2f patlayici=+%.2f top=%.2f taret=%.2f" % [
		sector,
		SectorModifiers.get_sector_name(sector),
		SectorModifiers.get_descent_scale(sector),
		SectorModifiers.get_row_fill_bonus(sector),
		SectorModifiers.get_explosive_bonus(sector),
		SectorModifiers.get_ball_speed_scale(sector),
		SectorModifiers.get_attacker_scale(sector),
	])
	sector_transition.visible = true
	sector_transition.modulate = Color(1.0, 1.0, 1.0, 0.0)
	sector_transition.scale = Vector2.ONE * 0.35
	sector_transition.pivot_offset = sector_transition.size * 0.5
	_apply_sector_background(sector, true)
	if is_instance_valid(sector_transition_tween):
		sector_transition_tween.kill()
	sector_transition_tween = sector_transition.create_tween()
	sector_transition_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	sector_transition_tween.parallel().tween_property(sector_transition, "modulate:a", 1.0, 0.35)
	sector_transition_tween.parallel().tween_property(sector_transition, "scale", Vector2.ONE * 1.15, 0.35)
	sector_transition_tween.tween_property(sector_transition, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sector_transition_tween.tween_interval(1.0)
	sector_transition_tween.set_parallel(true)
	sector_transition_tween.tween_property(sector_transition, "scale", Vector2.ONE * 1.20, 0.70).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sector_transition_tween.tween_property(sector_transition, "modulate:a", 0.0, 0.70).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sector_transition_tween.set_parallel(false)
	await sector_transition_tween.finished
	sector_transition.visible = false
	sector_transition_playing = false


func _apply_sector_background(sector: int, animate: bool) -> void:
	var progress := clampf(float(sector - 1) / 6.0, 0.0, 1.0)
	var nebula_target := Color(
		1.0 + 0.04 * progress,
		1.0 + 0.045 * progress,
		1.0 + 0.06 * progress,
		0.62 + 0.03 * progress
	)
	var star_target := 1.0 + 0.12 * progress
	if not animate:
		space_nebula_background.modulate = nebula_target
		animated_starfield.set("sector_intensity_multiplier", star_target)
		return
	if is_instance_valid(sector_background_tween):
		sector_background_tween.kill()
	sector_background_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sector_background_tween.parallel().tween_property(space_nebula_background, "modulate", nebula_target, 1.2)
	sector_background_tween.parallel().tween_property(animated_starfield, "sector_intensity_multiplier", star_target, 1.2)


func _try_start_pending_boss() -> void:
	if choosing_card or xp_level_up_sequence_active or evolution_selection_active or boss_reward_active or pause_menu_active:
		return
	if not boss_pending or pending_boss_type == &"none" or boss_active or boss_warning_running:
		return
	if _count_active_field_bricks() > 0:
		return
	# Board-clear anÄ±nda yeni row/Side Wave aynÄ± frame'de araya giremesin.
	if is_instance_valid(brick_field):
		brick_field.lock_for_boss_transition()
	_run_progression_boss_warning()


func _cleanup_side_attacker_for_boss_transition() -> void:
	var side_spawner := get_node_or_null("SideAttackerSpawner")
	if is_instance_valid(side_spawner) and side_spawner.has_method("cleanup_for_boss_transition"):
		side_spawner.cleanup_for_boss_transition()


func _count_active_field_bricks() -> int:
	var active_count := 0
	for brick: Node in get_tree().get_nodes_in_group("game_brick"):
		if not is_instance_valid(brick):
			continue
		if is_instance_valid(brick_field) and not brick_field.is_ancestor_of(brick):
			continue
		if brick.get("is_destroyed") == true:
			continue
		active_count += 1
	return active_count


func _run_progression_boss_warning() -> void:
	if boss_warning_running or not boss_pending or pending_boss_type == &"none":
		return
	boss_warning_running = true
	await get_tree().create_timer(0.55).timeout
	if not boss_pending or game_over:
		boss_warning_running = false
		return
	boss_warning.visible = true
	boss_warning.modulate.a = 0.0
	boss_warning_label.text = "WARNING"
	var warning_in := boss_warning.create_tween()
	warning_in.tween_property(boss_warning, "modulate:a", 1.0, 0.16)
	await warning_in.finished
	await get_tree().create_timer(0.28).timeout
	boss_warning_label.text = "BOSS INCOMING"
	await get_tree().create_timer(0.52).timeout
	var warning_out := boss_warning.create_tween()
	warning_out.tween_property(boss_warning, "modulate:a", 0.0, 0.18)
	await warning_out.finished
	boss_warning.visible = false
	boss_warning_running = false
	if boss_pending and not game_over:
		start_boss_encounter(true, pending_boss_type)


func start_boss_encounter(is_progression_boss: bool = false, boss_type: StringName = &"core") -> void:
	if boss_active or is_instance_valid(active_boss):
		return
	if boss_type not in [&"core", &"sentinel", &"celestial", &"void", &"sovereign", &"architect", &"chronoform"]:
		return
	boss_active = true
	active_boss_is_progression = is_progression_boss
	active_boss_type = boss_type
	$HUD/ComboManager.reset_combo()
	if is_instance_valid(brick_field):
		brick_field.pause_for_boss()
		if not is_progression_boss:
			await brick_field.clear_bricks_for_boss(0.28)
	if not boss_active or game_over:
		return
	active_boss = _get_boss_scene(boss_type).instantiate()
	add_child(active_boss)
	var viewport_size: Vector2 = get_viewport_rect().size
	var boss_safe_rect := GameManager.get_gameplay_rect(viewport_size)
	active_boss.global_position = Vector2(boss_safe_rect.get_center().x, boss_safe_rect.position.y - 100.0)
	active_boss.health_changed.connect(_on_boss_health_changed)
	active_boss.defeated.connect(_on_boss_defeated)
	if active_boss.has_signal("generator_state_changed"):
		active_boss.generator_state_changed.connect(_on_sentinel_generator_state_changed)
	if active_boss.has_signal("status_feedback"):
		active_boss.status_feedback.connect(_on_sentinel_status_feedback)
	_setup_boss_hud(boss_type)
	boss_hp_bar.max_value = active_boss.max_hp
	boss_hp_bar.value = active_boss.current_hp
	boss_hp_panel.visible = true
	print("%s spawned" % _get_boss_display_name(boss_type))
	var combat_y: float = GameManager.PLAYFIELD_TOP + _get_boss_combat_offset(boss_type)
	active_boss.begin_entry(Vector2(boss_safe_rect.get_center().x, combat_y))
	if is_instance_valid(brick_field):
		brick_field.start_boss_side_waves()


func _get_boss_scene(boss_type: StringName) -> PackedScene:
	match boss_type:
		&"sentinel":
			return boss_sentinel_scene
		&"celestial":
			return boss_celestial_scene
		&"void":
			return boss_void_scene
		&"sovereign":
			return boss_void_sovereign_scene
		&"architect":
			return boss_void_architect_scene
		&"chronoform":
			return boss_chronoform_scene
		_:
			return boss_core_scene


func _get_boss_display_name(boss_type: StringName) -> String:
	match boss_type:
		&"sentinel":
			return "THE SENTINEL"
		&"celestial":
			return "THE CELESTIAL"
		&"void":
			return "THE VOID ENTITY"
		&"sovereign":
			return "THE VOID SOVEREIGN"
		&"architect":
			return "THE VOID ARCHITECT"
		&"chronoform":
			return "THE CHRONOFORM"
		_:
			return "THE CORE"


# 10 boss hedefine göre ölçeklenir. Son üç kayıt henüz eklenmemiş 8/9/10. boss içindir;
# _get_boss_reward_index clamp'lediği için eksik boss tipleri güvenle 0'a düşer.
const BOSS_REWARD_SALVAGE := [8, 10, 12, 14, 16, 18, 22, 26, 30, 36]
const BOSS_REWARD_COINS := [4, 5, 7, 8, 10, 12, 15, 18, 21, 25]

func _get_boss_reward_index(boss_type: StringName) -> int:
	match boss_type:
		&"sentinel":
			return 1
		&"celestial":
			return 2
		&"void":
			return 3
		&"sovereign":
			return 4
		&"architect":
			return 5
		&"chronoform":
			return 6
	return 0


func _award_boss_defeat_rewards(boss_type: StringName) -> void:
	# Boss ödülü artık üç seçenekli bir karar ekranı üzerinden verilir.
	_open_boss_reward_screen(boss_type)


# ==================================================
# BOSS ÖDÜL SEÇİMİ
# ==================================================

func _build_boss_reward_options(boss_type: StringName) -> Array:
	var index := clampi(_get_boss_reward_index(boss_type), 0, BOSS_REWARD_SALVAGE.size() - 1)
	var salvage_reward: int = BOSS_REWARD_SALVAGE[index]
	var coin_reward: int = BOSS_REWARD_COINS[index]
	var options: Array = []

	# 1) Kaynak: garanti PARÇA + coin yığını.
	options.append({
		"id": &"salvage",
		"title": "GANİMET",
		"description": "+%d PARÇA\n+%d COIN" % [salvage_reward * 2, coin_reward * 2],
		"icon": ICON_SALVAGE,
		"tone": Color(0.30, 0.95, 1.0, 1.0),
		"salvage": salvage_reward * 2,
		"coins": coin_reward * 2,
	})

	# 2) Dayanıklılık: can dolumu, tavandaysa yerine PARÇA.
	if GameManager.lives < GameManager.MAX_LIVES:
		options.append({
			"id": &"heal",
			"title": "ONARIM",
			"description": "+2 CAN\n+%d PARÇA" % salvage_reward,
			"icon": ICON_LIFE,
			"tone": Color(1.0, 0.42, 0.58, 1.0),
			"lives": 2,
			"salvage": salvage_reward,
		})
	else:
		options.append({
			"id": &"heal",
			"title": "FAZLA ENERJİ",
			"description": "Can zaten dolu.\n+%d PARÇA" % salvage_reward,
			"icon": ICON_LIFE,
			"tone": Color(1.0, 0.42, 0.58, 1.0),
			"salvage": salvage_reward,
		})

	# 3) Taktik: kart ekranı üzerinde kontrol.
	options.append({
		"id": &"tactics",
		"title": "TAKTİK VERİ",
		"description": "+2 YENİDEN DAĞIT\n+1 KARTI YOK ET",
		"icon": ICON_TROPHY,
		"tone": Color(0.72, 0.30, 1.00, 1.0),
		"rerolls": 2,
		"banishes": 1,
	})

	# 4) Kasa: taşınan PARÇA'yı güvenceye al. Yalnızca riske atılacak bir şey
	# varken görünür — boş seçenek sunmanın anlamı yok.
	if GameManager.carried_salvage > 0:
		options.append({
			"id": &"bank",
			"title": "KASAYA AL",
			"description": "Taşınan %d PARÇA'yı\ngüvenceye al." % GameManager.carried_salvage,
			"icon": ICON_SALVAGE,
			"tone": Color(0.16, 0.88, 0.48, 1.0),
			"bank": true,
		})

	# 5) Lanet: gönüllü zorluk karşılığında kalıcı kazanç çarpanı.
	var curse_offer: StringName = Curses.pick_offer(GameManager.active_curses, GameManager.lives)
	if curse_offer != &"none":
		options.append({
			"id": &"curse",
			"curse_id": curse_offer,
			"title": Curses.get_curse_name(curse_offer),
			"description": "%s\n%s" % [
				Curses.get_description(curse_offer),
				Curses.get_reward_text(curse_offer),
			],
			"icon": ICON_DEPTH,
			"tone": Color(1.00, 0.34, 0.34, 1.0),
		})
	return options


func _open_boss_reward_screen(boss_type: StringName) -> void:
	if boss_reward_active:
		return
	boss_reward_options = _build_boss_reward_options(boss_type)
	if boss_reward_options.is_empty():
		return
	boss_reward_active = true
	_ensure_boss_reward_screen()
	_render_boss_reward_options(boss_type)
	boss_reward_screen.visible = true
	if not OS.has_feature("mobile") and not boss_reward_buttons.is_empty():
		boss_reward_buttons[0].grab_focus()
	get_tree().paused = true


func _ensure_boss_reward_screen() -> void:
	if is_instance_valid(boss_reward_screen):
		return
	boss_reward_screen = CanvasLayer.new()
	boss_reward_screen.name = "BossRewardScreen"
	boss_reward_screen.layer = 28
	# Ekran get_tree().paused = true iken aciliyor; PROCESS_MODE_ALWAYS olmazsa
	# butonlar girdi almaz. Kart ekrani da sahne dosyasinda ayni sekilde isaretli.
	boss_reward_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	boss_reward_screen.visible = false
	add_child(boss_reward_screen)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.004, 0.012, 0.035, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	boss_reward_screen.add_child(dim)

	boss_reward_title = Label.new()
	boss_reward_title.name = "Title"
	boss_reward_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_reward_title.add_theme_font_size_override("font_size", 30)
	boss_reward_title.add_theme_color_override("font_color", Color(0.36, 0.96, 1.0, 1.0))
	boss_reward_screen.add_child(boss_reward_title)

	boss_reward_subtitle = Label.new()
	boss_reward_subtitle.name = "Subtitle"
	boss_reward_subtitle.text = "ÖDÜLÜNÜ SEÇ"
	boss_reward_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_reward_subtitle.add_theme_font_size_override("font_size", 16)
	boss_reward_subtitle.add_theme_color_override("font_color", Color(0.62, 0.78, 0.90, 0.85))
	boss_reward_screen.add_child(boss_reward_subtitle)

	boss_reward_row = HBoxContainer.new()
	boss_reward_row.name = "Options"
	boss_reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	boss_reward_row.add_theme_constant_override("separation", 22)
	boss_reward_screen.add_child(boss_reward_row)


func _make_boss_reward_button(option: Dictionary) -> Button:
	var tone: Color = option.get("tone", Color.WHITE)
	var button := Button.new()
	button.custom_minimum_size = Vector2(226.0, 250.0)
	button.focus_mode = Control.FOCUS_NONE if OS.has_feature("mobile") else Control.FOCUS_ALL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.016, 0.055, 0.085, 0.96)
	style.border_color = tone
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(tone.r, tone.g, tone.b, 0.28)
	style.shadow_size = 12
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.set_border_width_all(4)
	hover.shadow_size = 20
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", hover)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 12)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 14.0
	column.offset_right = -14.0
	column.offset_top = 18.0
	column.offset_bottom = -18.0
	button.add_child(column)

	var icon := TextureRect.new()
	icon.texture = option.get("icon") as Texture2D
	icon.custom_minimum_size = Vector2(64.0, 64.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = tone
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)

	var title := Label.new()
	title.text = String(option.get("title", ""))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", tone)
	column.add_child(title)

	var description := Label.new()
	description.text = String(option.get("description", ""))
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 14)
	description.add_theme_color_override("font_color", Color(0.80, 0.87, 0.95, 1.0))
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(description)

	return button


func _render_boss_reward_options(boss_type: StringName) -> void:
	boss_reward_title.text = "%s YENİLDİ" % _get_boss_display_name(boss_type)
	for child in boss_reward_row.get_children():
		child.queue_free()
	boss_reward_buttons.clear()

	for index in range(boss_reward_options.size()):
		var button := _make_boss_reward_button(boss_reward_options[index])
		button.pressed.connect(_on_boss_reward_selected.bind(index))
		boss_reward_row.add_child(button)
		boss_reward_buttons.append(button)

	_layout_boss_reward_screen()


func _layout_boss_reward_screen() -> void:
	if not is_instance_valid(boss_reward_screen):
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var safe_rect := GameManager.get_layout_safe_rect(viewport_size)
	_set_mobile_rect(boss_reward_title, Rect2(
		safe_rect.position.x, safe_rect.position.y + (150.0 if OS.has_feature("mobile") else 84.0),
		safe_rect.size.x, 40.0
	))
	_set_mobile_rect(boss_reward_subtitle, Rect2(
		safe_rect.position.x, boss_reward_title.position.y + 42.0, safe_rect.size.x, 24.0
	))
	var row_size := boss_reward_row.get_combined_minimum_size()
	_set_mobile_rect(boss_reward_row, Rect2(
		safe_rect.position.x + (safe_rect.size.x - row_size.x) * 0.5,
		boss_reward_subtitle.position.y + 48.0,
		maxf(row_size.x, 1.0),
		maxf(row_size.y, 1.0)
	))


func _on_boss_reward_selected(option_index: int) -> void:
	if not boss_reward_active or option_index < 0 or option_index >= boss_reward_options.size():
		return
	var option: Dictionary = boss_reward_options[option_index]
	_play_card_select_sound()

	var salvage_gain := int(option.get("salvage", 0))
	var coin_gain := int(option.get("coins", 0))
	var life_gain := int(option.get("lives", 0))
	var reroll_gain := int(option.get("rerolls", 0))
	var banish_gain := int(option.get("banishes", 0))

	if salvage_gain > 0:
		_award_run_salvage(salvage_gain)
		run_boss_salvage_reward += salvage_gain
	if coin_gain > 0:
		GameManager.add_coins(coin_gain)
		run_coins_collected += coin_gain
		_refresh_shop_button_text()
	for _life_index in range(life_gain):
		GameManager.add_life()
	if life_gain > 0:
		update_labels()
		pulse_lives_hud()
	GameManager.rerolls_remaining += reroll_gain
	GameManager.banishes_remaining += banish_gain

	if bool(option.get("bank", false)):
		var banked: int = GameManager.bank_carried_salvage()
		_show_reward_banner(
			"KASAYA ALINDI",
			[{"icon": ICON_SALVAGE, "text": "+%d" % banked}],
			Color(0.16, 0.88, 0.48, 1.0),
			SFX_BONUS_REWARD
		)

	var curse_id: StringName = option.get("curse_id", &"none")
	if curse_id != &"none" and GameManager.accept_curse(curse_id):
		update_labels()
		_show_reward_banner(
			"LANET KABUL EDİLDİ",
			[{"icon": ICON_DEPTH, "text": "KAZANÇ x%.2f" % GameManager.get_curse_gain_multiplier()}],
			Color(1.00, 0.34, 0.34, 1.0),
			SFX_NEW_RECORD
		)
		refresh_dynamic_build_difficulty()

	print("BOSS REWARD PICKED: %s | parca=%d coin=%d can=%d reroll=%d banish=%d" % [
		option.get("id", &"?"), salvage_gain, coin_gain, life_gain, reroll_gain, banish_gain
	])

	boss_reward_screen.visible = false
	boss_reward_active = false
	boss_reward_options = []
	_play_reward_sfx(SFX_BOSS_REWARD)
	_try_resolve_pending_rewards()


func _get_boss_combat_offset(boss_type: StringName) -> float:
	match boss_type:
		&"sentinel":
			return 190.0
		&"celestial":
			return 215.0
		&"void":
			return 220.0
		&"sovereign":
			return 240.0
		&"architect":
			return 235.0
		&"chronoform":
			return 225.0
		_:
			return 170.0


func notify_boss_projectile_fired() -> void:
	if boss_active and is_instance_valid(brick_field):
		brick_field.notify_boss_projectile_fired()


func notify_boss_side_wave_spawned(separation_seconds: float) -> void:
	if boss_active and is_instance_valid(active_boss) and active_boss.has_method("delay_projectile_after_side_wave"):
		active_boss.delay_projectile_after_side_wave(separation_seconds)


func _setup_boss_hud(boss_type: StringName) -> void:
	_ensure_sentinel_hud_indicators()
	boss_hp_bar.modulate = Color.WHITE
	sentinel_feedback_label.visible = false
	sentinel_feedback_label.size.x = boss_hp_panel.size.x
	if boss_type == &"sentinel":
		boss_name_label.text = "THE SENTINEL"
		boss_name_label.size.x = 120.0
		sentinel_left_indicator.visible = true
		sentinel_right_indicator.visible = true
		sentinel_shield_indicator.visible = true
		_on_sentinel_generator_state_changed(true, true, true)
		if not sentinel_hint_shown:
			sentinel_hint_shown = true
			call_deferred(
				"_show_hud_status",
				"ÇEKİRDEĞİ AÇMAK İÇİN İKİ JENERATÖRÜ DE YOK ET",
				Color(0.58, 0.96, 1.0, 1.0),
				2.2
			)
	else:
		boss_name_label.text = _get_boss_display_name(boss_type)
		boss_name_label.size.x = 210.0 if boss_type in [&"sovereign", &"architect"] else 168.0 if boss_type == &"chronoform" else (178.0 if boss_type == &"void" else (150.0 if boss_type == &"celestial" else 112.0))
		sentinel_left_indicator.visible = false
		sentinel_right_indicator.visible = false
		sentinel_shield_indicator.visible = false
		if boss_type == &"celestial":
			boss_hp_bar.modulate = Color(0.86, 0.62, 1.0, 1.0)
		elif boss_type in [&"void", &"sovereign", &"architect", &"chronoform"]:
			boss_hp_bar.modulate = Color(0.36, 0.96, 0.94, 1.0)


func _ensure_sentinel_hud_indicators() -> void:
	if is_instance_valid(sentinel_left_indicator):
		return
	sentinel_left_indicator = Label.new()
	sentinel_left_indicator.name = "SentinelLeftGenerator"
	sentinel_left_indicator.text = "SOL JENERAT\u00D6R"
	sentinel_left_indicator.position = Vector2(120.0, 3.0)
	sentinel_left_indicator.size = Vector2(96.0, 22.0)
	sentinel_left_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sentinel_left_indicator.add_theme_font_size_override("font_size", 12 if OS.has_feature("mobile") else 11)
	boss_hp_panel.add_child(sentinel_left_indicator)
	sentinel_right_indicator = Label.new()
	sentinel_right_indicator.name = "SentinelRightGenerator"
	sentinel_right_indicator.text = "SA\u011E JENERAT\u00D6R"
	sentinel_right_indicator.position = Vector2(216.0, 3.0)
	sentinel_right_indicator.size = Vector2(96.0, 22.0)
	sentinel_right_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sentinel_right_indicator.add_theme_font_size_override("font_size", 12 if OS.has_feature("mobile") else 11)
	boss_hp_panel.add_child(sentinel_right_indicator)
	sentinel_shield_indicator = Label.new()
	sentinel_shield_indicator.name = "SentinelShieldState"
	sentinel_shield_indicator.text = "KALKANLI"
	sentinel_shield_indicator.position = Vector2(312.0, 3.0)
	sentinel_shield_indicator.size = Vector2(96.0, 22.0)
	sentinel_shield_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sentinel_shield_indicator.add_theme_font_size_override("font_size", 13 if OS.has_feature("mobile") else 12)
	boss_hp_panel.add_child(sentinel_shield_indicator)
	sentinel_feedback_label = Label.new()
	sentinel_feedback_label.name = "SentinelStatusFeedback"
	sentinel_feedback_label.position = Vector2(0.0, 49.0)
	sentinel_feedback_label.size = Vector2(420.0, 28.0)
	sentinel_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sentinel_feedback_label.add_theme_font_size_override("font_size", 17)
	sentinel_feedback_label.visible = false
	sentinel_feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hp_panel.add_child(sentinel_feedback_label)


func _on_sentinel_generator_state_changed(left_active: bool, right_active: bool, shielded: bool) -> void:
	_ensure_sentinel_hud_indicators()
	sentinel_left_indicator.modulate = Color(0.42, 1.0, 0.92, 1.0) if left_active else Color(0.28, 0.34, 0.40, 0.48)
	sentinel_right_indicator.modulate = Color(0.42, 1.0, 0.92, 1.0) if right_active else Color(0.28, 0.34, 0.40, 0.48)
	sentinel_left_indicator.text = "SOL JENERAT\u00D6R" if left_active else "SOL JENERAT\u00D6R \u2014"
	sentinel_right_indicator.text = "SA\u011E JENERAT\u00D6R" if right_active else "SA\u011E JENERAT\u00D6R \u2014"
	sentinel_shield_indicator.text = "KALKANLI" if shielded else "\u00C7EK\u0130RDEK A\u00C7IK"
	sentinel_shield_indicator.modulate = Color(0.48, 0.96, 1.0, 1.0) if shielded else Color(1.0, 0.55, 0.20, 1.0)
	boss_hp_bar.modulate = Color(0.62, 0.92, 1.0, 1.0) if shielded else Color(1.0, 0.64, 0.30, 1.0)


func _on_sentinel_status_feedback(message: String, tone: StringName) -> void:
	_ensure_sentinel_hud_indicators()
	if is_instance_valid(sentinel_feedback_tween):
		sentinel_feedback_tween.kill()
	sentinel_feedback_label.text = message
	sentinel_feedback_label.modulate = Color(0.58, 0.96, 1.0, 1.0) if tone == &"shield" else Color(1.0, 0.58, 0.18, 1.0)
	sentinel_feedback_label.scale = Vector2.ONE * 0.90
	sentinel_feedback_label.pivot_offset = sentinel_feedback_label.size * 0.5
	sentinel_feedback_label.visible = true
	sentinel_feedback_tween = sentinel_feedback_label.create_tween()
	sentinel_feedback_tween.tween_property(sentinel_feedback_label, "scale", Vector2.ONE * 1.06, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sentinel_feedback_tween.tween_property(sentinel_feedback_label, "scale", Vector2.ONE, 0.10)
	sentinel_feedback_tween.tween_interval(0.48)
	sentinel_feedback_tween.tween_property(sentinel_feedback_label, "modulate:a", 0.0, 0.22)
	sentinel_feedback_tween.tween_callback(func() -> void: sentinel_feedback_label.visible = false)

func _on_boss_health_changed(current_hp: int, _max_hp: int) -> void:
	if is_instance_valid(boss_hp_tween):
		boss_hp_tween.kill()
	boss_hp_tween = boss_hp_bar.create_tween()
	boss_hp_tween.tween_property(boss_hp_bar, "value", float(current_hp), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_boss_defeated() -> void:
	if is_instance_valid(brick_field):
		brick_field.stop_boss_side_waves()
	var defeated_progression_boss := active_boss_is_progression
	var defeated_boss_type := active_boss_type
	active_boss_is_progression = false
	active_boss_type = &"none"
	if defeated_progression_boss:
		GameManager.evolution_credits += 1
		run_progression_boss_kills += 1
	boss_hp_panel.visible = false
	boss_hp_bar.modulate = Color.WHITE
	active_boss = null
	await get_tree().create_timer(1.5).timeout
	if game_over:
		return
	boss_active = false
	$HUD/ComboManager.reset_combo()
	if defeated_progression_boss and defeated_boss_type == &"core":
		first_boss_defeated = true
		boss_pending = false
		pending_boss_type = &"none"
		if is_instance_valid(brick_field):
			var pre_boss_interval: float = brick_field.row_step_interval
			GameManager.post_boss_descent_multiplier = 0.84 if OS.has_feature("mobile") else 0.88
			brick_field.resume_after_progression_boss(FIRST_POST_BOSS_DEPTH)
			print("BOSS DESCENT INTERVAL | before=%.3f after=%.3f multiplier=%.2f" % [pre_boss_interval, brick_field.row_step_interval, GameManager.post_boss_descent_multiplier])
	elif defeated_progression_boss and defeated_boss_type == &"sentinel":
		second_boss_defeated = true
		boss_pending = false
		pending_boss_type = &"none"
		if is_instance_valid(brick_field):
			brick_field.resume_after_progression_boss(SECOND_POST_BOSS_DEPTH)
	elif defeated_progression_boss and defeated_boss_type == &"celestial":
		third_boss_defeated = true
		boss_pending = false
		pending_boss_type = &"none"
		if is_instance_valid(brick_field):
			brick_field.resume_after_progression_boss(THIRD_POST_BOSS_DEPTH)
	elif defeated_progression_boss and defeated_boss_type == &"void":
		fourth_boss_defeated = true
		boss_pending = false
		pending_boss_type = &"none"
		if is_instance_valid(brick_field):
			brick_field.resume_after_progression_boss(FOURTH_POST_BOSS_DEPTH)
	elif defeated_progression_boss and defeated_boss_type == &"sovereign":
		fifth_boss_defeated = true
		boss_pending = false
		pending_boss_type = &"none"
		if is_instance_valid(brick_field):
			brick_field.resume_after_progression_boss(FIFTH_POST_BOSS_DEPTH)
	elif defeated_progression_boss and defeated_boss_type == &"architect":
		sixth_boss_defeated = true
		boss_pending = false
		pending_boss_type = &"none"
		if is_instance_valid(brick_field):
			brick_field.resume_after_progression_boss(SIXTH_POST_BOSS_DEPTH)
	elif defeated_progression_boss and defeated_boss_type == &"chronoform":
		seventh_boss_defeated = true
		boss_pending = false
		pending_boss_type = &"none"
		if is_instance_valid(brick_field):
			brick_field.resume_after_progression_boss(SEVENTH_POST_BOSS_DEPTH)
		# Son boss: run kazanıldı. Ödül ekranı yerine zafer ekranı gelir.
		_trigger_run_victory()
		return
	elif boss_pending:
		call_deferred("_try_start_pending_boss")
	elif is_instance_valid(brick_field):
		brick_field.resume_after_boss()
	print("BrickField resumed")
	if defeated_progression_boss:
		_award_boss_defeat_rewards(defeated_boss_type)

# ==================================================
# ZAFER VE ASCENSION
# ==================================================

func _trigger_run_victory() -> void:
	if run_victory:
		return
	run_victory = true
	# Taşınan PARÇA zaferle birlikte tam olarak güvenceye alınır — kayıp yok.
	var banked: int = GameManager.bank_carried_salvage()
	var unlocked_new_tier: bool = GameManager.register_ascension_clear()
	print("RUN VICTORY | ascension=%d yeni_katman=%s kasaya_giren=%d" % [
		GameManager.run_ascension, unlocked_new_tier, banked
	])
	_show_victory_screen(banked, unlocked_new_tier)


func _show_victory_screen(banked_salvage: int, unlocked_new_tier: bool) -> void:
	GameManager.pending_card_choices = 0
	game_over = true
	_award_colony_run_end_bonus_once()
	_populate_run_summary()

	choosing_card = false
	$HUD/ComboManager.reset_combo()
	GameManager.magnet_time_remaining = 0.0
	update_magnet_aura_feedback(0.0)
	card_panel.visible = false

	# Game over ekranını zafer moduna çevir — ayrı sahne gerekmez.
	var title := get_node_or_null("GameOverScreen/VBoxContainer/GameOverLabel") as Label
	if is_instance_valid(title):
		title.text = "RUN TAMAMLANDI"
		title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.28, 1.0))

	var lines: Array[String] = [
		"CHRONOFORM YEN\u0130LD\u0130",
		"ASCENSION %d TEMİZLENDİ" % GameManager.run_ascension,
		"KASAYA GİREN: %d PARÇA" % banked_salvage,
	]
	if unlocked_new_tier and GameManager.run_ascension < GameManager.MAX_ASCENSION:
		lines.append("ASCENSION %d AÇILDI" % (GameManager.run_ascension + 1))
	elif GameManager.run_ascension >= GameManager.MAX_ASCENSION:
		lines.append("TÜM ASCENSION KATMANLARI TEMİZLENDİ")
	_show_new_record_badge(false)

	var summary := get_node_or_null("GameOverScreen/VBoxContainer/StatsLabel") as Label
	if is_instance_valid(summary):
		summary.text = String.chr(10).join(lines) + String.chr(10) + String.chr(10) + summary.text

	game_over_screen.visible = true
	get_tree().paused = true
	_play_reward_sfx(SFX_NEW_RECORD)

	if OS.has_feature("mobile"):
		retry_button.focus_mode = Control.FOCUS_NONE
		main_menu_button.focus_mode = Control.FOCUS_NONE
	else:
		retry_button.grab_focus()


## Coin debug butonu yalnizca ana menude gorunur — oyun sirasinda sag alt
## kose mobilde raket dokunma alanina yakin.
## Debug disi derlemede overlay hic olusturulmaz, gecerlilik kontrolu yeterli.
func _refresh_coin_debug_visibility() -> void:
	if is_instance_valid(coin_debug_overlay):
		coin_debug_overlay.visible = main_menu.visible


func _debug_add_test_coins() -> void:
	if not OS.is_debug_build() or OS.has_feature("release"):
		return
	GameManager.add_coins(50)
	_refresh_shop_button_text()
	if is_instance_valid(paddle_shop) and paddle_shop.visible:
		_refresh_paddle_shop()
	print("DEBUG COIN: +50 | total=%d" % GameManager.total_coins)


func _create_coin_debug_overlay() -> void:
	if (
		not OS.is_debug_build()
		or OS.has_feature("release")
		or not OS.has_feature("mobile")
	):
		return
	coin_debug_overlay = CanvasLayer.new()
	coin_debug_overlay.name = "CoinDebugOverlay"
	coin_debug_overlay.layer = 100
	coin_debug_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(coin_debug_overlay)

	coin_debug_button = Button.new()
	coin_debug_button.name = "AddCoinDebugButton"
	coin_debug_button.text = "+50 COIN"
	coin_debug_button.custom_minimum_size = Vector2(126.0, 54.0)
	coin_debug_button.mouse_filter = Control.MOUSE_FILTER_STOP
	coin_debug_button.add_theme_font_size_override("font_size", 18)
	coin_debug_button.pressed.connect(_debug_add_test_coins)
	coin_debug_overlay.add_child(coin_debug_button)

	# SOL UST DEGIL SAG ALT. Eskiden sol ustteydi ve ana menude logonun
	# uzerine biniyordu; guvenli alan duzeltmesinden sonra menu %90 genislige
	# ciktigi icin cakisma daha da artacakti.
	var safe_rect := GameManager.get_layout_safe_rect(get_viewport_rect().size)
	coin_debug_button.size = Vector2(126.0, 54.0)
	coin_debug_button.position = Vector2(
		safe_rect.end.x - 126.0 - 16.0,
		safe_rect.end.y - 54.0 - 56.0
	)
	_refresh_coin_debug_visibility()

func _create_paddle_shop() -> void:
	paddle_shop = CanvasLayer.new()
	paddle_shop.name = "PaddleShop"
	paddle_shop.layer = 55
	paddle_shop.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(paddle_shop)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.004, 0.012, 0.035, 0.94)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	paddle_shop.add_child(backdrop)

	paddle_shop_panel = Panel.new()
	paddle_shop.add_child(paddle_shop_panel)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.055, 0.10, 0.97)
	panel_style.border_color = Color(0.20, 0.88, 1.0, 0.82)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(14)
	paddle_shop_panel.add_theme_stylebox_override("panel", panel_style)

	var layout := VBoxContainer.new()
	layout.name = "ShopLayout"
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 18)
	layout.add_theme_constant_override("separation", 9)
	paddle_shop_panel.add_child(layout)

	var title := Label.new()
	title.text = "GEL\u0130\u015eT\u0130RMELER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.35, 0.95, 1.0, 1.0))
	layout.add_child(title)

	paddle_shop_coin_label = Label.new()
	paddle_shop_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paddle_shop_coin_label.add_theme_font_size_override("font_size", 20)
	paddle_shop_coin_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.18, 1.0))
	layout.add_child(paddle_shop_coin_label)

	for paddle_id: StringName in GameManager.PADDLE_IDS:
		var paddle_button := Button.new()
		paddle_button.custom_minimum_size = Vector2(440.0, 76.0)
		paddle_button.text = ""
		paddle_button.pressed.connect(_on_paddle_shop_pressed.bind(paddle_id))
		layout.add_child(paddle_button)
		paddle_shop_buttons[paddle_id] = paddle_button

		var preview := TextureRect.new()
		preview.texture = _get_paddle_shop_texture(paddle_id)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.position = Vector2(10.0, 10.0)
		preview.size = Vector2(142.0, 56.0)
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		paddle_button.add_child(preview)
		paddle_shop_images[paddle_id] = preview

		var copy_label := Label.new()
		copy_label.position = Vector2(160.0, 4.0)
		copy_label.size = Vector2(270.0, 68.0)
		copy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		copy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		copy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy_label.add_theme_font_size_override("font_size", 14)
		copy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		paddle_button.add_child(copy_label)
		paddle_shop_text_labels[paddle_id] = copy_label

	paddle_shop_status_label = Label.new()
	paddle_shop_status_label.custom_minimum_size = Vector2(0.0, 24.0)
	paddle_shop_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paddle_shop_status_label.add_theme_font_size_override("font_size", 15)
	paddle_shop_status_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.32, 1.0))
	layout.add_child(paddle_shop_status_label)

	var back_button := Button.new()
	back_button.text = "GER\u0130"
	back_button.custom_minimum_size = Vector2(240.0, 48.0)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_size_override("font_size", 22)
	back_button.pressed.connect(_close_paddle_shop)
	layout.add_child(back_button)
	paddle_shop_buttons[&"BACK"] = back_button

	paddle_shop.visible = false
	_layout_paddle_shop()


func _layout_paddle_shop() -> void:
	if not is_instance_valid(paddle_shop_panel):
		return
	var viewport_size := get_viewport_rect().size
	var safe_rect := GameManager.get_layout_safe_rect(viewport_size)
	var panel_width := minf(560.0, safe_rect.size.x - 28.0)
	var panel_height := minf(610.0, safe_rect.size.y - 36.0)
	_set_mobile_rect(paddle_shop_panel, Rect2(
		safe_rect.position.x + (safe_rect.size.x - panel_width) * 0.5,
		safe_rect.position.y + (safe_rect.size.y - panel_height) * 0.5,
		panel_width,
		panel_height
	))


func _on_total_coins_changed(total: int) -> void:
	if is_instance_valid(total_coin_label):
		total_coin_label.text = str(total)


func _refresh_shop_button_text() -> void:
	if is_instance_valid(shop_button):
		shop_button.text = ""
func _get_paddle_shop_texture(paddle_id: StringName) -> Texture2D:
	match paddle_id:
		GameManager.PADDLE_PLASMA:
			return SHOP_PLASMA_PADDLE_TEXTURE
		GameManager.PADDLE_FIRE:
			return SHOP_FIRE_PADDLE_TEXTURE
		GameManager.PADDLE_PIERCING:
			return SHOP_PIERCING_PADDLE_TEXTURE
		GameManager.PADDLE_NEON_CORE:
			return SHOP_NEON_CORE_PADDLE_TEXTURE
	return SHOP_NEUTRAL_PADDLE_TEXTURE


func _get_paddle_shop_copy(paddle_id: StringName) -> String:
	# Metin art\u0131k tek kaynaktan: GameManager.PADDLE_PROFILES.
	var profile := GameManager.get_paddle_profile(paddle_id)
	var separator := String.chr(10)
	var stat_bits: Array[String] = []
	stat_bits.append("%d CAN" % int(profile.get("lives", 3)))
	var width_percent := int(round((float(profile.get("width", 1.0)) - 1.0) * 100.0))
	if width_percent != 0:
		stat_bits.append("GEN\u0130\u015eL\u0130K %+d%%" % width_percent)
	var speed_percent := int(round((float(profile.get("speed", 1.0)) - 1.0) * 100.0))
	if speed_percent != 0:
		stat_bits.append("HIZ %+d%%" % speed_percent)
	return "%s RAKET%s%s%s%s" % [
		String(profile.get("name", String(paddle_id))),
		separator,
		" \u00b7 ".join(stat_bits),
		separator,
		String(profile.get("trait", "")),
	]

func _refresh_paddle_shop() -> void:
	paddle_shop_coin_label.text = "COIN: %d" % GameManager.total_coins
	paddle_shop_status_label.text = ""
	for paddle_id: StringName in GameManager.PADDLE_IDS:
		var button := paddle_shop_buttons[paddle_id] as Button
		var action := ""
		if GameManager.active_paddle_id == paddle_id:
			action = "AKT\u0130F"
			button.modulate = _get_paddle_affinity_color(paddle_id)
		elif GameManager.owned_paddles.has(paddle_id):
			action = "AKT\u0130F ET"
			button.modulate = Color.WHITE
		else:
			action = "SATIN AL \u2014 %d" % int(GameManager.PADDLE_PRICES[paddle_id])
			button.modulate = Color(0.78, 0.84, 0.90, 1.0)
		var copy_label := paddle_shop_text_labels[paddle_id] as Label
		copy_label.text = _get_paddle_shop_copy(paddle_id) + String.chr(10) + action


func _get_paddle_affinity_color(paddle_id: StringName) -> Color:
	match paddle_id:
		GameManager.PADDLE_PLASMA:
			return Color(0.58, 1.0, 0.62, 1.0)
		GameManager.PADDLE_FIRE:
			return Color(1.0, 0.48, 0.42, 1.0)
		GameManager.PADDLE_PIERCING:
			return Color(0.82, 0.58, 1.0, 1.0)
	return Color(0.72, 0.95, 1.0, 1.0)


func _open_colony() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://colony.tscn")


func _open_paddle_shop() -> void:
	_refresh_paddle_shop()
	main_menu.visible = false
	_refresh_coin_debug_visibility()
	paddle_shop.visible = true
	if OS.has_feature("mobile"):
		for shop_control in paddle_shop_buttons.values():
			(shop_control as Button).focus_mode = Control.FOCUS_NONE
	else:
		(paddle_shop_buttons[GameManager.PADDLE_NEUTRAL] as Button).grab_focus()


func _close_paddle_shop() -> void:
	paddle_shop.visible = false
	main_menu.visible = true
	_refresh_coin_debug_visibility()
	_refresh_shop_button_text()
	if not OS.has_feature("mobile"):
		shop_button.grab_focus()


func _on_paddle_shop_pressed(paddle_id: StringName) -> void:
	if GameManager.owned_paddles.has(paddle_id):
		GameManager.activate_paddle(paddle_id)
	else:
		if not GameManager.purchase_paddle(paddle_id):
			paddle_shop_status_label.text = "YETERL\u0130 COIN YOK"
			return
	_refresh_paddle_shop()
	_refresh_shop_button_text()

# ==================================================
# YENÃƒâ€Ã‚Â° OYUN
# ==================================================

func start_new_game():

	GameManager.reset_run()

	GameManager.start_directly = true


	get_tree().paused = false
	get_tree().reload_current_scene()


# ==================================================
# ÃƒÆ’Ã¢â‚¬Â¡IKIÃƒâ€¦Ã‚Â
# ==================================================

func toggle_pause_menu() -> void:
	if pause_menu_active:
		resume_from_pause_menu()
		return
	if game_over or choosing_card or evolution_selection_active or main_menu.visible or card_panel.visible or evolution_panel.visible:
		return
	pause_menu_active = true
	pause_menu.visible = true
	get_tree().paused = true
	if not OS.has_feature("mobile"):
		pause_resume_button.grab_focus()


func resume_from_pause_menu() -> void:
	if not pause_menu_active:
		return
	pause_menu_active = false
	pause_menu.visible = false
	if boss_active or boss_warning_running:
		get_tree().paused = false
	else:
		_try_resolve_pending_rewards()
	if is_instance_valid(pause_resume_button):
		pause_resume_button.release_focus()


func return_to_main_menu_from_pause() -> void:
	pause_menu_active = false
	pause_menu.visible = false
	get_tree().paused = false
	return_to_main_menu()


func toggle_music() -> void:
	GameManager.music_enabled = not GameManager.music_enabled
	if music_controller.has_method("set_music_enabled"):
		music_controller.call("set_music_enabled", GameManager.music_enabled)
	_refresh_music_button_text()


func _refresh_music_button_text() -> void:
	if not is_instance_valid(music_button):
		return
	music_button.text = ""
	music_button.icon = MENU_MUSIC_ON_TEXTURE if GameManager.music_enabled else MENU_MUSIC_OFF_TEXTURE
func _setup_main_menu_button_feedback() -> void:
	for menu_button: Button in [new_game_button, shop_button, colony_button, music_button, quit_button]:
		menu_button.pivot_offset = menu_button.size * 0.5
		menu_button.button_down.connect(_on_main_menu_button_down.bind(menu_button))
		menu_button.button_up.connect(_on_main_menu_button_up.bind(menu_button))


func _on_main_menu_button_down(menu_button: Button) -> void:
	menu_button.scale = Vector2.ONE * 0.96
	menu_button.modulate = Color(0.82, 1.0, 1.0, 1.0)


func _on_main_menu_button_up(menu_button: Button) -> void:
	var tween := menu_button.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(menu_button, "scale", Vector2.ONE, 0.10)
	tween.parallel().tween_property(menu_button, "modulate", Color.WHITE, 0.10)


func quit_game():

	get_tree().quit()


# ==================================================
# TUÃƒâ€Ã‚ÂLA KIRILDI
# ==================================================

func brick_destroyed(brick_position, brick_color, source = "ball", damage_context = null, brick_instance_id: int = 0):

	if game_over or choosing_card:
		return

	bricks_left -= 1
	if boss_pending:
		_try_start_pending_boss()
	var unique_destroy := _register_destroyed_brick_for_summary(brick_instance_id)
	var drop_chance_multiplier := 1.0
	var destroyed_brick := instance_from_id(brick_instance_id) as Node
	if is_instance_valid(destroyed_brick) and bool(destroyed_brick.get_meta("is_side_wave_brick", false)):
		drop_chance_multiplier = SIDE_WAVE_DROP_MULTIPLIER
	# Elit tugla: yuksek can karsiliginda degerli dusurme. Elit hicbir zaman
	# yan dalgada cikmadigi icin iki carpan cakismaz.
	if is_instance_valid(destroyed_brick) and bool(destroyed_brick.get_meta("is_elite_brick", false)):
		drop_chance_multiplier = EliteBricks.DROP_MULTIPLIER
	if unique_destroy:
		var row_xp_scale := float(destroyed_brick.get_meta("xp_row_scale", 1.0)) if is_instance_valid(destroyed_brick) else 1.0
		_resolve_brick_collectible_drop(brick_position, drop_chance_multiplier, row_xp_scale)
		var resonance_became_ready := GameManager.register_core_resonance_weapon_kill(
			StringName(source)
		)
		if resonance_became_ready and OS.is_debug_build():
			print("CORE RESONANCE READY: %s" % GameManager.get_active_core_module_id())
	$HUD/FrameGlow.flash(brick_color)
	var contributes_to_combo = true
	if source == "explosion" and damage_context is Dictionary:
		var explosion_combo_hits = int(damage_context.get("combo_hits", 0))
		contributes_to_combo = explosion_combo_hits < 3
		if contributes_to_combo:
			damage_context["combo_hits"] = explosion_combo_hits + 1


	if contributes_to_combo:
		$ChainLightningManager.register_brick_kill(source, damage_context)
		var combo_shake = $HUD/ComboManager.register_break()
		$WorldShake.start_break(combo_shake)

	BrickBreakAudio.play_break()




	# --------------------------------------------------
	# TÃƒÆ’Ã…â€œM TOPLARI HIZLANDIR
	# --------------------------------------------------

	var balls = get_tree().get_nodes_in_group(
		"game_ball"
	)

	for ball in balls:

		if ball.has_method("increase_speed"):

			ball.increase_speed(get_ball_acceleration_scale())


	# --------------------------------------------------
	# RAKETÃƒâ€Ã‚Â° HIZLANDIR
	# --------------------------------------------------

	var paddles = get_tree().get_nodes_in_group(
		"game_paddle"
	)

	for paddle_node in paddles:

		if paddle_node.has_method("increase_speed"):

			paddle_node.increase_speed()


	update_labels()


	# --------------------------------------------------
	# LEVEL BÃƒâ€Ã‚Â°TTÃƒâ€Ã‚Â°
	# --------------------------------------------------

	# Continuous run'da son brick level completion veya sahne reload tetiklemez.


func get_ball_acceleration_scale() -> float:
	if GameManager.run_depth <= 3:
		return 0.25
	if not first_boss_defeated:
		return 0.50
	return 1.0


func register_spawned_bricks(amount):

	bricks_left += amount


func unregister_danger_brick():

	bricks_left = maxi(bricks_left - 1, 0)
	if boss_pending:
		_try_start_pending_boss()


func apply_danger_damage():

	lose_life(&"danger")


func apply_enemy_projectile_damage():

	if game_over or enemy_projectile_damage_locked:
		return

	enemy_projectile_damage_locked = true
	$HUD/ComboManager.reset_combo()
	_play_enemy_projectile_hit_feedback()
	lose_life(&"enemy_projectile")

	await get_tree().create_timer(0.70).timeout
	enemy_projectile_damage_locked = false


func _play_enemy_projectile_hit_feedback() -> void:
	if not is_instance_valid(paddle):
		return
	if is_instance_valid(enemy_hit_feedback_tween):
		enemy_hit_feedback_tween.kill()
	paddle.modulate = Color(1.35, 0.42, 0.38, 1.0)
	enemy_hit_feedback_tween = paddle.create_tween()
	enemy_hit_feedback_tween.tween_property(
		paddle,
		"modulate",
		Color.WHITE,
		0.13
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func update_depth_debug_label(_step_interval = -1.0, _next_step = -1.0):

	if is_instance_valid(depth_label):
		depth_label.text = "DEPTH " + str(GameManager.run_depth)


# ==================================================
# XP SÃƒâ€Ã‚Â°STEMÃƒâ€Ã‚Â°
# ==================================================

func _resolve_brick_collectible_drop(spawn_position: Vector2, drop_multiplier: float, row_xp_scale: float = 1.0) -> void:
	# One shared roll gives every destroyed brick either zero or one collectible.
	# Ineligible Heart/Magnet slots remain no-drop so other probabilities do not increase.
	var effective_orb_chance := float(exp_orb_drop_chance)
	if not GameManager.first_card_selection_done:
		effective_orb_chance *= 1.50
	# Tarama Dizisi karti tum drop sanslarini yukseltir.
	drop_multiplier *= GameManager.get_drop_rate_multiplier()
	var coin_chance: float = GameManager.get_effective_coin_drop_chance(float(coin_drop_chance), drop_multiplier)
	var orb_chance: float = effective_orb_chance * drop_multiplier
	var heart_chance: float = float(heart_drop_chance) * drop_multiplier
	var magnet_chance: float = float(magnet_drop_chance) * drop_multiplier
	var wide_pickup_chance: float = float(wide_paddle_pickup_drop_chance) * drop_multiplier
	# Ekstra top artik aktifken de duser; kartopu olmasin diye sans sahnedeki
	# top sayisiyla ters orantili olceklenir (bkz. _extra_ball_drop_scale).
	var extra_ball_chance: float = (
		float(extra_ball_pickup_drop_chance) * drop_multiplier * _extra_ball_drop_scale()
	)
	# Hurda Dedektoru karti yalnizca PARCA drop'unu ayrica katlar.
	var building_part_chance: float = (
		GameManager.BUILDING_PART_DROP_CHANCE
		* drop_multiplier
		* GameManager.get_salvage_drop_multiplier()
	)
	var drop_roll: float = randf()
	var range_end: float = building_part_chance
	if drop_roll < range_end:
		spawn_building_part_pickup(spawn_position)
		return
	range_end += coin_chance
	if drop_roll < range_end:
		spawn_coin_pickup(spawn_position)
		return
	range_end += orb_chance
	if drop_roll < range_end:
		spawn_xp_orb(spawn_position, row_xp_scale)
		return
	range_end += heart_chance
	if drop_roll < range_end:
		# Tam candayken Heart normalde bos gecer. Teknoloji Merkezi Lv2+ varsa
		# dusmeye devam eder ve PARCA'ya donusur (bkz. collect_heart).
		if (
			GameManager.lives < GameManager.MAX_LIVES
			or GameManager.get_colony_full_life_heart_salvage() > 0
		):
			spawn_heart_pickup(spawn_position)
		return
	range_end += magnet_chance
	if drop_roll < range_end:
		if GameManager.magnet_time_remaining <= 0.0:
			spawn_magnet_pickup(spawn_position)
		return
	range_end += wide_pickup_chance
	if drop_roll < range_end:
		if wide_paddle_pickup_time_remaining <= 0.0:
			spawn_temporary_power_pickup(spawn_position, &"wide_paddle")
		return
	range_end += extra_ball_chance
	if drop_roll < range_end:
		spawn_temporary_power_pickup(spawn_position, &"extra_ball")
		return


func spawn_xp_orb(brick_position, row_xp_scale: float = 1.0):

	var orb = xp_orb_scene.instantiate()
	orb.xp_row_scale = row_xp_scale
	add_child(orb)
	orb.global_position = brick_position


func spawn_coin_pickup(spawn_position: Vector2) -> void:
	var coin := coin_pickup_scene.instantiate()
	add_child(coin)
	coin.global_position = spawn_position


func spawn_building_part_pickup(spawn_position: Vector2) -> void:
	var pickup := building_part_pickup_scene.instantiate()
	add_child(pickup)
	pickup.global_position = spawn_position
	print("BUILDING PART DROPPED")


func _award_run_salvage(amount: int) -> void:
	# Run içinde kazanılan tüm PARÇA tek noktadan geçsin ki özet doğru olsun.
	# Faz 4: lanet çarpanı burada uygulanır ve PARÇA doğrudan depoya değil,
	# önce "taşınan" havuzuna gider. Boss sonrası güvenceye alınabilir;
	# alınmadan ölünürse yarısı kaybolur.
	if amount <= 0:
		return
	var multiplied: int = maxi(1, roundi(
		float(amount) * GameManager.get_curse_gain_multiplier()
	))
	run_salvage_earned += multiplied
	GameManager.carry_salvage(multiplied)


func collect_building_part(_pickup_position: Vector2) -> void:
	_award_run_salvage(1)
	print("BUILDING PART COLLECTED - TOTAL: %d" % GameManager.total_salvage)


func _clear_building_part_pickups() -> void:
	for pickup in get_tree().get_nodes_in_group("building_part_pickup"):
		if is_instance_valid(pickup):
			pickup.queue_free()

func _clear_exp_orb_pickups() -> void:
	for orb in get_tree().get_nodes_in_group("exp_orb_pickup"):
		if is_instance_valid(orb):
			orb.queue_free()

func collect_coin(_pickup_position: Vector2) -> void:
	var gained: int = maxi(1, roundi(GameManager.get_curse_gain_multiplier()))
	run_coins_collected += gained
	GameManager.add_coins(gained)
	_refresh_shop_button_text()

func spawn_heart_pickup(spawn_position):

	var heart = heart_pickup_scene.instantiate()
	add_child(heart)
	heart.global_position = spawn_position


func spawn_magnet_pickup(spawn_position):

	var magnet = magnet_pickup_scene.instantiate()
	add_child(magnet)
	magnet.global_position = spawn_position


func spawn_temporary_power_pickup(spawn_position: Vector2, pickup_type: StringName) -> void:
	var pickup := temporary_power_pickup_scene.instantiate()
	pickup.configure(pickup_type)
	add_child(pickup)
	pickup.global_position = spawn_position


func activate_wide_paddle_pickup() -> void:
	wide_paddle_pickup_time_remaining = TEMPORARY_PICKUP_DURATION
	paddle.apply_wide_level(1)


## Sahnedeki top sayisini IKIYE KATLAR (MAX_ACTIVE_BALLS tavanina kadar).
##
## Eskiden tek gecici top ekliyordu ve zamanla kayboluyordu. Artik katlama
## yapiyor ve toplar KALICI - dogal yoldan (rakete carpamayip dusunce)
## azaliyorlar. Sureli olsaydi katlanan toplarin yarisi bir anda yok olurdu,
## bu da odul gibi degil ceza gibi hissettirirdi.
func activate_extra_ball_pickup() -> int:
	var mevcut: int = _active_ball_count()
	if mevcut <= 0:
		return 0
	var eklenecek: int = mini(mevcut, MAX_ACTIVE_BALLS - mevcut)
	var eklenen := 0
	for i in range(eklenecek):
		if spawn_extra_ball(false) == null:
			break
		eklenen += 1
	return eklenen


## Sahnede gercekten ucusta olan top sayisi.
func _active_ball_count() -> int:
	var count := 0
	for ball_node in get_tree().get_nodes_in_group("game_ball"):
		if is_instance_valid(ball_node) and not ball_node.is_queued_for_deletion():
			count += 1
	return count


## Ekstra top dusme sansi, sahnedeki top sayisina gore azalir.
##
## Katlama usteldir: 1 -> 2 -> 4 -> 8. Sabit oranla dusseydi kartopu olurdu.
## Cok topu olan oyuncu daha az gorur, tavandayken hic gormez.
func _extra_ball_drop_scale() -> float:
	var balls: int = _active_ball_count()
	if balls >= MAX_ACTIVE_BALLS:
		return 0.0
	return 1.0 / float(maxi(balls, 1))

func activate_magnet(duration = 10.0):

	# Koloni Teknoloji Merkezi ile Cekim Alani karti birlikte carpilir.
	GameManager.set_magnet_time(
		duration
		* GameManager.get_colony_magnet_duration_multiplier()
		* GameManager.get_magnet_duration_multiplier()
	)
	update_magnet_aura_feedback(0.0)

func _process(delta):
	if not game_over and not main_menu.visible:
		run_elapsed_seconds += delta
	_try_play_pending_sector_transition()
	if OS.has_feature("mobile"):
		mobile_safe_area_refresh_timer -= delta
		if mobile_safe_area_refresh_timer <= 0.0:
			mobile_safe_area_refresh_timer = 0.5
			var previous_safe_rect := GameManager.mobile_safe_rect
			var refreshed_safe_rect := GameManager.refresh_mobile_safe_area(get_viewport_rect().size)
			if (
				previous_safe_rect.position.distance_to(refreshed_safe_rect.position) > 0.25
				or previous_safe_rect.size.distance_to(refreshed_safe_rect.size) > 0.25
			):
				call_deferred("_refresh_mobile_safe_layout")

	if not game_over and not main_menu.visible:
		_update_temporary_pickup_effects(delta)

	if not game_over and GameManager.magnet_time_remaining > 0.0:
		GameManager.magnet_time_remaining = maxf(
			GameManager.magnet_time_remaining - delta,
			0.0
		)

	update_magnet_aura_feedback(delta)
	ui_feedback_refresh_left -= delta
	if ui_feedback_refresh_left <= 0.0:
		ui_feedback_refresh_left = UI_FEEDBACK_REFRESH_INTERVAL
		_refresh_build_identity_hud()
		_update_danger_line_feedback()


func _update_temporary_pickup_effects(delta: float) -> void:
	if wide_paddle_pickup_time_remaining > 0.0:
		wide_paddle_pickup_time_remaining = maxf(wide_paddle_pickup_time_remaining - delta, 0.0)
		if wide_paddle_pickup_time_remaining <= 0.0:
			paddle.apply_wide_level(0)


func update_magnet_aura_feedback(delta):

	var active = GameManager.magnet_time_remaining > 0.0
	magnet_aura.visible = active
	if not active:
		return
	magnet_pulse_time += delta
	magnet_aura.modulate.a = 0.20 + sin(magnet_pulse_time * 3.2) * 0.05


func get_lives_hud_target_position():

	return lives_panel.global_position + lives_panel.size * 0.5


func collect_heart():

	if not GameManager.add_life():
		# Maksimum candayken Heart PARCA'ya donusur (Teknoloji Merkezi Lv2+).
		var salvage_bonus: int = GameManager.get_colony_full_life_heart_salvage()
		if salvage_bonus > 0:
			_award_run_salvage(salvage_bonus)
			_show_reward_banner(
				"HEART DONUSTURULDU",
				[{"icon": ICON_SALVAGE, "text": "+%d" % salvage_bonus}],
				Color(1.0, 0.42, 0.58, 1.0),
				SFX_BONUS_REWARD
			)
		return

	update_labels()
	pulse_lives_hud()

func pulse_lives_hud():

	lives_panel.scale = Vector2.ONE
	var tween = lives_panel.create_tween()
	tween.tween_property(lives_panel, "scale", Vector2(1.05, 1.05), 0.08)
	tween.tween_property(lives_panel, "scale", Vector2.ONE, 0.12)


func trigger_chain_lightning(origin_position, primary_brick, source: StringName = &"ball"):

	return $ChainLightningManager.trigger(origin_position, primary_brick, source)


func trigger_fireball_blast(origin_position: Vector2, primary_brick: Node, level: int) -> void:

	var clamped_level := clampi(level, 0, 3)
	var base_radius: float = FIREBALL_BASE_RADII[clamped_level]
	var damage_radius: float = (
		base_radius
		* FIREBALL_RADIUS_MULTIPLIERS[clamped_level]
		* GameManager.get_colony_fire_radius_scale()
	)
	if damage_radius <= 0.0:
		return
	var resonance_boosted := GameManager.consume_core_resonance(&"fireball")
	if resonance_boosted:
		damage_radius *= GameManager.CORE_RESONANCE_FIREBALL_RADIUS_SCALE
	var is_inferno: bool = GameManager.fireball_evolution == &"inferno" and level >= 3
	var is_napalm: bool = GameManager.fireball_evolution == &"napalm" and level >= 3
	if is_inferno:
		damage_radius *= 1.45
	# Görsel ve gameplay aynı tek effective radius değerini kullanır.
	spawn_fireball_visual(origin_position, damage_radius, is_inferno)
	# Tek event context'i primary ve splash hedeflerini instance ID ile deduplicate eder.
	var context = {
		"damaged": {primary_brick.get_instance_id(): true},
		"detonated": {},
		"fireball_combo_hits": 0,
		"combo_hits": 0
	}
	for brick in get_tree().get_nodes_in_group("game_brick"):
		if not is_instance_valid(brick) or brick == primary_brick:
			continue
		if brick.get("is_destroyed") == true:
			continue
		if brick.global_position.distance_to(origin_position) > damage_radius:
			continue
		var brick_id = brick.get_instance_id()
		if context["damaged"].has(brick_id):
			continue
		context["damaged"][brick_id] = true
		if brick.has_method("play_fireball_splash_reaction"):
			brick.play_fireball_splash_reaction()
		brick.hit("fireball", context)
	if level > 0:
		# Aynı effective radius hem ana splash hem affinity hedef aramasında kullanılır.
		var extra_target_count := GameManager.get_colony_fire_extra_targets()
		for _target_index in range(extra_target_count):
			var affinity_target: Node2D
			var nearest_distance := INF
			for candidate_node in get_tree().get_nodes_in_group("game_brick"):
				var candidate := candidate_node as Node2D
				if not is_instance_valid(candidate) or candidate == primary_brick:
					continue
				if candidate.get("is_destroyed") == true:
					continue
				var candidate_id := candidate.get_instance_id()
				if context["damaged"].has(candidate_id):
					continue
				var candidate_distance: float = candidate.global_position.distance_to(origin_position)
				if candidate_distance <= damage_radius * 1.25 and candidate_distance < nearest_distance:
					nearest_distance = candidate_distance
					affinity_target = candidate
			if not is_instance_valid(affinity_target):
				break
			context["damaged"][affinity_target.get_instance_id()] = true
			if affinity_target.has_method("play_fireball_splash_reaction"):
				affinity_target.play_fireball_splash_reaction()
			affinity_target.hit("fireball", context)
	if is_napalm:
		var napalm_radius: float = (
			FIREBALL_BASE_RADII[3] * FIREBALL_RADIUS_MULTIPLIERS[3] * 0.70
		)
		spawn_napalm_field(origin_position, napalm_radius)


func spawn_fireball_visual(origin_position: Vector2, radius: float, enhanced: bool = false) -> void:

	var active_limit := 6 if OS.has_feature("mobile") else 10
	var active_effects := get_tree().get_nodes_in_group("fireball_impact_vfx")
	if active_effects.size() >= active_limit:
		var oldest_effect := active_effects[0] as Node
		if is_instance_valid(oldest_effect):
			oldest_effect.queue_free()

	var effect := Node2D.new()
	effect.name = "FireballImpactVFX"
	effect.add_to_group("fireball_impact_vfx")
	if OS.has_feature("mobile"):
		effect.modulate = Color(1.18, 1.14, 1.08, 1.0)
	effect.global_position = origin_position
	effect.z_index = 34
	add_child(effect)

	# 1) 0.07 saniyelik sÃƒâ€Ã‚Â±cak merkez flash.
	var core_flash := Polygon2D.new()
	var core_points := PackedVector2Array()
	for point_index: int in range(16):
		core_points.append(Vector2.from_angle(TAU * float(point_index) / 16.0) * 8.0)
	core_flash.polygon = core_points
	core_flash.color = Color(1.0, 0.94, 0.72, 0.96)
	core_flash.scale = Vector2.ONE * 0.35
	effect.add_child(core_flash)
	var flash_tween := core_flash.create_tween().set_parallel(true)
	flash_tween.tween_property(core_flash, "scale", Vector2.ONE * (2.5 if enhanced else 2.0), 0.07)
	flash_tween.tween_property(core_flash, "modulate:a", 0.0, 0.07)

	# 2) Ãƒâ€Ã‚Â°nce radial shockwave; yalnÃƒâ€Ã‚Â±zca gÃƒÆ’Ã‚Â¶rseldir.
	var ring := Line2D.new()
	var ring_points := PackedVector2Array()
	for point_index: int in range(33):
		ring_points.append(Vector2.from_angle(TAU * float(point_index) / 32.0) * 12.0)
	ring.points = ring_points
	ring.width = 2.2 if enhanced else 1.8
	ring.default_color = Color(1.0, 0.56, 0.10, 0.92)
	ring.antialiased = true
	effect.add_child(ring)
	var ring_target_scale := radius / 12.0
	var ring_tween := ring.create_tween().set_parallel(true)
	ring_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ring_tween.tween_property(ring, "scale", Vector2.ONE * ring_target_scale, 0.22)
	ring_tween.tween_property(ring, "modulate:a", 0.0, 0.22)

	# 3) SÃƒâ€Ã‚Â±cak fire burst: desktop 14/16, Android 10/12 parÃƒÆ’Ã‚Â§acÃƒâ€Ã‚Â±k.
	var burst_count := (12 if enhanced else 10) if OS.has_feature("mobile") else (16 if enhanced else 14)
	for particle_index: int in range(burst_count):
		var particle := Polygon2D.new()
		var particle_length := randf_range(3.2, 6.2)
		var particle_width := randf_range(0.65, 1.25)
		particle.polygon = PackedVector2Array([
			Vector2(-1.0, -particle_width), Vector2(particle_length, 0.0), Vector2(-1.0, particle_width)
		])
		particle.color = [Color("#FFF0B5"), Color("#FF9A22"), Color("#FF4B12")][particle_index % 3]
		effect.add_child(particle)
		var angle := randf_range(0.0, TAU)
		particle.rotation = angle
		particle.position = Vector2.from_angle(angle) * randf_range(2.0, 8.0)
		var duration := randf_range(0.20, 0.34)
		var travel := randf_range(radius * 0.28, radius * (0.58 if enhanced else 0.48))
		var motion := particle.create_tween().set_parallel(true)
		motion.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		motion.tween_property(particle, "position", Vector2.from_angle(angle) * travel, duration)
		motion.tween_property(particle, "scale", Vector2.ONE * randf_range(0.08, 0.20), duration)
		motion.tween_property(particle, "modulate:a", 0.0, duration)

	# 4) Burst'ten sonra biraz daha uzun yaÃƒâ€¦Ã…Â¸ayan kÃƒÆ’Ã‚Â¼ÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â¼k ember katmanÃƒâ€Ã‚Â±.
	var ember_count := 4 if OS.has_feature("mobile") else 6
	if enhanced:
		ember_count += 2
	for ember_index: int in range(ember_count):
		var ember := Polygon2D.new()
		ember.polygon = PackedVector2Array([
			Vector2(-1.0, -0.7), Vector2(2.2, 0.0), Vector2(-1.0, 0.7)
		])
		ember.color = Color("#FFB340") if ember_index % 2 == 0 else Color("#FF6418")
		effect.add_child(ember)
		var ember_angle := randf_range(0.0, TAU)
		ember.rotation = ember_angle
		ember.position = Vector2.from_angle(ember_angle) * randf_range(8.0, 20.0)
		var ember_duration := randf_range(0.32, 0.48)
		var ember_target := ember.position + Vector2.from_angle(ember_angle) * randf_range(18.0, 42.0) + Vector2(0.0, -10.0)
		var ember_tween := ember.create_tween().set_parallel(true)
		ember_tween.tween_property(ember, "position", ember_target, ember_duration)
		ember_tween.tween_property(ember, "rotation", ember.rotation + randf_range(-1.0, 1.0), ember_duration)
		ember_tween.tween_property(ember, "modulate:a", 0.0, ember_duration)

	var shake_amplitude := (1.0 if enhanced else 0.72) if OS.has_feature("mobile") else (1.45 if enhanced else 1.05)
	if $WorldShake.has_method("start_fireball"):
		$WorldShake.start_fireball(shake_amplitude)
	_play_fireball_impact_sfx()
	get_tree().create_timer(0.52).timeout.connect(effect.queue_free)


func _play_fireball_impact_sfx() -> void:
	# Gelecekte eklenecek ayrÃƒâ€Ã‚Â± Fireball SFX player iÃƒÆ’Ã‚Â§in sessiz, gÃƒÆ’Ã‚Â¼venli hook.
	var fireball_sfx := get_node_or_null("FireballImpactSFX") as AudioStreamPlayer
	if is_instance_valid(fireball_sfx) and fireball_sfx.stream != null:
		fireball_sfx.play()

func spawn_napalm_field(origin_position: Vector2, radius: float) -> void:
	var field = napalm_field_scene.instantiate()
	field.setup(radius, 2.5, 0.5)
	add_child(field)
	field.global_position = origin_position


func get_combo_chain_rank():

	return $HUD/ComboManager.rank_index


func get_chain_lightning_rank() -> int:
	return $ChainLightningManager.get_charge_rank()




func _on_combo_rank_changed(new_rank_index):

	if new_rank_index > highest_combo_rank_index:
		highest_combo_rank_index = new_rank_index

	for ball in get_tree().get_nodes_in_group("game_ball"):
		if ball.has_method("set_combo_chain_rank"):
			ball.set_combo_chain_rank(new_rank_index)

	for paddle_node in get_tree().get_nodes_in_group("game_paddle"):
		if paddle_node.has_method("set_combo_chain_rank"):
			paddle_node.set_combo_chain_rank(new_rank_index)

	for projectile in get_tree().get_nodes_in_group("plasma_projectile"):
		if projectile.has_method("set_combo_chain_rank"):
			projectile.set_combo_chain_rank(new_rank_index)


## apply_depth_scale: derinlik carpanini uygula. Yalnizca debug kisayolu
## kapatir — orada tam olarak bir level-up tetiklenmesi isteniyor.
func add_xp(amount, apply_depth_scale := true, row_xp_scale: float = 1.0):
	if game_over:
		return
	# Veri Emilimi karti toplanan XP'yi artirir.
	var depth_scale: float = (
		GameManager.get_depth_xp_multiplier() if apply_depth_scale else 1.0
	)
	amount = maxi(1, roundi(
		float(amount) * GameManager.get_xp_gain_multiplier() * depth_scale
	))
	amount = GameManager.normalize_collected_xp(amount, row_xp_scale)
	if amount <= 0:
		return
	GameManager.current_xp += amount

	var leveled_up = false

	while GameManager.current_xp >= GameManager.xp_required:

		GameManager.current_xp -= GameManager.xp_required
		GameManager.run_level += 1
		GameManager.pending_card_choices += 1
		GameManager.xp_required = roundi(
			100.0
			* pow(1.20, GameManager.run_level - 1)
		)
		leveled_up = true

	update_labels(false)

	if leveled_up:
		print("XP LEVEL UP TRIGGER")
		_try_resolve_pending_rewards()
	else:
		animate_xp_bar(GameManager.current_xp, GameManager.xp_required)


func get_xp_bar_target_position():
	return xp_bar.global_position + xp_bar.size * 0.5


func show_xp_pickup_feedback(amount, pickup_position):
	var feedback = Label.new()
	feedback.text = "+" + str(amount) + " XP"
	feedback.add_theme_font_size_override("font_size", 22 if OS.has_feature("mobile") else 18)
	feedback.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0, 1.0))
	feedback.z_index = 30
	feedback.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(feedback)
	feedback.global_position = pickup_position + Vector2(-25, -28)

	var tween = feedback.create_tween()
	tween.set_parallel(true)
	tween.tween_property(feedback, "position:y", feedback.position.y - 28.0, 0.50)
	tween.tween_property(feedback, "modulate:a", 0.0, 0.50)
	tween.chain().tween_callback(feedback.queue_free)


func spawn_mobile_pickup_burst(origin: Vector2, color: Color) -> void:
	if not OS.has_feature("mobile"):
		return
	var effect := Node2D.new()
	effect.global_position = origin
	effect.z_index = 32
	add_child(effect)
	for spark_index in range(6):
		var spark := Polygon2D.new()
		spark.polygon = PackedVector2Array([
			Vector2(-1.2, -0.7), Vector2(3.2, 0.0), Vector2(-1.2, 0.7)
		])
		spark.color = color if spark_index % 2 == 0 else Color.WHITE
		effect.add_child(spark)
		var angle := TAU * float(spark_index) / 6.0 + randf_range(-0.18, 0.18)
		spark.rotation = angle
		var burst := spark.create_tween().set_parallel(true)
		burst.tween_property(spark, "position", Vector2.from_angle(angle) * 22.0, 0.16)
		burst.tween_property(spark, "scale", Vector2(0.16, 0.16), 0.16)
		burst.tween_property(spark, "modulate:a", 0.0, 0.16)
	get_tree().create_timer(0.18).timeout.connect(effect.queue_free)


func animate_xp_bar(target_value, maximum):
	xp_bar.max_value = maximum
	update_xp_bar_glow(target_value, maximum)
	if xp_bar_value_tween and xp_bar_value_tween.is_valid():
		xp_bar_value_tween.kill()
	xp_bar_value_tween = xp_bar.create_tween()
	xp_bar_value_tween.tween_property(xp_bar, "value", target_value, 0.20)
	pulse_xp_bar()


func update_xp_bar_glow(value, maximum):
	var fill_ratio = clampf(float(value) / maxf(float(maximum), 1.0), 0.0, 1.0)
	xp_bar.self_modulate = Color(
		lerpf(0.94, 1.06, fill_ratio),
		lerpf(0.97, 1.04, fill_ratio),
		lerpf(1.0, 1.10, fill_ratio),
		1.0
	)


func pulse_xp_bar():
	if xp_bar_pulse_tween and xp_bar_pulse_tween.is_valid():
		xp_bar_pulse_tween.kill()
	xp_bar.scale = Vector2.ONE
	xp_bar_pulse_tween = xp_bar.create_tween()
	xp_bar_pulse_tween.tween_property(xp_bar, "scale", Vector2(1.04, 1.04), 0.08)
	xp_bar_pulse_tween.tween_property(xp_bar, "scale", Vector2.ONE, 0.10)


func show_level_up_feedback():
	var feedback = Label.new()
	feedback.text = "LEVEL UP!"
	feedback.add_theme_font_size_override("font_size", 30)
	feedback.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0, 1.0))
	feedback.z_index = 50
	feedback.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(feedback)
	feedback.position = Vector2(
		get_viewport_rect().size.x * 0.5 - 96.0,
		GameManager.PLAYFIELD_TOP + 18.0
	)
	feedback.pivot_offset = Vector2(80, 18)
	feedback.scale = Vector2(0.9, 0.9)

	var tween = feedback.create_tween()
	tween.set_parallel(true)
	tween.tween_property(feedback, "scale", Vector2(1.08, 1.08), 0.32)
	tween.tween_property(feedback, "position:y", feedback.position.y - 16.0, 0.32)
	tween.tween_property(feedback, "modulate:a", 0.0, 0.32)
	await tween.finished
	feedback.queue_free()


func _get_reward_sfx_player() -> AudioStreamPlayer:
	if is_instance_valid(reward_sfx_player):
		return reward_sfx_player
	reward_sfx_player = AudioStreamPlayer.new()
	reward_sfx_player.name = "RewardSFX"
	reward_sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	reward_sfx_player.volume_db = -4.0
	add_child(reward_sfx_player)
	return reward_sfx_player


func _play_reward_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	var player := _get_reward_sfx_player()
	player.stream = stream
	player.play()


func _make_reward_banner_style(tone: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.055, 0.09, 0.92)
	style.border_color = Color(tone.r, tone.g, tone.b, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(tone.r, tone.g, tone.b, 0.28)
	style.shadow_size = 14
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 12.0
	return style


func _make_reward_entry(icon: Texture2D, text: String, tone: Color) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	if icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.texture = icon
		icon_rect.custom_minimum_size = Vector2(24.0, 24.0)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.modulate = tone
		icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon_rect)
	var value := Label.new()
	value.text = text
	value.add_theme_font_size_override("font_size", 26)
	value.add_theme_color_override("font_color", tone)
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value)
	return row


func _show_reward_banner(
	heading: String,
	entries: Array,
	tone: Color,
	sound: AudioStream = null
) -> void:
	# Kart ekranı açılamayan ödüller ve boss kutlaması için ortada kısa süreli bildirim.
	_play_reward_sfx(sound)

	var frame := PanelContainer.new()
	frame.z_index = 60
	frame.process_mode = Node.PROCESS_MODE_ALWAYS
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _make_reward_banner_style(tone))

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(column)

	var heading_label := Label.new()
	heading_label.text = heading
	heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading_label.add_theme_font_size_override("font_size", 14)
	heading_label.add_theme_color_override("font_color", Color(tone.r, tone.g, tone.b, 0.70))
	column.add_child(heading_label)

	var entry_row := HBoxContainer.new()
	entry_row.alignment = BoxContainer.ALIGNMENT_CENTER
	entry_row.add_theme_constant_override("separation", 22)
	entry_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(entry_row)
	for entry: Dictionary in entries:
		entry_row.add_child(_make_reward_entry(
			entry.get("icon") as Texture2D,
			String(entry.get("text", "")),
			tone
		))

	add_child(frame)
	# İçerik boyutu bir frame sonra kesinleşir; ortalamayı ondan sonra yap.
	await get_tree().process_frame
	if not is_instance_valid(frame):
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var frame_size := frame.get_combined_minimum_size()
	frame.size = frame_size
	frame.position = Vector2(
		viewport_size.x * 0.5 - frame_size.x * 0.5,
		GameManager.PLAYFIELD_TOP + 54.0
	)
	frame.pivot_offset = frame_size * 0.5
	frame.scale = Vector2(0.88, 0.88)
	frame.modulate.a = 0.0

	var tween := frame.create_tween()
	tween.set_parallel(true)
	tween.tween_property(frame, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(frame, "modulate:a", 1.0, 0.14)
	await tween.finished
	await get_tree().create_timer(1.25, true, false, true).timeout
	if not is_instance_valid(frame):
		return
	var fade := frame.create_tween()
	fade.set_parallel(true)
	fade.tween_property(frame, "position:y", frame.position.y - 24.0, 0.30)
	fade.tween_property(frame, "modulate:a", 0.0, 0.30)
	await fade.finished
	if is_instance_valid(frame):
		frame.queue_free()


func show_pending_levelup_reward():
	if xp_level_up_sequence_active or GameManager.pending_card_choices <= 0:
		return
	xp_level_up_sequence_active = true
	get_tree().paused = true
	await show_level_up_feedback()
	xp_level_up_sequence_active = false
	if game_over or main_menu.visible or GameManager.pending_card_choices <= 0:
		return
	xp_bar.max_value = GameManager.xp_required
	xp_bar.value = GameManager.current_xp
	show_card_selection()


# ==================================================
# BEKLEYEN ÖDÜLLER
# ==================================================

func _try_resolve_pending_rewards() -> void:
	# Kart ve evrim ödülleri run içinde bekleyebilir; uygun ilk anda ikisini de boşalt.
	if (
		choosing_card
		or card_selection_committing
		or evolution_selection_active
		or xp_level_up_sequence_active
		or boss_reward_active
		or game_over
		or main_menu.visible
		or pause_menu_active
		or boss_active
		or boss_warning_running
	):
		return
	if GameManager.pending_card_choices > 0:
		show_pending_levelup_reward()
		return
	_try_open_pending_evolution()
	if not evolution_selection_active:
		get_tree().paused = false
		call_deferred("_try_start_pending_boss")


# ==================================================
# YEDEK LEVEL-UP ÖDÜLÜ
# ==================================================

const FALLBACK_REWARD_SALVAGE := 3
const FALLBACK_REWARD_COINS := 2

func _grant_fallback_levelup_reward() -> void:
	var reward_pool: Array[StringName] = [&"salvage", &"coins"]
	# Can eksikse iyileşme ağırlıklı gelsin.
	if GameManager.lives < GameManager.MAX_LIVES:
		reward_pool.append(&"life")
		reward_pool.append(&"life")
	if wide_paddle_pickup_time_remaining <= 0.0:
		reward_pool.append(&"wide_paddle")
	# Toplar tavandaysa katlama yapamaz; odul havuzuna girmesin.
	if _active_ball_count() < MAX_ACTIVE_BALLS:
		reward_pool.append(&"extra_ball")

	var reward: StringName = reward_pool.pick_random()
	var reward_text := ""
	var reward_icon: Texture2D = null
	var reward_color := Color(0.45, 0.95, 1.0, 1.0)
	match reward:
		&"life":
			GameManager.add_life()
			update_labels()
			pulse_lives_hud()
			reward_text = "+1"
			reward_icon = ICON_LIFE
			reward_color = Color(1.0, 0.42, 0.58, 1.0)
		&"wide_paddle":
			activate_wide_paddle_pickup()
			reward_text = "GENİŞ RAKET"
			reward_icon = ICON_WIDE_PADDLE
			reward_color = Color(0.55, 0.90, 1.0, 1.0)
		&"extra_ball":
			activate_extra_ball_pickup()
			reward_text = "TOPLAR İKİYE KATLANDI"
			reward_icon = ICON_EXTRA_BALL
			reward_color = Color(0.55, 0.90, 1.0, 1.0)
		&"coins":
			run_coins_collected += FALLBACK_REWARD_COINS
			GameManager.add_coins(FALLBACK_REWARD_COINS)
			_refresh_shop_button_text()
			reward_text = "+%d" % FALLBACK_REWARD_COINS
			reward_icon = ICON_COIN
			reward_color = Color(1.0, 0.78, 0.12, 1.0)
		_:
			_award_run_salvage(FALLBACK_REWARD_SALVAGE)
			reward_text = "+%d" % FALLBACK_REWARD_SALVAGE
			reward_icon = ICON_SALVAGE
			reward_color = Color(0.30, 0.95, 1.0, 1.0)

	print("FALLBACK LEVELUP REWARD: %s %s" % [reward_text, reward])
	_show_reward_banner(
		"BONUS",
		[{"icon": reward_icon, "text": reward_text}],
		reward_color,
		SFX_BONUS_REWARD
	)
	call_deferred("_try_resolve_pending_rewards")


# ==================================================
# KART EKRANI
# ==================================================

func show_card_selection(force_plasma = false):

	if choosing_card or game_over or evolution_selection_active or boss_reward_active or boss_active or boss_warning_running:
		return
	# Existing debug-only direct offers also own one choice.
	GameManager.pending_card_choices = maxi(GameManager.pending_card_choices, 1)

	print("OPEN CARD SCREEN")


	choosing_card = true


	choose_random_cards(force_plasma)
	if visible_cards.is_empty():
		# Uygun kart kalmadığında level-up sessizce kaybolmasın: yedek ödül ver.
		choosing_card = false
		GameManager.pending_card_choices -= 1
		_grant_fallback_levelup_reward()
		return

	card_screen.visible = true
	card_panel.visible = true
	_refresh_card_slot_state()

	last_focused_card = null
	card_select_sound_played = false
	if OS.has_feature("mobile"):
		var focus_owner := get_viewport().gui_get_focus_owner()
		if is_instance_valid(focus_owner):
			focus_owner.release_focus()
	else:
		visible_cards[0].grab_focus()


	get_tree().paused = true


# ==================================================
# RASTGELE 2 KART
# ==================================================

func _get_card_slots() -> Array:
	return [plasma_card, pierce_card, fireball_card]


# Kart kurallari card_system.gd'de. Buradaki sarmalayicilar yalnizca
# calisma durumunu paketler; kural mantigi bu dosyada TUTULMAZ.
func _make_card_state() -> Dictionary:
	return CardSystem.make_state(GameManager, first_boss_defeated, second_boss_defeated)


func _get_unlocked_max_card_level() -> int:
	return CardSystem.get_weapon_level_cap(_make_card_state())


func _is_card_eligible(card_id: StringName) -> bool:
	return CardSystem.is_card_eligible(card_id, _make_card_state())


func _get_eligible_card_ids() -> Array:
	return CardSystem.get_eligible_card_ids(_make_card_state())


func _roll_card_ids(count: int) -> Array:
	return CardSystem.roll_card_ids(count, _make_card_state())


func choose_random_cards(force_plasma = false):
	var rolled: Array = []
	if force_plasma and _is_card_eligible(&"plasma"):
		rolled.append(&"plasma")
		for card_id: StringName in _roll_card_ids(3):
			if rolled.size() >= 3:
				break
			if card_id != &"plasma":
				rolled.append(card_id)
	else:
		rolled = _roll_card_ids(3)

	slot_card_ids = rolled
	visible_cards = []

	var slots := _get_card_slots()
	for slot: Button in slots:
		slot.visible = false
		slot.scale = Vector2.ONE
		slot.z_index = 0
		slot.modulate = Color(1.0, 1.0, 1.0, 1.0)

	var card_positions: Array[Vector2]
	if OS.has_feature("mobile"):
		var safe_rect := GameManager.get_layout_safe_rect(get_viewport_rect().size)
		var two_card_width := MOBILE_CARD_SIZE.x * 2.0 + 20.0
		var first_x := safe_rect.position.x + (safe_rect.size.x - two_card_width) * 0.5
		card_positions = [
			Vector2(first_x, safe_rect.position.y + 238.0),
			Vector2(first_x + MOBILE_CARD_SIZE.x + 20.0, safe_rect.position.y + 238.0),
			Vector2(safe_rect.position.x + (safe_rect.size.x - MOBILE_CARD_SIZE.x) * 0.5, safe_rect.position.y + 568.0)
		]
	else:
		card_positions = [Vector2(218, 180), Vector2(468, 180), Vector2(718, 180)]

	for index in range(rolled.size()):
		var slot: Button = slots[index]
		_render_card_slot(slot, rolled[index])
		slot.visible = true
		slot.position = card_positions[index]
		visible_cards.append(slot)

	for index in range(visible_cards.size()):
		var slot: Button = visible_cards[index]
		var left_slot: Button = visible_cards[(index - 1 + visible_cards.size()) % visible_cards.size()]
		var right_slot: Button = visible_cards[(index + 1) % visible_cards.size()]
		slot.focus_neighbor_left = slot.get_path_to(left_slot)
		slot.focus_neighbor_right = slot.get_path_to(right_slot)

	_refresh_card_action_buttons()


func _setup_card_action_buttons() -> void:
	if is_instance_valid(reroll_button):
		return
	reroll_button = _make_card_action_button("YENIDEN DAGIT", Color(0.36, 0.86, 1.0, 1.0))
	reroll_button.pressed.connect(_on_reroll_pressed)
	card_panel.add_child(reroll_button)
	banish_button = _make_card_action_button("KARTI YOK ET", Color(1.0, 0.52, 0.34, 1.0))
	banish_button.pressed.connect(_on_banish_pressed)
	card_panel.add_child(banish_button)
	_layout_card_action_buttons()


func _make_card_action_button(label: String, tone: Color) -> Button:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", tone)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.42, 0.48, 0.56, 0.65))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.015, 0.06, 0.10, 0.94)
	normal.border_color = Color(tone.r, tone.g, tone.b, 0.85)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(9)
	normal.content_margin_left = 16.0
	normal.content_margin_right = 16.0
	normal.content_margin_top = 8.0
	normal.content_margin_bottom = 8.0
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.03, 0.12, 0.18, 0.98)
	hover.shadow_color = Color(tone.r, tone.g, tone.b, 0.30)
	hover.shadow_size = 10
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.border_color = Color(0.28, 0.34, 0.42, 0.55)
	button.add_theme_stylebox_override("disabled", disabled)
	return button


func _layout_card_action_buttons() -> void:
	if not is_instance_valid(reroll_button):
		return
	var button_size := Vector2(200.0, 40.0)
	var spacing := 18.0
	var total_width := button_size.x * 2.0 + spacing
	var origin: Vector2
	if OS.has_feature("mobile"):
		var safe_rect := GameManager.get_layout_safe_rect(get_viewport_rect().size)
		origin = Vector2(
			safe_rect.position.x + (safe_rect.size.x - total_width) * 0.5,
			safe_rect.position.y + 900.0
		)
	else:
		origin = Vector2((get_viewport_rect().size.x - total_width) * 0.5, 520.0)
	_set_mobile_rect(reroll_button, Rect2(origin, button_size))
	_set_mobile_rect(banish_button, Rect2(origin + Vector2(button_size.x + spacing, 0.0), button_size))


func _refresh_card_action_buttons() -> void:
	if not is_instance_valid(reroll_button):
		return
	_layout_card_action_buttons()
	var can_reroll := GameManager.rerolls_remaining > 0 and not visible_cards.is_empty()
	reroll_button.disabled = not can_reroll
	reroll_button.text = "YENIDEN DAGIT (%d)" % GameManager.rerolls_remaining
	# Banish yalnizca elden bir kart cikarilabiliyorsa anlamli.
	var can_banish := (
		GameManager.banishes_remaining > 0
		and visible_cards.size() > 1
		and _get_eligible_card_ids().size() > visible_cards.size()
	)
	banish_button.disabled = not can_banish
	if banish_arm_active:
		banish_button.text = "YOK EDİLECEK KARTI SEÇ"
	else:
		banish_button.text = "KARTI YOK ET (%d)" % GameManager.banishes_remaining


func _on_reroll_pressed() -> void:
	if not choosing_card or card_selection_committing or GameManager.rerolls_remaining <= 0:
		return
	GameManager.rerolls_remaining -= 1
	banish_arm_active = false
	_play_card_select_sound()
	choose_random_cards()
	if visible_cards.is_empty():
		# Reroll sonrasi aday kalmadiysa level-up bos gecmesin.
		choosing_card = false
		GameManager.pending_card_choices = maxi(0, GameManager.pending_card_choices - 1)
		_grant_fallback_levelup_reward()
		return
	if not OS.has_feature("mobile"):
		visible_cards[0].grab_focus()


func _on_banish_pressed() -> void:
	if not choosing_card or card_selection_committing or GameManager.banishes_remaining <= 0:
		return
	banish_arm_active = not banish_arm_active
	_refresh_card_action_buttons()


func _banish_slot(slot: Button) -> void:
	var card_id := _get_slot_card_id(slot)
	if card_id == &"none":
		return
	GameManager.banishes_remaining -= 1
	GameManager.banished_cards[card_id] = true
	banish_arm_active = false
	print("CARD BANISHED: %s" % card_id)
	_play_card_select_sound()
	choose_random_cards()
	if visible_cards.is_empty():
		choosing_card = false
		get_tree().paused = false
		_grant_fallback_levelup_reward()
		return
	if not OS.has_feature("mobile"):
		visible_cards[0].grab_focus()


func _get_card_icon(card_id: StringName) -> Texture2D:
	if card_icon_cache.has(card_id):
		return card_icon_cache[card_id]
	var path := CardPool.get_icon_path(card_id)
	var texture: Texture2D = null
	if path != "" and ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	card_icon_cache[card_id] = texture
	return texture


func _make_card_slot_style(tone: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.016, 0.055, 0.085, 0.96)
	style.border_color = tone
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(tone.r, tone.g, tone.b, 0.30)
	style.shadow_size = 12
	return style


func _render_card_slot(slot: Button, card_id: StringName) -> void:
	slot.text = ""
	slot.set_meta("card_id", String(card_id))
	var next_level: int = mini(
		CardPool.get_display_level(GameManager, card_id) + 1,
		CardPool.get_max_level(card_id)
	)
	var tone := CardPool.get_rarity_color(card_id)

	# Nadirlik rengi kart cercevesinden okunur.
	var style := _make_card_slot_style(tone)
	slot.add_theme_stylebox_override("normal", style)
	var focus_style := style.duplicate() as StyleBoxFlat
	focus_style.set_border_width_all(4)
	focus_style.shadow_size = 20
	slot.add_theme_stylebox_override("hover", focus_style)
	slot.add_theme_stylebox_override("focus", focus_style)
	var pressed_style := focus_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.03, 0.12, 0.17, 0.98)
	slot.add_theme_stylebox_override("pressed", pressed_style)

	var image := slot.get_node_or_null("CardImage") as TextureRect
	if is_instance_valid(image):
		image.visible = true
		image.texture = _get_card_icon(card_id)
		image.modulate = Color.WHITE if CardPool.is_weapon(card_id) else tone

	var title_panel := slot.get_node_or_null("TitlePanel") as Control
	if is_instance_valid(title_panel):
		title_panel.visible = true
		var title := title_panel.get_node_or_null("Title") as Label
		if is_instance_valid(title):
			var title_text := CardPool.get_title(card_id)
			if CardPool.uses_roman_numeral(card_id):
				title_text += " " + level_to_roman(next_level)
			title.text = title_text
			title.add_theme_color_override("font_color", tone)

	_set_card_description(slot, CardPool.get_description(card_id, next_level))
	_set_card_rarity_tag(slot, card_id, tone)
	_set_card_type_tag(slot, card_id, next_level, tone)

	# Karta ozel dekoratif dugumler yalnizca kendi kartinda gorunsun.
	for decoration_name in ["ImpactRing", "ImpactBrick", "PiercingIcon"]:
		var decoration := slot.get_node_or_null(decoration_name) as CanvasItem
		if is_instance_valid(decoration):
			decoration.visible = false


func _set_card_rarity_tag(slot: Button, card_id: StringName, tone: Color) -> void:
	var tag := slot.get_node_or_null("RarityTag") as Label
	if not is_instance_valid(tag):
		tag = Label.new()
		tag.name = "RarityTag"
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(tag)
	tag.text = CardPool.get_rarity_label(card_id)
	tag.add_theme_font_size_override("font_size", 11 if OS.has_feature("mobile") else 10)
	tag.add_theme_color_override("font_color", Color(tone.r, tone.g, tone.b, 0.85))
	var slot_width: float = MOBILE_CARD_SIZE.x if OS.has_feature("mobile") else slot.size.x
	var slot_height: float = MOBILE_CARD_SIZE.y if OS.has_feature("mobile") else slot.size.y
	_set_mobile_rect(tag, Rect2(0.0, slot_height - 20.0, slot_width, 16.0))


func _set_card_type_tag(slot: Button, card_id: StringName, next_level: int, tone: Color) -> void:
	var tag := slot.get_node_or_null("TypeTag") as Label
	if not is_instance_valid(tag):
		tag = Label.new()
		tag.name = "TypeTag"
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(tag)
	var tag_text := "PASSIVE"
	if card_id in [&"fireball", &"pierce"]:
		tag_text = "CORE"
	elif WeaponSystem.handles(card_id):
		var current_level := CardPool.get_display_level(GameManager, card_id)
		tag_text = (
			"WEAPON · NEW" if current_level <= 0
			else "WEAPON · UPGRADE → LV%d" % next_level
		)
	tag.text = tag_text
	tag.add_theme_font_size_override("font_size", 10 if OS.has_feature("mobile") else 9)
	tag.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0, 1.0))
	var tag_style := StyleBoxFlat.new()
	tag_style.bg_color = Color(0.01, 0.04, 0.09, 0.88)
	tag_style.border_color = Color(tone.r, tone.g, tone.b, 0.72)
	tag_style.set_border_width_all(1)
	tag_style.set_corner_radius_all(6)
	tag.add_theme_stylebox_override("normal", tag_style)
	var slot_width: float = MOBILE_CARD_SIZE.x if OS.has_feature("mobile") else slot.size.x
	_set_mobile_rect(tag, Rect2(10.0, 9.0, slot_width - 20.0, 23.0))


func _get_slot_card_id(slot: Button) -> StringName:
	if not is_instance_valid(slot) or not slot.has_meta("card_id"):
		return &"none"
	return StringName(String(slot.get_meta("card_id")))


func _on_card_slot_pressed(slot: Button) -> void:
	if not choosing_card or card_selection_committing or not slot.visible:
		return
	var card_id := _get_slot_card_id(slot)
	if card_id == &"none" or not CardPool.has_card(card_id):
		return
	if banish_arm_active:
		_banish_slot(slot)
		return
	card_selection_committing = true
	_play_card_select_sound()
	await play_card_effect(slot)
	if game_over:
		card_selection_committing = false
		return
	close_card_selection()
	_apply_card_selection(card_id)
	card_selection_committing = false
	_try_resolve_pending_rewards()


func _apply_card_selection(card_id: StringName) -> void:
	var previous_level := CardPool.get_display_level(GameManager, card_id)
	var next_level: int = mini(
		CardPool.get_display_level(GameManager, card_id) + 1,
		CardPool.get_max_level(card_id)
	)

	# Monteli silahlar yuva sistemine gider; seviyeyi orasi yazar.
	if WeaponSystem.handles(card_id):
		WeaponSystem.apply(self, card_id, next_level)
		build_hud.refresh_from_run_state()
		_refresh_build_identity_hud(true)
		refresh_dynamic_build_difficulty()
		call_deferred("_try_resolve_pending_rewards")
		return

	GameManager.set_card_level(card_id, next_level)
	print("CARD TAKEN: %s Lv%d (%s)" % [card_id, next_level, CardPool.get_rarity(card_id)])

	match card_id:
		&"plasma":
			paddle.apply_plasma_level(next_level, true)
		&"pierce":
			for ball in get_tree().get_nodes_in_group("game_ball"):
				if ball.has_method("set_pierce_level"):
					ball.set_pierce_level(next_level)
		&"fireball":
			for ball in get_tree().get_nodes_in_group("game_ball"):
				if ball.has_method("set_fireball_level"):
					ball.set_fireball_level(next_level)
		&"combo_window":
			$HUD/ComboManager.refresh_card_modifiers()
		&"revive":
			GameManager.revive_available = true

	build_hud.refresh_from_run_state()
	_refresh_build_identity_hud(true)
	if previous_level <= 0 and card_id in [&"fireball", &"pierce"]:
		var selected_name := "FIREBALL" if card_id == &"fireball" else "PIERCING"
		var blocked_name := "PIERCING" if card_id == &"fireball" else "FIREBALL"
		_show_hud_status(
			"ÇEKİRDEK KİLİTLENDİ: %s · %s DEVRE DIŞI" % [selected_name, blocked_name],
			Color(1.0, 0.72, 0.28, 1.0),
			1.8
		)
	refresh_dynamic_build_difficulty()
	call_deferred("_try_resolve_pending_rewards")


func _refresh_persistent_extra_balls() -> void:
	if game_over or choosing_card:
		return
	var active_balls := get_tree().get_nodes_in_group("game_ball")
	# Firlatilmayi bekleyen top varken cogaltma yapma; firlatista tekrar cagrilir.
	for ball in active_balls:
		if ball.get("ball_launched") == false:
			return
	var target_balls: int = 1 + GameManager.get_bonus_ball_count()
	var attempts := 0
	while get_tree().get_nodes_in_group("game_ball").size() < target_balls and attempts < 4:
		attempts += 1
		if spawn_extra_ball(false) == null:
			break


func close_card_selection():
	if not choosing_card:
		return
	GameManager.pending_card_choices = maxi(0, GameManager.pending_card_choices - 1)

	if not GameManager.first_card_selection_done:
		GameManager.first_card_selection_done = true

	card_panel.visible = false

	choosing_card = false
	banish_arm_active = false
	last_focused_card = null

	# Reward coordinator resumes after queued cards/evolutions are resolved.


# ==================================================
# +1 TOP
# ==================================================

func _on_card_focus_entered(card: Control) -> void:
	if not (choosing_card or evolution_selection_active) or not card.visible:
		return
	if last_focused_card == null:
		last_focused_card = card
		return
	if last_focused_card == card:
		return
	last_focused_card = card
	var now_msec := Time.get_ticks_msec()
	if now_msec - last_card_move_sound_msec < CARD_MOVE_SOUND_COOLDOWN_MSEC:
		return
	last_card_move_sound_msec = now_msec
	card_move_sfx.pitch_scale = randf_range(0.98, 1.02)
	card_move_sfx.play()


func _play_card_select_sound() -> void:
	if card_select_sound_played:
		return
	card_select_sound_played = true
	card_select_sfx.pitch_scale = 1.0
	card_select_sfx.play()


func get_evolution_eligible_cards() -> Array[StringName]:
	var eligible_cards: Array[StringName] = []
	if GameManager.plasma_level >= 3 and GameManager.plasma_evolution == &"none":
		eligible_cards.append(&"plasma")
	if GameManager.fireball_level >= 3 and GameManager.fireball_evolution == &"none":
		eligible_cards.append(&"fireball")
	if GameManager.pierce_level >= 3 and GameManager.pierce_evolution == &"none":
		eligible_cards.append(&"pierce")
	return eligible_cards


func _try_open_pending_evolution() -> void:
	if GameManager.evolution_credits <= 0:
		return
	if (
		evolution_selection_active
		or choosing_card
		or boss_reward_active
		or game_over
		or main_menu.visible
		or boss_active
		or boss_warning_running
	):
		return
	var eligible_cards := get_evolution_eligible_cards()
	if not eligible_cards.is_empty():
		request_evolution_for_card(eligible_cards[0])
		return
	# Harcanacak evrim kalmadiysa kredi bosa gitmesin.
	_convert_surplus_evolution_credit()


func _get_remaining_evolution_capacity() -> int:
	var capacity := 0
	var plasma_level: int = GameManager.get_weapon_level(GameManager.WEAPON_PLASMA)
	# A banished upgrade below Lv3 cannot reach evolution; an owned Lv3 still can.
	if GameManager.plasma_evolution == &"none":
		if plasma_level >= 3:
			capacity += 1
		elif not GameManager.banished_cards.has(&"plasma") and GameManager.can_acquire_weapon(GameManager.WEAPON_PLASMA):
			capacity += 1

	var core_capacity := 0
	for core_id: StringName in [&"fireball", &"pierce"]:
		var other_id: StringName = &"pierce" if core_id == &"fireball" else &"fireball"
		var level: int = GameManager.get_card_level(core_id)
		var evolved: bool = (
			GameManager.fireball_evolution != &"none" if core_id == &"fireball"
			else GameManager.pierce_evolution != &"none"
		)
		if evolved:
			continue
		if level >= 3:
			core_capacity += 1
		elif GameManager.get_card_level(other_id) <= 0 and not GameManager.banished_cards.has(core_id):
			core_capacity += 1
	# Before a Core is chosen, both are offers but only one can ever evolve.
	if GameManager.fireball_level <= 0 and GameManager.pierce_level <= 0:
		core_capacity = mini(core_capacity, 1)
	return capacity + core_capacity


func _convert_surplus_evolution_credit() -> void:
	# Yalnızca hiçbir zaman harcanamayacak fazlalık dönüştürülür; ileride
	# kullanılabilecek krediler oyuncudan alınmaz.
	var surplus: int = GameManager.evolution_credits - _get_remaining_evolution_capacity()
	if surplus <= 0:
		return
	GameManager.evolution_credits -= surplus
	GameManager.rerolls_remaining += surplus
	GameManager.banishes_remaining += surplus
	print("EVOLUTION CREDIT CONVERTED | %d kredi -> +%d reroll, +%d banish" % [
		surplus, surplus, surplus
	])
	_show_reward_banner(
		"EVRİM KREDİSİ DÖNÜŞTÜ",
		[{"icon": ICON_TROPHY, "text": "+%d DAĞIT   +%d YOK ET" % [surplus, surplus]}],
		Color(0.72, 0.30, 1.00, 1.0),
		SFX_BONUS_REWARD
	)


func request_evolution_for_card(card_id: StringName) -> void:
	if GameManager.evolution_credits <= 0 or card_id not in get_evolution_eligible_cards():
		return
	active_evolution_card = card_id
	_configure_evolution_screen(card_id)
	_open_evolution_screen()


func request_plasma_evolution() -> void:
	if evolution_selection_active:
		return
	request_evolution_for_card(&"plasma")


func _open_evolution_screen() -> void:
	if evolution_selection_active:
		return

	evolution_selection_active = true
	evolution_panel.visible = true
	last_focused_card = null
	card_select_sound_played = false
	overcharge_card.focus_neighbor_left = overcharge_card.get_path_to(ricochet_card)
	overcharge_card.focus_neighbor_right = overcharge_card.get_path_to(ricochet_card)
	ricochet_card.focus_neighbor_left = ricochet_card.get_path_to(overcharge_card)
	ricochet_card.focus_neighbor_right = ricochet_card.get_path_to(overcharge_card)
	if OS.has_feature("mobile"):
		var focus_owner := get_viewport().gui_get_focus_owner()
		if is_instance_valid(focus_owner):
			focus_owner.release_focus()
	else:
		overcharge_card.grab_focus()
	get_tree().paused = true


func _configure_evolution_screen(card_id: StringName) -> void:
	if card_id == &"pierce":
		evolution_subtitle.text = "DEL\u0130C\u0130 TOP \u0130\u00C7\u0130N SON FORMU SE\u00C7"
		evolution_left_title.text = "GENİŞ DELİK"
		evolution_left_description.text = "Raket dönüşü başına delinen\ntuğla sayısı 3 artar."
		evolution_right_title.text = "ZİNCİRLEME"
		evolution_right_description.text = "Delinen her tuğla ayrı bir\nzincir şimşeği tetikler."
		evolution_left_image.texture = PIERCING_CARD_TEXTURE
		evolution_right_image.texture = PIERCING_CARD_TEXTURE
		evolution_left_image.modulate = Color(0.46, 1.0, 0.86, 1.0)
		evolution_right_image.modulate = Color(0.62, 0.82, 1.0, 1.0)
		return
	if card_id == &"fireball":
		evolution_subtitle.text = "ALEV TOPU \u0130\u00C7\u0130N SON FORMU SE\u00C7"
		evolution_left_title.text = "INFERNO"
		evolution_left_description.text = "Patlama alan\u0131n\u0131 %45 b\u00FCy\u00FCt\u00FCr.\nHasar g\u00FCc\u00FC de\u011Fi\u015Fmez."
		evolution_right_title.text = "NAPALM"
		evolution_right_description.text = "Patlama sonras\u0131 2,5 saniye kalan\nyan\u0131c\u0131 alan zamanla hasar verir."
		evolution_left_image.texture = preload("res://ball_card.png")
		evolution_right_image.texture = preload("res://ball_card.png")
		evolution_left_image.modulate = Color(1.0, 0.38, 0.12, 1.0)
		evolution_right_image.modulate = Color(1.0, 0.62, 0.18, 1.0)
		return
	evolution_subtitle.text = "PLAZMA \u0130\u00C7\u0130N SON FORMU SE\u00C7"
	evolution_left_title.text = "OVERCHARGE"
	evolution_left_description.text = "Plazma silahlar\u0131n\u0131 a\u015F\u0131r\u0131 y\u00FCkler.\nAte\u015F h\u0131z\u0131 %30 artar."
	evolution_right_title.text = "RICOCHET"
	evolution_right_description.text = "Geni\u015F a\u00E7\u0131l\u0131 \u00FC\u00E7 at\u0131\u015F yapar.\nHer mermi duvardan 3 kez seker."
	evolution_left_image.texture = preload("res://plasma_card.png")
	evolution_right_image.texture = preload("res://plasma_card.png")
	evolution_left_image.modulate = Color(1.0, 0.58, 0.28, 1.0)
	evolution_right_image.modulate = Color(0.46, 0.88, 1.0, 1.0)


func _select_active_evolution(option_index: int) -> void:
	if active_evolution_card == &"plasma":
		_select_plasma_evolution(&"overcharge" if option_index == 0 else &"ricochet")
	elif active_evolution_card == &"fireball":
		_select_fireball_evolution(&"inferno" if option_index == 0 else &"napalm")
	elif active_evolution_card == &"pierce":
		_select_pierce_evolution(&"breach" if option_index == 0 else &"cascade")


func _select_plasma_evolution(evolution: StringName) -> void:
	if (
		not evolution_selection_active
		or active_evolution_card != &"plasma"
		or GameManager.plasma_evolution != &"none"
		or GameManager.evolution_credits <= 0
	):
		return
	if evolution not in [&"overcharge", &"ricochet"]:
		return

	_play_card_select_sound()
	GameManager.plasma_evolution = evolution
	GameManager.evolution_credits -= 1
	paddle.apply_plasma_evolution(evolution, true)
	build_hud.refresh_from_run_state()
	refresh_dynamic_build_difficulty()
	evolution_panel.visible = false
	evolution_selection_active = false
	active_evolution_card = &"none"
	last_focused_card = null
	_try_resolve_pending_rewards()


func refresh_dynamic_build_difficulty() -> void:
	if is_instance_valid(brick_field):
		brick_field.apply_depth_settings()
	var side_spawner := get_node_or_null("SideAttackerSpawner")
	if is_instance_valid(side_spawner) and side_spawner.has_method("refresh_build_modifier"):
		side_spawner.refresh_build_modifier()


func _select_pierce_evolution(evolution: StringName) -> void:
	if (
		not evolution_selection_active
		or active_evolution_card != &"pierce"
		or GameManager.pierce_evolution != &"none"
		or GameManager.evolution_credits <= 0
	):
		return
	if evolution not in [&"breach", &"cascade"]:
		return

	_play_card_select_sound()
	GameManager.pierce_evolution = evolution
	GameManager.evolution_credits -= 1
	for ball in get_tree().get_nodes_in_group("game_ball"):
		if ball.has_method("refill_pierce_capacity"):
			ball.refill_pierce_capacity()
	build_hud.refresh_from_run_state()
	refresh_dynamic_build_difficulty()
	evolution_panel.visible = false
	evolution_selection_active = false
	active_evolution_card = &"none"
	last_focused_card = null
	_try_resolve_pending_rewards()


func _select_fireball_evolution(evolution: StringName) -> void:
	if (
		not evolution_selection_active
		or active_evolution_card != &"fireball"
		or GameManager.fireball_evolution != &"none"
		or GameManager.evolution_credits <= 0
	):
		return
	if evolution not in [&"inferno", &"napalm"]:
		return

	_play_card_select_sound()
	GameManager.fireball_evolution = evolution
	GameManager.evolution_credits -= 1
	build_hud.refresh_from_run_state()
	evolution_panel.visible = false
	evolution_selection_active = false
	active_evolution_card = &"none"
	last_focused_card = null
	_try_resolve_pending_rewards()


func _set_card_description(card: Button, description_text: String) -> void:
	var description := card.get_node_or_null("Description") as Label
	if is_instance_valid(description):
		description.text = description_text
		if OS.has_feature("mobile"):
			_fit_card_description(description, 13, 11)
		else:
			_fit_card_description(description, 11, 9)


func _fit_card_description(description: Label, preferred_size: int, minimum_size: int) -> void:
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.clip_text = true
	var font := description.get_theme_font("font")
	var available_width := maxf(description.size.x, 1.0)
	var available_height := maxf(description.size.y, 1.0)
	var fitted_size := preferred_size
	while fitted_size > minimum_size:
		var text_size := font.get_multiline_string_size(
			description.text,
			HORIZONTAL_ALIGNMENT_CENTER,
			available_width,
			fitted_size
		)
		if text_size.y <= available_height:
			break
		fitted_size -= 1
	description.add_theme_font_size_override("font_size", fitted_size)


func level_to_roman(level):

	return ["", "I", "II", "III"][level]


# ==================================================
# KART SEÃƒÆ’Ã¢â‚¬Â¡Ãƒâ€Ã‚Â°M EFEKTÃƒâ€Ã‚Â°
# ==================================================

func play_card_effect(card):

	var original_scale = card.scale
	var original_modulate = card.modulate


	# --------------------------------------------------
	# BÃƒÆ’Ã…â€œYÃƒÆ’Ã…â€œ VE PARLA
	# --------------------------------------------------

	var tween = card.create_tween()

	tween.set_parallel(true)


	tween.tween_property(
		card,
		"scale",
		original_scale * 1.15,
		0.12
	)


	tween.tween_property(
		card,
		"modulate",
		Color(
			1.5,
			1.5,
			1.5,
			1.0
		),
		0.12
	)


	await tween.finished


	# --------------------------------------------------
	# NORMALE DÃƒÆ’Ã¢â‚¬â€œN
	# --------------------------------------------------

	var tween_back = card.create_tween()

	tween_back.set_parallel(true)


	tween_back.tween_property(
		card,
		"scale",
		original_scale,
		0.10
	)


	tween_back.tween_property(
		card,
		"modulate",
		original_modulate,
		0.10
	)


	await tween_back.finished


# ==================================================
# EKSTRA TOP
# ==================================================

func spawn_extra_ball(_is_temporary: bool = false) -> Node:
	var active_balls = get_tree().get_nodes_in_group("game_ball")
	if active_balls.is_empty() or active_balls.size() >= MAX_ACTIVE_BALLS:
		return null

	var source_ball = active_balls[0]
	var spawn_side := -1.0 if active_balls.size() % 2 == 1 else 1.0
	var spawn_offset := Vector2(8.0 * spawn_side, 0.0)
	var angle_offset := deg_to_rad(8.0 * spawn_side)
	var new_ball = ball_scene.instantiate()
	new_ball.requires_manual_launch = false
	add_child(new_ball)
	new_ball.global_position = source_ball.global_position + spawn_offset
	new_ball.speed = minf(source_ball.speed, new_ball.max_speed)
	new_ball.direction = source_ball.direction.rotated(angle_offset).normalized()
	return new_ball

func ball_lost(ball):
	$HUD/ComboManager.reset_combo()
	ball.remove_from_group(
		"game_ball"
	)


	ball.queue_free()


	var balls_left = get_tree().get_nodes_in_group(
		"game_ball"
	).size()


	# BaÃƒâ€¦Ã…Â¸ka top varsa can gitmez.
	if balls_left > 0:
		return


	lose_life(&"ball_lost")


	if not game_over:

		call_deferred(
			"spawn_fresh_ball"
		)


# ==================================================
# YENÃƒâ€Ã‚Â° TOP
# ==================================================

func spawn_fresh_ball():

	var new_ball = ball_scene.instantiate()
	new_ball.requires_manual_launch = true

	add_child(new_ball)


	new_ball.global_position = Vector2(
		get_viewport_rect().size.x * 0.5,
		paddle.global_position.y - 100.0
	)


	new_ball.direction = Vector2(
		0.7,
		-0.7
	).normalized()


func set_plasma_launch_paused(paused):

	var current_paddle = get_node_or_null("Paddle")
	if current_paddle and current_paddle.has_method("set_plasma_launch_paused"):
		current_paddle.set_plasma_launch_paused(paused)


# ==================================================
# CAN KAYBI
# ==================================================

func lose_life(_reason: StringName = &"ball_lost"):

	if game_over:
		return


	if GameManager.colony_shield_charges > 0:
		# Koloni Kalkan Jeneratoru: can gitmeden darbeyi emer.
		GameManager.colony_shield_charges -= 1
		print("COLONY SHIELD ABSORBED | kalan=%d" % GameManager.colony_shield_charges)
		_show_reward_banner(
			"KALKAN EMD\u0130",
			[{"icon": ICON_LIFE, "text": "%d KALKAN KALDI" % GameManager.colony_shield_charges}],
			Color(0.42, 0.88, 1.0, 1.0),
			SFX_BONUS_REWARD
		)
		return


	GameManager.lives -= 1


	if GameManager.lives <= 0 and GameManager.revive_available:
		# Yedek Cekirdek karti run basina bir kez devreye girer.
		GameManager.revive_available = false
		GameManager.lives = 2
		update_labels()
		pulse_lives_hud()
		print("REVIVE USED")
		_show_reward_banner(
			"YEDEK ÇEKİRDEK DEVREDE",
			[{"icon": ICON_LIFE, "text": "+2"}],
			Color(1.0, 0.42, 0.58, 1.0),
			SFX_BONUS_REWARD
		)
		return


	if GameManager.lives <= 0:

		GameManager.lives = 0

		game_over = true

		update_labels()

		show_game_over()

		return


	update_labels()


# ==================================================
# GAME OVER
# ==================================================

func _register_destroyed_brick_for_summary(brick_instance_id: int) -> bool:
	if brick_instance_id > 0:
		if run_destroyed_brick_ids.has(brick_instance_id):
			return false
		run_destroyed_brick_ids[brick_instance_id] = true
	run_bricks_destroyed += 1
	return true


func _format_run_time() -> String:
	var total_seconds := maxi(0, floori(run_elapsed_seconds))
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]


func _get_final_build_summary() -> String:
	var build_lines: Array[String] = []
	if GameManager.plasma_level > 0:
		if GameManager.plasma_evolution != &"none":
			build_lines.append("PLAZMA \u2014 %s" % String(GameManager.plasma_evolution).to_upper())
		else:
			build_lines.append("PLAZMA Lv%d" % GameManager.plasma_level)
	if GameManager.fireball_level > 0:
		if GameManager.fireball_evolution != &"none":
			build_lines.append("ALEV TOPU \u2014 %s" % String(GameManager.fireball_evolution).to_upper())
		else:
			build_lines.append("ALEV TOPU Lv%d" % GameManager.fireball_level)
	if GameManager.pierce_level > 0:
		if GameManager.pierce_evolution != &"none":
			build_lines.append("DEL\u0130C\u0130 TOP \u2014 %s" % String(GameManager.pierce_evolution).to_upper())
		else:
			build_lines.append("DEL\u0130C\u0130 TOP Lv%d" % GameManager.pierce_level)
	# Pasif kartlar da final build \u00f6zetinde listelensin.
	for card_id: StringName in CardPool.get_ids():
		if CardPool.is_weapon(card_id):
			continue
		var passive_level: int = GameManager.get_card_level(card_id)
		if passive_level <= 0:
			continue
		if CardPool.get_max_level(card_id) > 1:
			build_lines.append("%s Lv%d" % [CardPool.get_title(card_id), passive_level])
		else:
			build_lines.append(CardPool.get_title(card_id))
	return "YOK" if build_lines.is_empty() else String.chr(10).join(build_lines)


func _populate_run_summary() -> void:
	var records: Dictionary = GameManager.register_run_result(
		GameManager.run_depth,
		run_bricks_destroyed,
		run_progression_boss_kills
	)
	var new_depth_record := bool(records.get("new_depth_record", false))
	_show_new_record_badge(new_depth_record)
	var highest_rank: String = $HUD/ComboManager.get_rank_name(highest_combo_rank_index)
	# Rekor mesajını rozet taşıyor; bu satır yalnızca en iyi dereceyi gösterir.
	var depth_line := "ULAŞILAN DEPTH: %d   (EN İYİ: %d)" % [
		GameManager.run_depth, GameManager.best_depth
	]
	var stat_lines: Array[String] = [
		depth_line,
		"TOPLAM SÜRE: %s" % _format_run_time(),
		"YOK EDİLEN TUĞLA: %d" % run_bricks_destroyed,
		"EN YÜKSEK COMBO RANK: %s" % highest_rank,
		"ÖLDÜRÜLEN BOSS: %d" % run_progression_boss_kills,
		"TOPLANAN COIN: %d" % run_coins_collected,
		"KAZANILAN PARÇA: %d" % run_salvage_earned,
		"KASAYA GİREN: %d   (KAYIP: %d)" % [run_salvage_rescued, run_salvage_lost],
		"RUN NO: %d" % GameManager.total_runs,
	]
	var curse_names: Array = GameManager.get_active_curse_names()
	if not curse_names.is_empty():
		stat_lines.append("LANETLER: %s" % ", ".join(curse_names))
	run_summary_stats_label.text = String.chr(10).join(stat_lines)
	run_summary_build_label.text = _get_final_build_summary()

func _show_new_record_badge(active: bool) -> void:
	var summary_box := get_node_or_null("GameOverScreen/VBoxContainer") as VBoxContainer
	if not is_instance_valid(summary_box):
		return
	var badge := summary_box.get_node_or_null("NewRecordBadge") as HBoxContainer
	if not is_instance_valid(badge):
		badge = HBoxContainer.new()
		badge.name = "NewRecordBadge"
		badge.alignment = BoxContainer.ALIGNMENT_CENTER
		badge.add_theme_constant_override("separation", 8)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var badge_tone := Color(1.0, 0.82, 0.24, 1.0)
		var badge_icon := TextureRect.new()
		badge_icon.name = "Icon"
		badge_icon.texture = ICON_TROPHY
		badge_icon.custom_minimum_size = Vector2(26.0, 26.0)
		badge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge_icon.modulate = badge_tone
		badge_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		badge.add_child(badge_icon)
		var badge_label := Label.new()
		badge_label.name = "Text"
		badge_label.text = "YENİ REKOR"
		badge_label.add_theme_font_size_override("font_size", 22)
		badge_label.add_theme_color_override("font_color", badge_tone)
		badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(badge_label)
		summary_box.add_child(badge)
		# Başlığın hemen altına al.
		summary_box.move_child(badge, 1)

	badge.visible = active
	if not active:
		return
	_play_reward_sfx(SFX_NEW_RECORD)
	badge.pivot_offset = badge.size * 0.5
	badge.scale = Vector2(0.80, 0.80)
	badge.modulate.a = 0.0
	var reveal := badge.create_tween()
	reveal.set_parallel(true)
	reveal.tween_property(badge, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal.tween_property(badge, "modulate:a", 1.0, 0.22)


func _award_colony_run_end_bonus_once() -> void:
	if run_colony_bonus_awarded:
		return
	run_colony_bonus_awarded = true
	run_colony_parts_bonus = GameManager.get_colony_run_end_salvage()
	if run_colony_parts_bonus > 0:
		_award_run_salvage(run_colony_parts_bonus)
	# Kasaya alınmamış PARÇA'nın yarısı ölümle birlikte kaybolur.
	var settlement: Dictionary = GameManager.settle_carried_salvage_on_death()
	run_salvage_rescued = int(settlement.get("rescued", 0))
	run_salvage_lost = int(settlement.get("lost", 0))

func show_game_over():
	GameManager.pending_card_choices = 0

	game_over = true
	_award_colony_run_end_bonus_once()
	_populate_run_summary()

	choosing_card = false
	$HUD/ComboManager.reset_combo()
	GameManager.magnet_time_remaining = 0.0
	update_magnet_aura_feedback(0.0)

	card_panel.visible = false
	game_over_screen.visible = true
	get_tree().paused = true

	if OS.has_feature("mobile"):
		retry_button.focus_mode = Control.FOCUS_NONE
		main_menu_button.focus_mode = Control.FOCUS_NONE
	else:
		retry_button.grab_focus()

# ==================================================
# TEKRAR OYNA
# ==================================================

func retry_game():

	GameManager.reset_run()
	GameManager.start_directly = true


	get_tree().paused = false

	get_tree().reload_current_scene()


# ==================================================
# ANA MENÃƒÆ’Ã…â€œYE DÃƒÆ’Ã¢â‚¬â€œN
# ==================================================

func return_to_main_menu():

	GameManager.start_directly = false

	get_tree().paused = false

	get_tree().reload_current_scene()


# ==================================================
# HUD
# ==================================================

func update_labels(update_xp_immediately = true):

	var hearts = ""


	for i in range(GameManager.MAX_LIVES):
		if i < GameManager.lives:
			hearts += "\u2665 "
		else:
			hearts += "\u2661 "

	lives_label.text = hearts


	xp_bar.max_value = GameManager.xp_required
	if update_xp_immediately:
		xp_bar.value = GameManager.current_xp
	update_xp_bar_glow(GameManager.current_xp, GameManager.xp_required)
	level_label.text = "LEVEL " + str(GameManager.run_level)
	xp_label.text = (
		str(GameManager.current_xp)
		+ " / "
		+ str(GameManager.xp_required)
		+ " XP"
	)
