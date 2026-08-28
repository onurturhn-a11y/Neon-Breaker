extends StaticBody2D


var is_destroyed = false


@onready var hit_sound = $HitSound
@onready var color_rect = $ColorRect
@onready var collision_shape = $CollisionShape2D


func hit(_source = "ball"):

	# --------------------------------------------------
	# ZATEN KIRILDIYSA TEKRAR ÇALIŞMASIN
	# --------------------------------------------------

	if is_destroyed:
		return


	is_destroyed = true


	# --------------------------------------------------
	# TUĞLANIN RENGİNİ SAKLA
	# --------------------------------------------------

	var brick_color = color_rect.color


	# --------------------------------------------------
	# AYNI FRAME'DE TEKRAR ÇARPILMASINI ENGELLE
	# --------------------------------------------------

	collision_shape.set_deferred(
		"disabled",
		true
	)


	# --------------------------------------------------
	# TUĞLAYI GÖRÜNMEZ YAP
	# --------------------------------------------------

	color_rect.visible = false


	# --------------------------------------------------
	# SES
	# --------------------------------------------------

	hit_sound.play()


	# --------------------------------------------------
	# ÇARPMA FLAŞI
	# --------------------------------------------------

	create_hit_flash(
		brick_color
	)


	# --------------------------------------------------
	# PARÇALANMA EFEKTİ
	# --------------------------------------------------

	create_explosion(
		brick_color
	)


	# --------------------------------------------------
	# MAIN'E SADECE BİR KEZ HABER VER
	# --------------------------------------------------

	get_parent().brick_destroyed(global_position, brick_color, "ball", null, get_instance_id())


	# --------------------------------------------------
	# SESİN KESİLMEMESİ İÇİN BEKLE
	# --------------------------------------------------

	await get_tree().create_timer(
		0.2
	).timeout


	queue_free()


# ==================================================
# ÇARPMA FLAŞI
# ==================================================

func create_hit_flash(brick_color):

	var flash = Polygon2D.new()


	flash.polygon = PackedVector2Array([
		Vector2(-12, -12),
		Vector2(12, -12),
		Vector2(12, 12),
		Vector2(-12, 12)
	])


	# Beyaz enerji flaşı
	flash.color = Color(
		1.0,
		1.0,
		1.0,
		0.9
	)


	flash.z_index = 25


	get_parent().add_child(
		flash
	)


	flash.global_position = (
		global_position
	)


	# --------------------------------------------------
	# FLAŞ ANİMASYONU
	# --------------------------------------------------

	var tween = flash.create_tween()

	tween.set_parallel(true)


	# Hızlı büyüme
	tween.tween_property(
		flash,
		"scale",
		Vector2(
			1.8,
			1.8
		),
		0.12
	)


	# Hızlı kaybolma
	tween.tween_property(
		flash,
		"modulate:a",
		0.0,
		0.12
	)


	tween.chain().tween_callback(
		flash.queue_free
	)


# ==================================================
# TUĞLA PARÇALANMA EFEKTİ
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


		# --------------------------------------------------
		# RASTGELE SAÇILMA YÖNÜ
		# --------------------------------------------------

		var direction = Vector2(
			randf_range(
				-150,
				150
			),
			randf_range(
				-150,
				150
			)
		)


		var tween = piece.create_tween()

		tween.set_parallel(true)


		# Parçayı dışarı fırlat
		tween.tween_property(
			piece,
			"global_position",
			piece.global_position
			+ direction,
			0.45
		)


		# Parçayı küçült
		tween.tween_property(
			piece,
			"scale",
			Vector2(
				0.2,
				0.2
			),
			0.45
		)


		# Saydamlaştır
		tween.tween_property(
			piece,
			"modulate:a",
			0.0,
			0.45
		)


		tween.chain().tween_callback(
			piece.queue_free
		)
