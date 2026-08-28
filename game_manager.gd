extends Node

signal total_coins_changed(total: int)
signal total_salvage_changed(total: int)


# HUD alt kenarıyla ortak oyun alanı üst sınırı.
var PLAYFIELD_TOP = 62.0
const MAX_LIVES = 5
const DESKTOP_GAMEPLAY_CAMERA_ZOOM := 0.88
const DESKTOP_GAMEPLAY_SIDE_MARGIN := 24.0
const DESKTOP_PADDLE_BOTTOM_MARGIN := 48.0
const META_SAVE_PATH := "user://neon_break_meta.cfg"
const BUILDING_PART_DROP_CHANCE := 0.08
const MAX_WEAPON_SLOTS := 2
const MAX_WEAPON_LEVEL := 3
const WEAPON_PLASMA: StringName = &"PLASMA"
const WEAPON_ARC_CANNON: StringName = &"ARC_CANNON"
const WEAPON_SCATTER_CANNON: StringName = &"SCATTER_CANNON"
const WEAPON_RAILGUN: StringName = &"RAILGUN"
const WEAPON_HOMING_MISSILE: StringName = &"HOMING_MISSILE"
const WEAPON_PULSE_LASER: StringName = &"PULSE_LASER"
const WEAPON_MINE_LAUNCHER: StringName = &"MINE_LAUNCHER"
const PADDLE_NEUTRAL: StringName = &"NEUTRAL"
const PADDLE_PLASMA: StringName = &"PLASMA"
const PADDLE_FIRE: StringName = &"FIRE"
const PADDLE_PIERCING: StringName = &"PIERCING"
const PADDLE_NEON_CORE: StringName = &"NEON_CORE"
const PADDLE_IDS: Array[StringName] = [
	PADDLE_NEUTRAL, PADDLE_PLASMA, PADDLE_FIRE, PADDLE_PIERCING, PADDLE_NEON_CORE
]
const PADDLE_PRICES := {
	PADDLE_NEUTRAL: 0,
	PADDLE_PLASMA: 40,
	PADDLE_FIRE: 50,
	PADDLE_PIERCING: 50,
	PADDLE_NEON_CORE: 0,
}

# Her raket run'a farkli baslar. lives/width/speed taban degerleri degistirir,
# start_card run acilisinda ucretsiz gelen silah kartidir.
const PADDLE_PROFILES := {
	PADDLE_NEUTRAL: {
		"name": "STANDART",
		"lives": 3,
		"width": 1.00,
		"speed": 1.00,
		"start_card": &"none",
		"bonus_rerolls": 1,
		"trait": "Dengeli gövde. Run'a +1 yeniden dağıtma ile başlar.",
	},
	PADDLE_PLASMA: {
		"name": "PLAZMA",
		"lives": 3,
		"width": 0.92,
		"speed": 1.00,
		"start_card": &"plasma",
		"bonus_rerolls": 0,
		"trait": "Dar gövde. Plazma Silahı Lv1 ile başlar, Plazma Laboratuvarı bonusu iki katı.",
	},
	PADDLE_FIRE: {
		"name": "ALEV",
		"lives": 2,
		"width": 1.00,
		"speed": 0.95,
		"start_card": &"fireball",
		"bonus_rerolls": 0,
		"trait": "Tek can eksik, yavaş. Alev Topu Lv1 ile başlar, Ateş Reaktörü bonusu iki katı.",
	},
	PADDLE_PIERCING: {
		"name": "DELİCİ",
		"lives": 3,
		"width": 0.88,
		"speed": 1.10,
		"start_card": &"pierce",
		"bonus_rerolls": 0,
		"trait": "En dar ve en hızlı gövde. Delici Top Lv1 ile başlar, Araştırma bonusu iki katı.",
	},
	PADDLE_NEON_CORE: {
		"name": "NEON ÇEKİRDEK",
		"lives": 1,
		"width": 1.15,
		"speed": 1.05,
		"start_card": &"none",
		"bonus_rerolls": 0,
		"trait": "Tek can. Geniş gövde ve run başına 2 kalkan yükü.",
	},
}
# Neon Cekirdek'in tek canini dengeleyen dogustan kalkan yuku.
const NEON_CORE_SHIELD_CHARGES := 2
var mobile_safe_rect := Rect2()
var total_coins := 0
var owned_paddles: Dictionary = {PADDLE_NEUTRAL: true, PADDLE_NEON_CORE: true}
var active_paddle_id: StringName = PADDLE_NEUTRAL
var paddle_affinity: StringName = PADDLE_NEUTRAL

# Persistent Colony prototype state. This is intentionally separate from run reset.
const COLONY_PROTOTYPE_STARTING_SALVAGE := 100
var total_salvage: int = COLONY_PROTOTYPE_STARTING_SALVAGE
var colony_platform_buildings: Array = []
var reactor_built := false
const COLONY_PLATFORM_IDS: Array[String] = ["top_left", "top_right", "middle_left", "middle_right", "bottom_left", "bottom_right"]
const COLONY_BUILDING_PLASMA_LAB := "plasma_lab"
const COLONY_BUILDING_FIRE_REACTOR := "fire_reactor"
const COLONY_BUILDING_PIERCING_RESEARCH := "piercing_research"
const COLONY_BUILDING_PART_FACTORY := "part_factory"
const COLONY_BUILDING_COIN_REFINERY := "coin_refinery"
const COLONY_BUILDING_TECH_CENTER := "tech_center"
const COLONY_BUILDING_SHIELD_GENERATOR := "shield_generator"
const COLONY_BUILDING_SIM_CHAMBER := "sim_chamber"
const COLONY_BUILDING_DATA_ARCHIVE := "data_archive"
# Dokuz bina, alti platform: hangi ucunden vazgectigi oyuncunun karari.
const COLONY_BUILDING_IDS: Array[String] = [
	COLONY_BUILDING_PLASMA_LAB,
	COLONY_BUILDING_FIRE_REACTOR,
	COLONY_BUILDING_PIERCING_RESEARCH,
	COLONY_BUILDING_PART_FACTORY,
	COLONY_BUILDING_COIN_REFINERY,
	COLONY_BUILDING_TECH_CENTER,
	COLONY_BUILDING_SHIELD_GENERATOR,
	COLONY_BUILDING_SIM_CHAMBER,
	COLONY_BUILDING_DATA_ARCHIVE,
]

# ---------- Sonsuz kalibrasyon katmani ----------
# Lv3'ten sonra her bina tekrarlanabilir kalibrasyon alir; maliyet ustel buyur.
const CALIBRATION_BASE_COST := 40
const CALIBRATION_COST_GROWTH := 1.35
const SHIELD_GENERATOR_CHARGES := [0, 1, 1, 2]
const SIM_CHAMBER_REROLLS := [0, 1, 2, 3]
const DATA_ARCHIVE_XP_BONUS := [0.0, 0.08, 0.16, 0.25]
const COIN_BASE_DROP_CHANCE := 0.006
const COIN_REFINERY_BONUSES := [0.0, 0.001, 0.0022, 0.0035]
const MAX_COIN_DROP_CHANCE := 0.01
var reactor_level := 0
var colony_hint_seen := false
var colony_six_slot_migrated := false

# Kalıcı run rekorları. Run reset'inden etkilenmez, her run sonunda güncellenir.
var best_depth := 0
var best_boss_kills := 0
var total_runs := 0
var lifetime_boss_kills := 0
var lifetime_bricks_destroyed := 0

func _ready() -> void:
	load_meta_progression()


func load_meta_progression() -> void:
	total_coins = 0
	owned_paddles = {PADDLE_NEUTRAL: true, PADDLE_NEON_CORE: true}
	active_paddle_id = PADDLE_NEUTRAL
	total_salvage = COLONY_PROTOTYPE_STARTING_SALVAGE
	colony_platform_buildings = []
	reactor_built = false
	reactor_level = 0
	colony_hint_seen = false
	colony_six_slot_migrated = false
	best_depth = 0
	best_boss_kills = 0
	total_runs = 0
	lifetime_boss_kills = 0
	lifetime_bricks_destroyed = 0
	var config := ConfigFile.new()
	var error := config.load(META_SAVE_PATH)
	var migrated_legacy_colony := false
	if error == OK:
		total_coins = maxi(0, int(config.get_value("meta", "total_coins", 0)))
		var saved_owned: Array = config.get_value("meta", "owned_paddles", ["NEUTRAL"])
		for saved_id in saved_owned:
			var paddle_id := StringName(String(saved_id).to_upper())
			if paddle_id in PADDLE_IDS:
				owned_paddles[paddle_id] = true
		var saved_active := StringName(
			String(config.get_value("meta", "active_paddle_id", "NEUTRAL")).to_upper()
		)
		if saved_active in PADDLE_IDS and owned_paddles.has(saved_active):
			active_paddle_id = saved_active
		total_salvage = maxi(
			0,
			int(config.get_value(
				"colony",
				"total_salvage",
				COLONY_PROTOTYPE_STARTING_SALVAGE
			))
		)
		best_depth = maxi(0, int(config.get_value("records", "best_depth", 0)))
		best_boss_kills = maxi(0, int(config.get_value("records", "best_boss_kills", 0)))
		total_runs = maxi(0, int(config.get_value("records", "total_runs", 0)))
		lifetime_boss_kills = maxi(0, int(config.get_value("records", "lifetime_boss_kills", 0)))
		lifetime_bricks_destroyed = maxi(
			0, int(config.get_value("records", "lifetime_bricks_destroyed", 0))
		)
		reactor_built = bool(config.get_value("colony", "reactor_built", false))
		colony_hint_seen = bool(config.get_value("colony", "hint_seen", false))
		colony_six_slot_migrated = bool(config.get_value("colony", "six_slot_migrated", false))
		reactor_level = 1 if reactor_built else 0
	var saved_platforms: Array = config.get_value("colony", "platform_buildings", [])
	var occupied: Dictionary = {}
	for item in saved_platforms:
		if item is Dictionary:
			var e := item as Dictionary
			var sid := String(e.get("slot_id", ""))
			var kind := String(e.get("building_type", e.get("type", "")))
			if sid in COLONY_PLATFORM_IDS and not occupied.has(sid) and kind in ["reactor", "workshop", COLONY_BUILDING_PLASMA_LAB, COLONY_BUILDING_FIRE_REACTOR, COLONY_BUILDING_PIERCING_RESEARCH, COLONY_BUILDING_PART_FACTORY, COLONY_BUILDING_COIN_REFINERY, COLONY_BUILDING_TECH_CENTER]:
				var max_level := 3 if kind in COLONY_BUILDING_IDS else maxi(1, int(e.get("level", 1)))
				colony_platform_buildings.append({
					"building_type": kind,
					"slot_id": sid,
					"level": clampi(int(e.get("level", 1)), 1, max_level),
					"calibration": maxi(0, int(e.get("calibration", 0))),
				})
				occupied[sid] = true
	if reactor_built and not _colony_building_type_exists("reactor"):
		colony_platform_buildings.append({"building_type": "reactor", "slot_id": "top_left", "level": maxi(reactor_level, 1)})
		occupied["top_left"] = true
		migrated_legacy_colony = true
	# Final altı-platform düzeni için eski persistent bina state'ini yalnızca bir kez temizle.
	if not colony_six_slot_migrated:
		colony_platform_buildings.clear()
		reactor_built = false
		reactor_level = 0
		colony_six_slot_migrated = true
		migrated_legacy_colony = true
	paddle_affinity = active_paddle_id
	if migrated_legacy_colony:
		save_meta_progression()


func save_meta_progression() -> void:
	var config := ConfigFile.new()
	var owned_ids: Array[String] = []
	for paddle_id: StringName in PADDLE_IDS:
		if owned_paddles.has(paddle_id):
			owned_ids.append(String(paddle_id))
	config.set_value("meta", "total_coins", total_coins)
	config.set_value("meta", "owned_paddles", owned_ids)
	config.set_value("meta", "active_paddle_id", String(active_paddle_id))
	config.set_value("colony", "total_salvage", total_salvage)
	config.set_value("colony", "platform_buildings", colony_platform_buildings.duplicate(true))
	config.set_value("colony", "reactor_built", reactor_built)
	config.set_value("colony", "reactor_level", reactor_level)
	config.set_value("colony", "hint_seen", colony_hint_seen)
	config.set_value("colony", "six_slot_migrated", colony_six_slot_migrated)
	config.set_value("records", "best_depth", best_depth)
	config.set_value("records", "best_boss_kills", best_boss_kills)
	config.set_value("records", "total_runs", total_runs)
	config.set_value("records", "lifetime_boss_kills", lifetime_boss_kills)
	config.set_value("records", "lifetime_bricks_destroyed", lifetime_bricks_destroyed)
	var error := config.save(META_SAVE_PATH)
	if error != OK:
		push_warning("Meta progression save failed: %s" % error_string(error))


func build_colony_reactor(slot_id: String = "top_left", cost: int = 10) -> bool:
	if reactor_built or slot_id not in COLONY_PLATFORM_IDS or not get_colony_platform_building(slot_id).is_empty() or cost < 0 or total_salvage < cost:
		return false
	total_salvage -= cost
	reactor_built = true
	reactor_level = 1
	colony_platform_buildings.append({"building_type": "reactor", "slot_id": slot_id, "level": 1})
	save_meta_progression()
	return true

func build_colony_building(building_id: String, slot_id: String, cost: int) -> bool:
	if building_id not in COLONY_BUILDING_IDS:
		return false
	if slot_id not in COLONY_PLATFORM_IDS or cost < 0 or total_salvage < cost:
		return false
	if not get_colony_platform_building(slot_id).is_empty():
		return false
	if _colony_building_type_exists(building_id):
		return false
	total_salvage -= cost
	colony_platform_buildings.append({
		"building_type": building_id,
		"slot_id": slot_id,
		"level": 1,
	})
	save_meta_progression()
	return true


func upgrade_colony_building(slot_id: String, cost: int, max_level: int = 3) -> bool:
	if cost < 0 or total_salvage < cost:
		return false
	for entry in colony_platform_buildings:
		if not entry is Dictionary:
			continue
		var building := entry as Dictionary
		if String(building.get("slot_id", "")) != slot_id:
			continue
		var current_level := int(building.get("level", 1))
		if current_level >= max_level:
			return false
		total_salvage -= cost
		building["level"] = current_level + 1
		save_meta_progression()
		return true
	return false


func get_calibration_cost(calibration_level: int) -> int:
	return int(round(
		float(CALIBRATION_BASE_COST) * pow(CALIBRATION_COST_GROWTH, maxi(calibration_level, 0))
	))


func get_colony_building_calibration(building_id: String) -> int:
	var highest := 0
	for entry in colony_platform_buildings:
		if entry is Dictionary and String((entry as Dictionary).get("building_type", "")) == building_id:
			highest = maxi(highest, int((entry as Dictionary).get("calibration", 0)))
	return highest


func calibrate_colony_building(slot_id: String) -> bool:
	for entry in colony_platform_buildings:
		if not entry is Dictionary:
			continue
		var building := entry as Dictionary
		if String(building.get("slot_id", "")) != slot_id:
			continue
		# Kalibrasyon yalnizca Lv3 binalarda acilir.
		if int(building.get("level", 1)) < 3:
			return false
		var calibration := int(building.get("calibration", 0))
		var cost := get_calibration_cost(calibration)
		if total_salvage < cost:
			return false
		total_salvage -= cost
		building["calibration"] = calibration + 1
		save_meta_progression()
		return true
	return false


func get_colony_building_level(building_id: String) -> int:
	var highest_level := 0
	for entry in colony_platform_buildings:
		if entry is Dictionary and String((entry as Dictionary).get("building_type", "")) == building_id:
			highest_level = maxi(highest_level, int((entry as Dictionary).get("level", 0)))
	return highest_level

func get_colony_platform_building(slot_id: String) -> Dictionary:
	for entry in colony_platform_buildings:
		if entry is Dictionary and String((entry as Dictionary).get("slot_id", "")) == slot_id:
			return entry as Dictionary
	return {}

func _colony_building_type_exists(building_type: String) -> bool:
	for entry in colony_platform_buildings:
		if entry is Dictionary and String((entry as Dictionary).get("building_type", "")) == building_type:
			return true
	return false

# ---------- Koloni etki getter'lari ----------

func get_colony_shield_charges() -> int:
	var level := clampi(get_colony_building_level(COLONY_BUILDING_SHIELD_GENERATOR), 0, 3)
	var charges: int = SHIELD_GENERATOR_CHARGES[level]
	if charges <= 0:
		return 0
	# Her 3 kalibrasyonda bir ek kalkan.
	return charges + int(get_colony_building_calibration(COLONY_BUILDING_SHIELD_GENERATOR) / 3)


func get_colony_bonus_rerolls() -> int:
	var level := clampi(get_colony_building_level(COLONY_BUILDING_SIM_CHAMBER), 0, 3)
	var rerolls: int = SIM_CHAMBER_REROLLS[level]
	if rerolls <= 0:
		return 0
	# Her 2 kalibrasyonda bir ek reroll.
	return rerolls + int(get_colony_building_calibration(COLONY_BUILDING_SIM_CHAMBER) / 2)


func get_colony_xp_bonus() -> float:
	var level := clampi(get_colony_building_level(COLONY_BUILDING_DATA_ARCHIVE), 0, 3)
	var bonus: float = DATA_ARCHIVE_XP_BONUS[level]
	if bonus <= 0.0:
		return 0.0
	return bonus + 0.02 * float(get_colony_building_calibration(COLONY_BUILDING_DATA_ARCHIVE))


func get_colony_plasma_interval_scale() -> float:
	# Her kalibrasyon plazma ates araligini %2 kisaltir.
	return pow(0.98, float(get_colony_building_calibration(COLONY_BUILDING_PLASMA_LAB)))


func get_colony_fire_radius_scale() -> float:
	return 1.0 + 0.03 * float(get_colony_building_calibration(COLONY_BUILDING_FIRE_REACTOR))


func get_colony_bonus_pierce() -> int:
	# Her 4 kalibrasyonda +1 delme.
	return int(get_colony_building_calibration(COLONY_BUILDING_PIERCING_RESEARCH) / 4)


func get_colony_magnet_scale() -> float:
	return 1.0 + 0.05 * float(get_colony_building_calibration(COLONY_BUILDING_TECH_CENTER))


func get_effective_coin_drop_chance(base_chance: float) -> float:
	var refinery_level := clampi(get_colony_building_level(COLONY_BUILDING_COIN_REFINERY), 0, 3)
	return minf(
		maxf(base_chance, 0.0)
		+ float(COIN_REFINERY_BONUSES[refinery_level])
		+ 0.0003 * float(get_colony_building_calibration(COLONY_BUILDING_COIN_REFINERY)),
		MAX_COIN_DROP_CHANCE
	)

func get_colony_run_end_salvage() -> int:
	var level := clampi(get_colony_building_level(COLONY_BUILDING_PART_FACTORY), 0, 3)
	var rewards := [0, 2, 4, 7]
	var reward: int = rewards[level]
	if reward <= 0:
		return 0
	# Her 2 kalibrasyonda run sonu +1 PARCA.
	return reward + int(get_colony_building_calibration(COLONY_BUILDING_PART_FACTORY) / 2)


func register_run_result(
	reached_depth: int,
	bricks_destroyed: int,
	boss_kills: int
) -> Dictionary:
	# Run bitişinde bir kez çağrılır. Hangi rekorların kırıldığını geri döner.
	var new_depth_record := reached_depth > best_depth
	var new_boss_record := boss_kills > best_boss_kills
	total_runs += 1
	lifetime_boss_kills += maxi(0, boss_kills)
	lifetime_bricks_destroyed += maxi(0, bricks_destroyed)
	best_depth = maxi(best_depth, reached_depth)
	best_boss_kills = maxi(best_boss_kills, boss_kills)
	save_meta_progression()
	return {
		"new_depth_record": new_depth_record,
		"new_boss_record": new_boss_record,
	}


func add_salvage(amount: int) -> void:
	if amount <= 0:
		return
	total_salvage = maxi(0, total_salvage + amount)
	save_meta_progression()
	total_salvage_changed.emit(total_salvage)

# COLONY DEBUG - REMOVE BEFORE RELEASE
func debug_reset_colony_building_progression() -> void:
	colony_platform_buildings.clear()
	reactor_built = false
	reactor_level = 0
	save_meta_progression()

func add_coins(amount: int) -> void:
	total_coins = maxi(0, total_coins + amount)
	save_meta_progression()
	total_coins_changed.emit(total_coins)


func purchase_paddle(paddle_id: StringName) -> bool:
	if paddle_id not in PADDLE_IDS or owned_paddles.has(paddle_id):
		return false
	var price := int(PADDLE_PRICES.get(paddle_id, 0))
	if total_coins < price:
		return false
	total_coins -= price
	owned_paddles[paddle_id] = true
	save_meta_progression()
	total_coins_changed.emit(total_coins)
	return true


func activate_paddle(paddle_id: StringName) -> bool:
	if paddle_id not in PADDLE_IDS or not owned_paddles.has(paddle_id):
		return false
	active_paddle_id = paddle_id
	save_meta_progression()
	return true


func resolve_boss_direct_hit_damage(source: StringName, fallback_amount: int = 0) -> int:
	match source:
		&"plasma":
			return 1
		&"ball", &"piercing_ball":
			return 2
		&"fireball_ball":
			return 3
		&"fireball_splash", &"napalm", &"explosion", &"chain_lightning":
			return 0
	return fallback_amount


func refresh_mobile_safe_area(logical_viewport_size: Vector2) -> Rect2:
	if not OS.has_feature("mobile"):
		mobile_safe_rect = Rect2(Vector2.ZERO, logical_viewport_size)
		return mobile_safe_rect

	var physical_safe := DisplayServer.get_display_safe_area()
	var physical_window := DisplayServer.window_get_size()
	if physical_safe.size.x <= 0 or physical_safe.size.y <= 0:
		mobile_safe_rect = Rect2(Vector2.ZERO, logical_viewport_size)
		return mobile_safe_rect

	var physical_size := Vector2(physical_window)
	if physical_size.x <= 0.0 or physical_size.y <= 0.0:
		physical_size = Vector2(DisplayServer.screen_get_size())
	var scale_to_logical := Vector2(
		logical_viewport_size.x / maxf(physical_size.x, 1.0),
		logical_viewport_size.y / maxf(physical_size.y, 1.0)
	)
	var safe_position := Vector2(physical_safe.position) * scale_to_logical
	var safe_size := Vector2(physical_safe.size) * scale_to_logical
	mobile_safe_rect = Rect2(safe_position, safe_size).intersection(
		Rect2(Vector2.ZERO, logical_viewport_size)
	)
	if mobile_safe_rect.size.x <= 0.0 or mobile_safe_rect.size.y <= 0.0:
		mobile_safe_rect = Rect2(Vector2.ZERO, logical_viewport_size)
	return mobile_safe_rect


func get_desktop_visible_world_rect(viewport_size: Vector2) -> Rect2:
	var zoom_value := maxf(DESKTOP_GAMEPLAY_CAMERA_ZOOM, 0.01)
	var visible_size := viewport_size / zoom_value
	# Keep PLAYFIELD_TOP at the same screen-space Y while revealing more world below it.
	var world_top: float = float(PLAYFIELD_TOP) - float(PLAYFIELD_TOP) / zoom_value
	return Rect2(Vector2(0.0, world_top), visible_size)


func get_gameplay_rect(viewport_size: Vector2) -> Rect2:
	if OS.has_feature("mobile"):
		return get_layout_safe_rect(viewport_size)
	var visible_rect := get_desktop_visible_world_rect(viewport_size)
	var world_side_margin := DESKTOP_GAMEPLAY_SIDE_MARGIN / DESKTOP_GAMEPLAY_CAMERA_ZOOM
	return Rect2(
		visible_rect.position + Vector2(world_side_margin, 0.0),
		Vector2(maxf(visible_rect.size.x - world_side_margin * 2.0, 1.0), visible_rect.size.y)
	)


func get_gameplay_bottom(viewport_size: Vector2) -> float:
	if OS.has_feature("mobile"):
		var safe_rect := get_layout_safe_rect(viewport_size)
		return safe_rect.position.y + safe_rect.size.y
	return get_desktop_visible_world_rect(viewport_size).end.y

func get_layout_safe_rect(viewport_size: Vector2) -> Rect2:
	if OS.has_feature("mobile") and mobile_safe_rect.size.x > 0.0:
		return mobile_safe_rect
	return Rect2(Vector2.ZERO, viewport_size)


var level = 1
var lives = 3
var run_depth = 1

var start_directly = false
var music_enabled := true

var run_level = 1
var current_xp = 0
var xp_required = 100
var pending_levelup_card = false
var first_card_selection_done := false

var plasma_level = 0
var plasma_evolution: StringName = &"none"
var evolution_credits: int = 0
var pierce_level = 0
var fireball_level = 0
var fireball_evolution: StringName = &"none"
var pierce_evolution: StringName = &"none"
var magnet_time_remaining = 0.0
var post_boss_descent_multiplier: float = 1.0

# Pasif kart seviyeleri: StringName -> int. Silah kartları yukarıdaki kendi alanlarını kullanır.
var card_levels: Dictionary = {}
# Bu run'da banish edilmiş kartlar bir daha teklif edilmez.
var banished_cards: Dictionary = {}
var rerolls_remaining := 0
var banishes_remaining := 0
const RUN_START_REROLLS := 2
const RUN_START_BANISHES := 1
# Yedek Çekirdek kartı harcanınca kapanır.
var revive_available := false
# Codex silah yuvasi sistemi: iki yuva, her biri Lv3'e kadar.
var weapon_slots: Array[Dictionary] = [
	{"weapon_id": &"", "level": 0},
	{"weapon_id": &"", "level": 0},
]
# Kalkan Jeneratörü'nden gelen, can kaybını önleyen ücretsiz yükler.
var colony_shield_charges := 0


func reset_run():

	paddle_affinity = active_paddle_id

	level = 1
	lives = 3
	run_depth = 1

	run_level = 1
	current_xp = 0
	xp_required = 100
	pending_levelup_card = false
	first_card_selection_done = false

	plasma_level = 0
	plasma_evolution = &"none"
	evolution_credits = 0
	pierce_level = 0
	fireball_level = 0
	fireball_evolution = &"none"
	pierce_evolution = &"none"
	magnet_time_remaining = 0.0
	post_boss_descent_multiplier = 1.0
	card_levels = {}
	banished_cards = {}
	reset_weapon_slots()
	_apply_paddle_profile_to_run()


## Aktif raketin kimligi run baslangic durumunu belirler.
func _apply_paddle_profile_to_run() -> void:
	var profile := get_paddle_profile(paddle_affinity)
	lives = clampi(int(profile.get("lives", 3)), 1, MAX_LIVES)
	rerolls_remaining = (
		RUN_START_REROLLS
		+ get_colony_bonus_rerolls()
		+ int(profile.get("bonus_rerolls", 0))
	)
	banishes_remaining = RUN_START_BANISHES
	revive_available = false
	colony_shield_charges = get_colony_shield_charges()
	if paddle_affinity == PADDLE_NEON_CORE:
		colony_shield_charges += NEON_CORE_SHIELD_CHARGES
	# Raketin imza silahi ucretsiz gelir; acilis kart eli buna gore daralir.
	var start_card: StringName = profile.get("start_card", &"none")
	if start_card != &"none":
		if start_card == &"plasma":
			# Plazma artik yuva sisteminde tutuluyor; iki taraf ayni degeri gormeli.
			acquire_or_upgrade_weapon(WEAPON_PLASMA)
		else:
			set_card_level(start_card, 1)


func add_life():

	if lives >= MAX_LIVES:
		return false

	lives = mini(lives + 1, MAX_LIVES)
	return true


func set_magnet_time(duration):

	magnet_time_remaining = duration


# ==================================================
# KART SEVİYELERİ VE PASİF EFEKTLER
# ==================================================

# ==================================================
# SİLAH YUVALARI (Codex)
# ==================================================

func _empty_weapon_slot() -> Dictionary:
	return {"weapon_id": &"", "level": 0}


func reset_weapon_slots() -> void:
	weapon_slots.clear()
	for slot_index in range(MAX_WEAPON_SLOTS):
		weapon_slots.append(_empty_weapon_slot())
	plasma_level = 0
	debug_print_weapon_slots()


func get_weapon_slot_index(weapon_id: StringName) -> int:
	for slot_index in range(weapon_slots.size()):
		if StringName(weapon_slots[slot_index].get("weapon_id", &"")) == weapon_id:
			return slot_index
	return -1


func has_weapon(weapon_id: StringName) -> bool:
	return get_weapon_slot_index(weapon_id) >= 0


func get_weapon_level(weapon_id: StringName) -> int:
	var slot_index := get_weapon_slot_index(weapon_id)
	if slot_index < 0:
		return 0
	return clampi(int(weapon_slots[slot_index].get("level", 0)), 0, MAX_WEAPON_LEVEL)


func has_empty_weapon_slot() -> bool:
	for slot in weapon_slots:
		if StringName(slot.get("weapon_id", &"")) == &"":
			return true
	return false


func can_acquire_weapon(weapon_id: StringName) -> bool:
	if weapon_id == &"":
		return false
	var current_level := get_weapon_level(weapon_id)
	return current_level < MAX_WEAPON_LEVEL and (current_level > 0 or has_empty_weapon_slot())


func acquire_or_upgrade_weapon(weapon_id: StringName) -> int:
	if not can_acquire_weapon(weapon_id):
		return get_weapon_level(weapon_id)
	var slot_index := get_weapon_slot_index(weapon_id)
	if slot_index < 0:
		for index in range(weapon_slots.size()):
			if StringName(weapon_slots[index].get("weapon_id", &"")) == &"":
				slot_index = index
				weapon_slots[index] = {"weapon_id": weapon_id, "level": 1}
				break
	else:
		weapon_slots[slot_index]["level"] = mini(
			int(weapon_slots[slot_index].get("level", 0)) + 1,
			MAX_WEAPON_LEVEL
		)
	var level := get_weapon_level(weapon_id)
	if weapon_id == WEAPON_PLASMA:
		plasma_level = level
	debug_print_weapon_slots()
	return level


func get_weapon_slots_debug_text() -> String:
	var labels: Array[String] = []
	for slot in weapon_slots:
		var weapon_id := StringName(slot.get("weapon_id", &""))
		if weapon_id == &"":
			labels.append("EMPTY")
		else:
			var display_name := "Plasma" if weapon_id == WEAPON_PLASMA else String(weapon_id)
			labels.append("%s Lv%d" % [display_name, int(slot.get("level", 0))])
	return " | ".join(labels)


func debug_print_weapon_slots() -> void:
	if not OS.is_debug_build():
		return
	for slot_index in range(MAX_WEAPON_SLOTS):
		var slot := weapon_slots[slot_index]
		var weapon_id := StringName(slot.get("weapon_id", &""))
		if weapon_id == &"":
			print("WEAPON SLOT %d: EMPTY" % (slot_index + 1))
		else:
			print("WEAPON SLOT %d: %s LV%d" % [slot_index + 1, String(weapon_id), int(slot.get("level", 0))])


func get_card_level(card_id: StringName) -> int:
	# Silah kartları kendi alanlarında, pasifler card_levels sözlüğünde tutulur.
	match card_id:
		&"plasma":
			return plasma_level
		&"pierce":
			return pierce_level
		&"fireball":
			return fireball_level
	return int(card_levels.get(card_id, 0))


func set_card_level(card_id: StringName, level: int) -> void:
	match card_id:
		&"plasma":
			plasma_level = level
		&"pierce":
			pierce_level = level
		&"fireball":
			fireball_level = level
		_:
			card_levels[card_id] = level


func get_active_weapon_count() -> int:
	var count := 0
	for weapon_level: int in [plasma_level, pierce_level, fireball_level]:
		if weapon_level > 0:
			count += 1
	return count


func get_paddle_profile(paddle_id: StringName = active_paddle_id) -> Dictionary:
	return PADDLE_PROFILES.get(paddle_id, PADDLE_PROFILES[PADDLE_NEUTRAL])


func get_paddle_starting_lives() -> int:
	return int(get_paddle_profile(paddle_affinity).get("lives", 3))


func get_paddle_width_scale() -> float:
	return float(get_paddle_profile(paddle_affinity).get("width", 1.0))


func get_paddle_speed_scale() -> float:
	return float(get_paddle_profile(paddle_affinity).get("speed", 1.0))


## Eslesen koloni binasinin etkisi iki katina cikar; eslesmeyende etki yine de calisir.
func get_affinity_scale(paddle_id: StringName) -> float:
	return 2.0 if paddle_affinity == paddle_id else 1.0


func get_paddle_speed_multiplier() -> float:
	return (1.0 + 0.12 * float(get_card_level(&"paddle_speed"))) * get_paddle_speed_scale()


func get_paddle_width_multiplier() -> float:
	return (1.0 + 0.08 * float(get_card_level(&"paddle_width"))) * get_paddle_width_scale()


func get_xp_gain_multiplier() -> float:
	return 1.0 + 0.20 * float(get_card_level(&"xp_gain")) + get_colony_xp_bonus()


func get_drop_rate_multiplier() -> float:
	return 1.0 + 0.25 * float(get_card_level(&"drop_rate"))


func get_magnet_duration_multiplier() -> float:
	return (
		(1.0 + 0.30 * float(get_card_level(&"magnet_duration")))
		* get_colony_magnet_scale()
	)


func get_combo_timeout_multiplier() -> float:
	return 1.0 + 0.25 * float(get_card_level(&"combo_window"))


func get_ball_speed_multiplier() -> float:
	return 1.0 + 0.10 * float(get_card_level(&"ball_speed"))


func get_crit_chance() -> float:
	return 0.14 * float(get_card_level(&"crit_hit"))


func get_salvage_drop_multiplier() -> float:
	# Lv1 iki kat, Lv2 üç kat.
	return 1.0 + float(get_card_level(&"salvage_find"))


func get_bonus_ball_count() -> int:
	return get_card_level(&"extra_ball")


func get_card_descent_multiplier() -> float:
	return 0.85 if get_card_level(&"slow_descent") > 0 else 1.0


func get_build_threat() -> int:
	var effective_plasma_level: int = (
		maxi(plasma_level, 3) if plasma_evolution != &"none" else plasma_level
	)
	var effective_fireball_level: int = (
		maxi(fireball_level, 3) if fireball_evolution != &"none" else fireball_level
	)
	var active_levels: Array[int] = []
	for card_level: int in [effective_plasma_level, effective_fireball_level, pierce_level]:
		if card_level > 0:
			active_levels.append(card_level)

	# Üç ana kart birlikteyse level'lardan bağımsız olarak en yüksek threat önceliklidir.
	if active_levels.size() == 3:
		return 3
	if active_levels.size() < 2:
		return 0
	for card_level: int in active_levels:
		if card_level >= 3:
			return 2
	return 1


func get_build_speed_multiplier() -> float:
	match get_build_threat():
		1:
			return 0.94
		2:
			return 0.90
		3:
			return 0.86
	return 1.0


func get_power_synergy_tier() -> int:
	var active_levels: Array[int] = []
	for card_level: int in [plasma_level, pierce_level, fireball_level]:
		if card_level > 0:
			active_levels.append(card_level)
	if active_levels.size() < 2:
		return 0

	var level_two_or_higher := 0
	for card_level: int in active_levels:
		if card_level >= 2:
			level_two_or_higher += 1
	if active_levels.size() == 3 and level_two_or_higher >= 2:
		return 4
	if active_levels.size() == 3 or level_two_or_higher >= 2:
		return 3
	if level_two_or_higher >= 1:
		return 2
	return 1


func get_power_synergy_interval_multiplier(tier: int = get_power_synergy_tier()) -> float:
	match tier:
		1:
			return 0.92
		2:
			return 0.85
		3:
			return 0.78
		4:
			return 0.73
	return 1.0


func get_power_synergy_row_fill_bonus(tier: int = get_power_synergy_tier()) -> float:
	match tier:
		1:
			return 0.05
		2:
			return 0.10
		3, 4:
			return 0.15
	return 0.0

func get_late_game_descent_multiplier(depth: int = run_depth) -> float:
	if depth <= 4:
		return 1.00
	if depth <= 8:
		return 0.94
	if depth <= 12:
		return 0.87
	if depth <= 16:
		return 0.79
	if depth <= 20:
		return 0.71
	if depth <= 24:
		return 0.64
	return 0.58


func get_late_game_side_attacker_multiplier(depth: int = run_depth) -> float:
	if depth >= 21:
		return 0.60
	if depth >= 17:
		return 0.70
	if depth >= 13:
		return 0.80
	if depth >= 9:
		return 0.90
	return 1.0
