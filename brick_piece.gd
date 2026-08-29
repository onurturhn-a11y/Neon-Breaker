extends StaticBody2D


var is_destroyed = false

var health = 1
var max_health = 1

var armored = false
@export var explosive = false
@export var is_shield_brick = false

# ELIT TUGLA: yuksek can + kehribar cerceve + degerli dusurme.
# Oran level_generator tarafindan derinlige gore rulet edilir (elite_bricks.gd).
var is_elite = false
var elite_panel: Panel
var elite_pulse_tween: Tween

var grid_row = -1
var grid_column = -1
var shield_sources: Array[Node] = []
var shield_controller: Node2D

var armor_panel: Panel


@onready var hit_sound = $HitSound
@onready var color_rect = $ColorRect
@onready var collision_shape = $CollisionShape2D
@onready var brick_visual = $BrickVisual


func _ready():

	add_to_group("game_brick")
	if OS.has_feature("mobile"):
		brick_visual.modulate = Color(1.10, 1.10, 1.10, 1.0)
	create_armor_border()
	brick_visual.configure(color_rect.color, health, max_health)
	brick_visual.set_explosive(explosive)
	if explosive:
		add_to_group("explosive_brick")
	if is_shield_brick:
		shield_controller = preload("res://shield_brick.gd").new()
		shield_controller.name = "ShieldController"
		add_child(shield_controller)
		add_to_group("shield_brick")



func set_grid_cell(row_id: int, column_id: int) -> void:
	grid_row = row_id
	grid_column = column_id


func setup_shield_neighbors(left_brick: Node, right_brick: Node) -> void:
	if is_instance_valid(shield_controller):
		shield_controller.setup_neighbors(left_brick, right_brick)


func set_shield_source(source: Node, enabled: bool) -> void:
	if is_shield_brick:
		return
	if enabled:
		if is_instance_valid(source) and not shield_sources.has(source):
			shield_sources.append(source)
	else:
		shield_sources.erase(source)


func is_shielded() -> bool:
	for source_index in range(shield_sources.size() - 1, -1, -1):
		if not is_instance_valid(shield_sources[source_index]):
			shield_sources.remove_at(source_index)
	return not shield_sources.is_empty()


func play_shield_block_feedback() -> void:
	for source in shield_sources:
		if is_instance_valid(source) and source.has_method("play_block_feedback"):
			source.play_block_feedback(self)


# --------------------------------------------------
# ZIRH ÇERÇEVESİNİ OLUŞTUR
# --------------------------------------------------

func create_armor_border():

	armor_panel = Panel.new()

	add_child(armor_panel)


	# Ana tuğlayla aynı konum ve boyut
	armor_panel.position = color_rect.position
	armor_panel.size = color_rect.size


	armor_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Tuğlanın üstünde görünsün
	armor_panel.z_index = 10

	# Normal tuğlalarda görünmeyecek
	armor_panel.visible = false


	var style = StyleBoxFlat.new()


	# --------------------------------------------------
	# İÇ KISIM TAMAMEN ŞEFFAF
	# --------------------------------------------------

	style.bg_color = Color(
		0.0,
		0.0,
		0.0,
		0.0
	)


	# --------------------------------------------------
	# PARLAK METALİK ZIRH RENGİ
	# --------------------------------------------------

	style.border_color = Color(
		0.88,
		0.95,
		1.0,
		1.0
	)


	# --------------------------------------------------
	# KALIN ZIRH ÇERÇEVESİ
	# --------------------------------------------------

	style.border_width_left = 5
	style.border_width_right = 5
	style.border_width_top = 5
	style.border_width_bottom = 5


	# --------------------------------------------------
	# HAFİF YUVARLATILMIŞ KÖŞELER
	# --------------------------------------------------

	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4


	armor_panel.add_theme_stylebox_override(
		"panel",
		style
	)


# --------------------------------------------------
# ELİT TUĞLA
# --------------------------------------------------

## Üretim sırasında çağrılır — tuğla sahneye eklendikten SONRA, yani
## `_ready` çalıştıktan sonra. Bayrak, can ve görsel kurulumun tek giriş noktası.
func mark_as_elite(elite_health: int) -> void:
	if is_elite:
		return
	is_elite = true
	set_meta("is_elite_brick", true)
	set_health(elite_health)
	_setup_elite_visual()


## Kehribar çerçeve + nabız. Zırh panelinden ayrı bir Panel kullanır ki
## zırh mantığı (ilk vuruşta kaybolan çerçeve) elite'i etkilemesin.
func _setup_elite_visual() -> void:
	add_to_group("elite_brick")

	elite_panel = Panel.new()
	add_child(elite_panel)
	elite_panel.position = color_rect.position
	elite_panel.size = color_rect.size
	elite_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Zırh panelinin (z_index 10) bir üstünde dursun.
	elite_panel.z_index = 11

	var style = StyleBoxFlat.new()
	style.bg_color = Color(
		EliteBricks.ELITE_GLOW_COLOR.r,
		EliteBricks.ELITE_GLOW_COLOR.g,
		EliteBricks.ELITE_GLOW_COLOR.b,
		0.16
	)
	style.border_color = EliteBricks.ELITE_BORDER_COLOR
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	elite_panel.add_theme_stylebox_override("panel", style)

	# Zırhlı tuğlanın beyaz çerçevesi elite'in kehribarıyla yarışmasın.
	if armor_panel:
		armor_panel.visible = false

	_start_elite_pulse()


func _start_elite_pulse() -> void:
	if not is_instance_valid(elite_panel):
		return
	if is_instance_valid(elite_pulse_tween):
		elite_pulse_tween.kill()
	elite_pulse_tween = create_tween()
	elite_pulse_tween.set_loops()
	elite_pulse_tween.tween_property(
		elite_panel, "modulate:a", 0.55, EliteBricks.PULSE_PERIOD * 0.5
	).set_trans(Tween.TRANS_SINE)
	elite_pulse_tween.tween_property(
		elite_panel, "modulate:a", 1.0, EliteBricks.PULSE_PERIOD * 0.5
	).set_trans(Tween.TRANS_SINE)


## Can azaldıkça çerçeve incelir — oyuncu kaç vuruş kaldığını görsel okusun.
func _refresh_elite_damage_state() -> void:
	if not is_instance_valid(elite_panel):
		return
	var style := elite_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	var ratio: float = float(health) / float(maxi(max_health, 1))
	var width: int = maxi(1, roundi(4.0 * ratio))
	style.border_width_left = width
	style.border_width_right = width
	style.border_width_top = width
	style.border_width_bottom = width
	style.bg_color.a = 0.16 * ratio


func _stop_elite_pulse() -> void:
	if is_instance_valid(elite_pulse_tween):
		elite_pulse_tween.kill()
	if is_instance_valid(elite_panel):
		elite_panel.visible = false


# --------------------------------------------------
# TUĞLA CANINI AYARLA
# --------------------------------------------------

func set_health(value):

	health = value
	max_health = value

	brick_visual.update_health(health, max_health)


	# 2 veya daha fazla canı varsa zırhlı
	if health > 1:

		armored = true


		if armor_panel:

			armor_panel.visible = false


# --------------------------------------------------
# DARBE ALDI
# --------------------------------------------------

func hit(source = "ball", damage_context = null):

	if is_destroyed:
		return
	if not is_shield_brick and is_shielded():
		play_shield_block_feedback()
		return


	health -= 1


	# --------------------------------------------------
	# ZIRH KIRILDI AMA TUĞLA YAŞIYOR
	# --------------------------------------------------

	if health > 0:

		hit_sound.play()


		armored = false


		# Zırh çerçevesini kaldır
		if armor_panel:

			armor_panel.visible = false


		# Elit çerçevesi kırılana kadar durur; kalan cana göre incelir.
		if is_elite:
			_refresh_elite_damage_state()


		brick_visual.update_health(health, max_health)


		brick_visual.play_armor_hit_effect(color_rect.color)

		return


	# --------------------------------------------------
	# TUĞLA TAMAMEN KIRILIYOR
	# --------------------------------------------------

	is_destroyed = true

	if is_shield_brick and is_instance_valid(shield_controller):
		shield_controller.release_neighbors(true)


	var brick_color = color_rect.color


	# Aynı frame içinde tekrar vurulmasını engelle
	collision_shape.set_deferred(
		"disabled",
		true
	)


	# Tuğlayı gizle
	color_rect.visible = false


	# Zırh varsa gizle
	if armor_panel:

		armor_panel.visible = false


	# Elit nabzını durdur ve çerçeveyi kaldır.
	if is_elite:
		_stop_elite_pulse()


	await brick_visual.play_break_effect(brick_color, source)
	brick_visual.visible = false

	if explosive and get_parent().has_method("trigger_explosive_blast"):
		await get_parent().trigger_explosive_blast(
			global_position,
			self,
			damage_context,
			source == "explosion"
		)


	# Kırılma sesi


	# Main'e sadece gerçekten kırıldığında haber ver
	get_parent().brick_destroyed(
		global_position,
		brick_visual.get_display_color(),
		source,
		damage_context,
		get_instance_id()
	)


	# Sesin kesilmemesi için kısa bekle
	await get_tree().create_timer(
		0.2
	).timeout


	queue_free()


func play_fireball_splash_reaction() -> void:
	if is_destroyed or not is_instance_valid(brick_visual):
		return
	if brick_visual.has_method("play_fireball_splash_reaction"):
		brick_visual.play_fireball_splash_reaction()

func hit_from_plasma():

	hit("plasma")


# --------------------------------------------------
# ZIRH KIRILMA EFEKTİ
# --------------------------------------------------

func show_damage_effect():

	var original_scale = scale


	var tween = create_tween()


	# Darbede hızlıca küçülsün
	tween.tween_property(
		self,
		"scale",
		original_scale * 0.90,
		0.06
	)


	# Sonra eski boyutuna dönsün
	tween.tween_property(
		self,
		"scale",
		original_scale,
		0.10
	)


# --------------------------------------------------
# PATLAMA
# --------------------------------------------------

func create_explosion(brick_color):

	for i in range(25):

		var piece = Polygon2D.new()


		piece.polygon = PackedVector2Array([
			Vector2(-5, -5),
			Vector2(5, -5),
			Vector2(5, 5),
			Vector2(-5, 5)
		])


		piece.color = brick_color

		piece.z_index = 20


		get_parent().add_child(
			piece
		)


		piece.global_position = global_position


		var direction = Vector2(
			randf_range(-150, 150),
			randf_range(-150, 150)
		)


		var tween = piece.create_tween()


		tween.set_parallel(true)


		# Parçaları dışarı savur
		tween.tween_property(
			piece,
			"global_position",
			piece.global_position + direction,
			0.45
		)


		# Parçaları küçült
		tween.tween_property(
			piece,
			"scale",
			Vector2(0.2, 0.2),
			0.45
		)


		# Parçaları soldur
		tween.tween_property(
			piece,
			"modulate:a",
			0.0,
			0.45
		)


		tween.chain().tween_callback(
			piece.queue_free
		)
