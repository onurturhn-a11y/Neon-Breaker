extends Node


# ==================================================
# SAHNELER
# ==================================================

var brick_scene = preload(
	"res://brick_piece.tscn"
)

var brick_count = 0


# ==================================================
# TUĞLA YERLEŞİMİ
# ==================================================

# Board doluluk oraninin normalizasyon tabani (continuous_brick_field kullanir).
const GRID_ROWS = 8
var grid_columns = 13
var minimum_row_bricks = 5

var start_x = 132.0

var gap_x = 74.0
var gap_y = 29.0


var brick_scale = Vector2(
	0.6765,
	0.6435
)
const MOBILE_BRICK_SCALE_MULTIPLIER := 1.3924
const DESKTOP_BRICK_COLLISION_WIDTH := 100.0 * 0.6765


# ==================================================
# ZIRH
# ==================================================

var armored_chance = 0.05


# ==================================================
# HAREKETLİ TUĞLA ŞANSI
# ==================================================

var continuous_row_fill = 0.45
@export_range(0.0, 1.0, 0.01) var explosive_chance = 0.05
@export_range(0.0, 1.0, 0.01) var shield_chance = 0.0
@export_range(0.0, 1.0, 0.05) var special_brick_row_cap = 0.40
var special_bricks_created = 0
var special_brick_cap_count = 999
var shield_bricks_created = 0
var next_continuous_row_id = 0
var portrait_mobile_layout := false
const MOBILE_ROW_FILL_BONUS := 0.10
const MAX_CONTINUOUS_ROW_FILL := 0.95
var mobile_power_synergy_tier := 0
var mobile_power_synergy_pressure_scale := 0.0


func configure_for_viewport(layout_rect: Rect2, portrait_mobile: bool) -> void:
	portrait_mobile_layout = portrait_mobile
	var mobile_collision_width := 100.0 * 0.6765 * MOBILE_BRICK_SCALE_MULTIPLIER
	var mobile_gap := 6.0
	var six_column_width := mobile_collision_width * 6.0 + mobile_gap * 5.0
	if portrait_mobile:
		grid_columns = 6 if layout_rect.size.x >= six_column_width else 5
	else:
		grid_columns = maxi(1, floori((layout_rect.size.x - DESKTOP_BRICK_COLLISION_WIDTH) / 74.0) + 1)
	minimum_row_bricks = 2 if portrait_mobile else 5
	# Büyütülmüş collision genişliğiyle yaklaşık 6 px güvenli görsel boşluk kalır.
	gap_x = mobile_collision_width + mobile_gap if portrait_mobile else 74.0
	var mobile_collision_height := 35.0 * 0.6435 * MOBILE_BRICK_SCALE_MULTIPLIER
	gap_y = mobile_collision_height + 5.0 if portrait_mobile else 29.0
	brick_scale = Vector2(0.6765, 0.6435) * (
		MOBILE_BRICK_SCALE_MULTIPLIER if portrait_mobile else 1.0
	)
	# Brick scale/gap değişmez; yalnızca aynı grid yatay olarak viewport merkezine alınır.
	start_x = layout_rect.position.x + (
		layout_rect.size.x - float(grid_columns - 1) * gap_x
	) * 0.5


# ==================================================
# RENKLER
# ==================================================

var colors = [
	Color("#ff7a2f"),
	Color("#b84dff"),
	Color("#247cff"),
	Color("#00e5ff"),
	Color("#28e07b")
]


func configure_for_depth(depth):
	shield_chance = 0.0

	# Eski gameplay level yerine kesintisiz run derinliği kullanılır.
	match depth:
		1:
			continuous_row_fill = 0.45
			armored_chance = 0.0
			explosive_chance = 0.03
		2:
			continuous_row_fill = 0.60
			armored_chance = 0.0
			explosive_chance = 0.04
		3:
			continuous_row_fill = 0.72
			armored_chance = 0.0
			explosive_chance = 0.05
		4:
			continuous_row_fill = 0.82
			armored_chance = 0.05
			explosive_chance = 0.05
		5:
			continuous_row_fill = 0.90
			armored_chance = 0.05
			explosive_chance = 0.07
		6:
			continuous_row_fill = 0.91
			armored_chance = 0.10
			explosive_chance = 0.08
			shield_chance = 0.02
		7:
			continuous_row_fill = 0.92
			armored_chance = 0.15
			explosive_chance = 0.09
			shield_chance = 0.03
		8:
			continuous_row_fill = 0.93
			armored_chance = 0.20
			explosive_chance = 0.10
			shield_chance = 0.04
		9:
			continuous_row_fill = 0.94
			armored_chance = 0.25
			explosive_chance = 0.11
			shield_chance = 0.05
		_:
			# Depth 10+ taban değerleri. Faz 4: eskiden 80. depth'e kadar sabitti;
			# artık patlayıcı ve kalkan oranı derinlikle yavaşça büyür.
			continuous_row_fill = 0.95
			armored_chance = 0.30
			explosive_chance = minf(0.12 + float(depth - 10) * 0.0015, 0.20)
			shield_chance = minf(0.055 + float(depth - 10) * 0.005, 0.08)

	# İlk üç depth korunur; mobile board-pressure bonusu Depth 4'te devreye girer.
	if portrait_mobile_layout and depth >= 4:
		continuous_row_fill = minf(
			continuous_row_fill + MOBILE_ROW_FILL_BONUS,
			MAX_CONTINUOUS_ROW_FILL
		)

func set_mobile_power_synergy(tier: int, pressure_scale: float) -> void:
	mobile_power_synergy_tier = clampi(tier, 0, 4)
	mobile_power_synergy_pressure_scale = clampf(pressure_scale, 0.0, 1.0)


func get_effective_continuous_row_fill() -> float:
	# Faz 4: sinerji cezası kaldırıldı; yerini sektör modifier'ı aldı.
	return minf(
		continuous_row_fill + GameManager.get_sector_row_fill_bonus(),
		MAX_CONTINUOUS_ROW_FILL
	)

func has_any_run_upgrade() -> bool:
	return (
		GameManager.plasma_level > 0
		or GameManager.pierce_level > 0
		or GameManager.fireball_level > 0
	)


func get_effective_armored_chance() -> float:
	if not has_any_run_upgrade():
		return 0.0
	# Faz 4: build-tabanlı zırh cezası kaldırıldı; yalnızca derinlik ölçekler.
	var effective_chance: float = armored_chance
	if GameManager.run_depth >= 49:
		effective_chance += 0.16
	elif GameManager.run_depth >= 33:
		effective_chance += 0.14
	elif GameManager.run_depth >= 21:
		effective_chance += 0.12
	elif GameManager.run_depth >= 17:
		effective_chance += 0.09
	elif GameManager.run_depth >= 13:
		effective_chance += 0.07
	elif GameManager.run_depth >= 9:
		effective_chance += 0.05
	elif GameManager.run_depth >= 5:
		effective_chance += 0.02
	return minf(effective_chance + GameManager.get_curse_armor_bonus(), 0.42)


func get_effective_shield_chance() -> float:
	if not has_any_run_upgrade():
		return 0.0
	# Faz 4: build-tabanlı kalkan cezası kaldırıldı; yalnızca derinlik ölçekler.
	var effective_chance: float = shield_chance
	if GameManager.run_depth >= 49:
		effective_chance += 0.08
	elif GameManager.run_depth >= 33:
		effective_chance += 0.07
	elif GameManager.run_depth >= 21:
		effective_chance += 0.06
	elif GameManager.run_depth >= 17:
		effective_chance += 0.04
	elif GameManager.run_depth >= 13:
		effective_chance += 0.03
	elif GameManager.run_depth >= 9:
		effective_chance += 0.02
	return minf(effective_chance, 0.09)


func create_continuous_row(parent, row_y, row_index):

	brick_count = 0
	var pattern = randi_range(0, 3)
	var occupied = []

	for column in range(grid_columns):
		var should_create = false

		match pattern:
			0: # Full-ish: çok yoğun fakat her zaman kusursuz full değil.
				should_create = randf() < 0.90
			1: # Alternating/checker, aralara birkaç ek brick eklenir.
				should_create = ((row_index + column) % 2 == 0) or randf() < 0.28
			2: # Random gaps.
				should_create = randf() < 0.68
			3: # Birkaç boşluklu yoğun satır.
				should_create = randf() < 0.82

		if should_create:
			occupied.append(column)

	var target_brick_count = clampi(
		roundi(grid_columns * get_effective_continuous_row_fill()),
		minimum_row_bricks,
		grid_columns
	)
	special_bricks_created = 0
	shield_bricks_created = 0
	special_brick_cap_count = maxi(
		1,
		floori(target_brick_count * special_brick_row_cap)
	)

	# Pattern karakterini korurken row'u mevcut depth yoğunluğuna getir.
	while occupied.size() > target_brick_count:
		occupied.remove_at(randi_range(0, occupied.size() - 1))

	while occupied.size() < target_brick_count:
		var fallback_column = randi_range(0, grid_columns - 1)
		if not occupied.has(fallback_column):
			occupied.append(fallback_column)

	occupied.sort()
	var row_bricks: Dictionary = {}
	var row_id = next_continuous_row_id
	next_continuous_row_id += 1

	for column in occupied:
		var brick = create_brick(
			parent,
			Vector2(start_x + column * gap_x, row_y),
			colors.pick_random(),
			row_id,
			column,
			true
		)
		row_bricks[column] = brick

	for column in occupied:
		var shield_brick = row_bricks[column]
		if shield_brick.get("is_shield_brick") != true:
			continue
		shield_brick.setup_shield_neighbors(
			row_bricks.get(column - 1),
			row_bricks.get(column + 1)
		)

	return brick_count


# ==================================================
# TUĞLA OLUŞTUR
# ==================================================

func create_side_wave_group(
	parent,
	spawn_positions: Array[Vector2],
	columns: Array[int]
) -> Array[Node2D]:
	var created_bricks: Array[Node2D] = []
	if spawn_positions.size() != columns.size() or spawn_positions.is_empty():
		return created_bricks
	special_bricks_created = 0
	shield_bricks_created = 0
	special_brick_cap_count = maxi(
		1,
		floori(spawn_positions.size() * special_brick_row_cap)
	)
	var row_id: int = next_continuous_row_id
	next_continuous_row_id += 1
	var row_bricks: Dictionary = {}
	for index in range(spawn_positions.size()):
		var column := columns[index]
		var brick := create_brick(
			parent,
			spawn_positions[index],
			colors.pick_random(),
			row_id,
			column,
			true
		) as Node2D
		created_bricks.append(brick)
		row_bricks[column] = brick
	for column in columns:
		var shield_brick = row_bricks[column]
		if shield_brick.get("is_shield_brick") == true:
			shield_brick.setup_shield_neighbors(
				row_bricks.get(column - 1),
				row_bricks.get(column + 1)
			)
	return created_bricks


func create_brick(
	parent,
	pos,
	color,
	row_id = -1,
	column_id = -1,
	allow_shield = false
):

	var brick = brick_scene.instantiate()
	var make_explosive = false
	var make_armored = false
	var make_shield = false

	if special_bricks_created < special_brick_cap_count:
		var special_roll = randf()
		var active_shield_chance = get_effective_shield_chance() if (
			allow_shield and shield_bricks_created < 1
		) else 0.0
		var active_armored_chance = get_effective_armored_chance()
		var active_explosive_chance: float = minf(
			explosive_chance + GameManager.get_sector_explosive_bonus(), 0.32
		)
		if special_roll < active_shield_chance:
			make_shield = true
			shield_bricks_created += 1
		elif special_roll < active_shield_chance + active_explosive_chance:
			make_explosive = true
		elif special_roll < active_shield_chance + active_explosive_chance + active_armored_chance:
			make_armored = true

		if make_explosive or make_armored or make_shield:
			special_bricks_created += 1

	brick.explosive = make_explosive
	brick.is_shield_brick = make_shield
	brick.set_grid_cell(row_id, column_id)


	# --------------------------------------------------
	# NORMAL Mİ, HAREKETLİ Mİ?
	# --------------------------------------------------

	# --------------------------------------------------
	# POZİSYON
	# --------------------------------------------------

	brick.position = pos

	brick.scale = brick_scale


	# --------------------------------------------------
	# RENK
	# --------------------------------------------------

	brick.get_node(
		"ColorRect"
	).color = color


	# --------------------------------------------------
	# SAHNEYE EKLE
	# --------------------------------------------------

	parent.add_child(
		brick
	)


	# --------------------------------------------------
	# ZIRH
	# --------------------------------------------------

	if make_armored:

		if brick.has_method("set_health"):

			brick.set_health(
				2
			)


	# --------------------------------------------------
	# TUĞLA SAYISI
	# --------------------------------------------------

	brick_count += 1
	return brick
