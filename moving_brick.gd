extends AnimatableBody2D


# ==================================================
# HAREKET AYARLARI
# ==================================================

@export var move_speed = 45.0
@export var move_distance = 42.0
@export var grid_spacing_x = 74.0

var start_x = 0.0
var move_direction = 1.0


# ==================================================
# TUĞLA SİSTEMİ
# ==================================================

var is_destroyed = false

var health = 1
var max_health = 1

var armored = false

var armor_panel: Panel


@onready var hit_sound = get_node_or_null("HitSound")
@onready var color_rect = $ColorRect
@onready var collision_shape = $CollisionShape2D
@onready var brick_visual = $BrickVisual


# ==================================================
# BAŞLANGIÇ
# ==================================================

func _ready():

	add_to_group("game_brick")
	start_x = position.x

	# Her hareketli tuğla biraz farklı hareket etsin
	move_speed = randf_range(
		35.0,
		55.0
	)

	var desired_distance = randf_range(
		35.0,
		50.0
	)

	var half_width = (
		color_rect.size.x
		* abs(global_scale.x)
		* 0.5
	)

	var screen_width = get_viewport_rect().size.x

	var safe_distance = min(
		start_x - half_width,
		screen_width - half_width - start_x
	)

	# Yoğun grid'de iki komşu moving brick birbirine doğru hareket etse
	# bile collision genişlikleri üst üste binmesin.
	var collision_width = (
		collision_shape.shape.size.x
		* abs(global_scale.x)
	)
	var neighbor_safe_distance = max(
		(grid_spacing_x - collision_width) * 0.5 - 0.5,
		0.0
	)

	move_distance = min(
		desired_distance,
		max(safe_distance, 0.0),
		neighbor_safe_distance
	)

	create_armor_border()
	brick_visual.configure(color_rect.color, health, max_health)


	# Eğer generator zırhı _ready'den önce verdiyse
	if health > 1:

		armored = true

		armor_panel.visible = false


# ==================================================
# HAREKET
# ==================================================

func _physics_process(delta):

	position.x += (
		move_speed
		* move_direction
		* delta
	)


	# Sağa ulaştı
	if position.x >= start_x + move_distance:

		position.x = (
			start_x + move_distance
		)

		move_direction = -1.0


	# Sola ulaştı
	elif position.x <= start_x - move_distance:

		position.x = (
			start_x - move_distance
		)

		move_direction = 1.0


# ==================================================
# ZIRH ÇERÇEVESİ
# ==================================================

func create_armor_border():

	armor_panel = Panel.new()

	add_child(
		armor_panel
	)


	armor_panel.position = (
		color_rect.position
	)

	armor_panel.size = (
		color_rect.size
	)


	armor_panel.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	armor_panel.z_index = 10

	armor_panel.visible = false


	var style = StyleBoxFlat.new()


	# İç taraf tamamen şeffaf
	style.bg_color = Color(
		0.0,
		0.0,
		0.0,
		0.0
	)


	# Metalik beyaz zırh
	style.border_color = Color(
		0.88,
		0.95,
		1.0,
		1.0
	)


	# Kalın çerçeve
	style.border_width_left = 5
	style.border_width_right = 5
	style.border_width_top = 5
	style.border_width_bottom = 5


	# Hafif yuvarlak köşeler
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4


	armor_panel.add_theme_stylebox_override(
		"panel",
		style
	)


# ==================================================
# CAN AYARLA
# ==================================================

func set_health(value):

	health = value
	max_health = value

	brick_visual.update_health(health, max_health)


	if health > 1:

		armored = true

		if armor_panel:

			armor_panel.visible = false

	else:

		armored = false

		if armor_panel:

			armor_panel.visible = false

# ==================================================
# DARBE ALDI
# ==================================================

func hit(source = "ball"):

	if is_destroyed:
		return


	health -= 1


	# ==================================================
	# ZIRH KIRILDI AMA TUĞLA YAŞIYOR
	# ==================================================

	if health > 0:

		hit_sound.play()

		armored = false


		if armor_panel:

			armor_panel.visible = false


		brick_visual.update_health(health, max_health)


		brick_visual.play_armor_hit_effect(color_rect.color)

		return


	# ==================================================
	# TUĞLA TAMAMEN KIRILIYOR
	# ==================================================

	is_destroyed = true
	BrickBreakAudio.play_break()


	var brick_color = color_rect.color


	# Çarpışmayı kapat
	collision_shape.set_deferred(
		"disabled",
		true
	)


	# Tuğlayı gizle
	color_rect.visible = false


	# Zırhı gizle
	if armor_panel:

		armor_panel.visible = false


	await brick_visual.play_break_effect(brick_color, source)
	brick_visual.visible = false


	# Kırılma sesi


	# Ana oyuna haber ver
	get_parent().brick_destroyed(
		global_position,
		brick_visual.get_display_color(),
		source,
		null,
		get_instance_id()
	)


	# Sesin kesilmemesi için kısa bekle
	await get_tree().create_timer(
		0.2
	).timeout


	queue_free()


func hit_from_plasma():

	hit("plasma")


# ==================================================
# SES
# ==================================================

# ==================================================
# ZIRH KIRILMA EFEKTİ
# ==================================================

func show_damage_effect():

	var original_scale = scale


	var tween = create_tween()


	# Darbede küçül
	tween.tween_property(
		self,
		"scale",
		original_scale * 0.90,
		0.06
	)


	# Eski haline dön
	tween.tween_property(
		self,
		"scale",
		original_scale,
		0.10
	)


# ==================================================
# PATLAMA
# ==================================================

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


		piece.global_position = (
			global_position
		)


		var direction = Vector2(
			randf_range(-150, 150),
			randf_range(-150, 150)
		)


		var tween = piece.create_tween()

		tween.set_parallel(true)


		# Dışarı saç
		tween.tween_property(
			piece,
			"global_position",
			piece.global_position + direction,
			0.45
		)


		# Küçül
		tween.tween_property(
			piece,
			"scale",
			Vector2(
				0.2,
				0.2
			),
			0.45
		)


		# Saydamlaş
		tween.tween_property(
			piece,
			"modulate:a",
			0.0,
			0.45
		)


		tween.chain().tween_callback(
			piece.queue_free
		)
