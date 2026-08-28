extends Area2D

@export var fall_speed := 170.0
@export var exp_value := 10
@export var magnet_radius := 120.0
@export var shell_rotation_period := 5.0
@export var glow_rotation_period := 7.0
@export var glow_pulse_period := 1.4
@export var core_pulse_period := 1.0

# Sadece mobilde orbun tamamını biraz büyütür.
@export_range(1.0, 1.4, 0.01) var mobile_scale_multiplier := 1.15

const VISUAL_SCALE := 0.021

# XP barına uçuş süresi.
const COLLECT_FLIGHT_DURATION := 0.22

# Uçuş sırasında arkada bırakılan enerji izi sıklığı.
const TRAIL_INTERVAL := 0.04

var collected := false
var animation_time := 0.0
var trail_time := 0.0

var paddle: Node2D
var magnet_motion := CollectibleMagnetMotion.new()

var base_root_scale := Vector2.ONE


func _ready() -> void:
	add_to_group("collectible")
	add_to_group("exp_orb_pickup")

	body_entered.connect(_on_body_entered)

	paddle = (
		get_tree()
		.get_first_node_in_group("game_paddle")
		as Node2D
	)

	# Desktop boyutuna dokunma.
	# Android/mobile tarafında %15 daha büyük.
	if OS.has_feature("mobile"):
		scale *= mobile_scale_multiplier

	# Collect animasyonunda mevcut scale'i referans almak için sakla.
	base_root_scale = scale


func _process(delta: float) -> void:
	# --------------------------------------------------
	# XP BARINA UÇUŞ
	# --------------------------------------------------

	if collected:
		trail_time -= delta

		if trail_time <= 0.0:
			trail_time = TRAIL_INTERVAL
			spawn_flight_trail()

		return

	# --------------------------------------------------
	# IDLE ANİMASYONLARI
	# --------------------------------------------------

	animation_time += delta

	# Shell saat yönünde yavaşça döner.
	$Shell.rotation += (
		TAU
		* delta
		/ shell_rotation_period
	)

	# Glow ters yönde döner.
	$Glow.rotation -= (
		TAU
		* delta
		/ glow_rotation_period
	)

	# --------------------------------------------------
	# GLOW PULSE
	# --------------------------------------------------

	var glow_phase := (
		sin(
			TAU
			* animation_time
			/ glow_pulse_period
		)
		+ 1.0
	) * 0.5

	$Glow.modulate.a = lerpf(
		0.55,
		0.90,
		glow_phase
	)

	# --------------------------------------------------
	# CORE PULSE
	# --------------------------------------------------

	var core_phase := (
		sin(
			TAU
			* animation_time
			/ core_pulse_period
		)
		+ 1.0
	) * 0.5

	var core_scale := (
		VISUAL_SCALE
		* lerpf(
			0.94,
			1.04,
			core_phase
		)
	)

	$Core.scale = (
		Vector2.ONE
		* core_scale
	)

	var core_brightness := lerpf(
		0.94,
		1.08,
		core_phase
	)

	$Core.self_modulate = Color(
		core_brightness,
		core_brightness,
		core_brightness,
		1.0
	)

	# --------------------------------------------------
	# MAGNET
	# --------------------------------------------------

	if GameManager.magnet_time_remaining > 0.0:
		magnet_motion.move_collectible(
			self,
			paddle,
			fall_speed,
			delta
		)

	else:
		magnet_motion.reset()

		global_position.y += (
			fall_speed
			* delta
		)

	# --------------------------------------------------
	# EKRANDAN ÇIKTI
	# --------------------------------------------------

	if (
		global_position.y
		> GameManager.get_gameplay_bottom(
			get_viewport_rect().size
		) + 36.0
	):
		queue_free()


func _on_body_entered(body: Node) -> void:
	if collected:
		return

	if not body.is_in_group("game_paddle"):
		return

	collected = true

	# Artık ikinci kez toplanamaz.
	set_deferred(
		"monitoring",
		false
	)

	set_deferred(
		"monitorable",
		false
	)

	magnet_motion.reset()

	var game := get_parent()

	# --------------------------------------------------
	# PADDLE COLLECT BURST
	# --------------------------------------------------

	if game.has_method(
		"spawn_mobile_pickup_burst"
	):
		game.spawn_mobile_pickup_burst(
			global_position,
			Color(
				0.20,
				0.94,
				1.0,
				1.0
			)
		)

	# --------------------------------------------------
	# +10 XP FEEDBACK
	# --------------------------------------------------

	if game.has_method(
		"show_xp_pickup_feedback"
	):
		game.show_xp_pickup_feedback(
			exp_value,
			global_position
		)

	# --------------------------------------------------
	# XP BAR HEDEFİ
	# --------------------------------------------------

	var target_position := global_position

	if game.has_method(
		"get_xp_bar_target_position"
	):
		target_position = (
			game.get_xp_bar_target_position()
		)

	# İlk trail hemen oluşsun.
	trail_time = 0.0

	# --------------------------------------------------
	# XP BARINA UÇUŞ
	# --------------------------------------------------

	var flight_tween := create_tween()

	flight_tween.set_parallel(true)

	flight_tween.set_trans(
		Tween.TRANS_QUAD
	)

	flight_tween.set_ease(
		Tween.EASE_IN
	)

	# Orb XP barına gider.
	flight_tween.tween_property(
		self,
		"global_position",
		target_position,
		COLLECT_FLIGHT_DURATION
	)

	# Uçarken küçülür.
	flight_tween.tween_property(
		self,
		"scale",
		base_root_scale * 0.35,
		COLLECT_FLIGHT_DURATION
	)

	# Hafif enerji patlaması/parlaklık.
	flight_tween.tween_property(
		self,
		"modulate",
		Color(
			1.18,
			1.25,
			1.25,
			1.0
		),
		COLLECT_FLIGHT_DURATION
	)

	# Core biraz daha parlaklaşsın.
	flight_tween.tween_property(
		$Core,
		"self_modulate",
		Color(
			1.55,
			1.55,
			1.55,
			1.0
		),
		COLLECT_FLIGHT_DURATION
	)

	# Glow uçuş sırasında biraz açılır.
	flight_tween.tween_property(
		$Glow,
		"modulate:a",
		1.0,
		COLLECT_FLIGHT_DURATION
	)

	await flight_tween.finished

	# --------------------------------------------------
	# XP BARA ULAŞTI
	# --------------------------------------------------

	# XP ancak orb bara ulaştığında eklenir.
	if game.has_method("add_xp"):
		game.add_xp(exp_value)

	print(
		"EXP ORB COLLECTED - +%d EXP - TOTAL: %d"
		% [
			exp_value,
			GameManager.current_xp
		]
	)

	XPOrbAudio.play_collect()

	queue_free()


func spawn_flight_trail() -> void:
	var trail := Polygon2D.new()

	trail.polygon = PackedVector2Array([
		Vector2(0, -3),
		Vector2(3, 0),
		Vector2(0, 3),
		Vector2(-3, 0)
	])

	trail.color = Color(
		0.40,
		0.95,
		1.0,
		0.62 if OS.has_feature("mobile") else 0.50
	)

	trail.z_index = 19

	# Oyun kısa süreli pause durumuna girerse
	# trail tween'i yarıda kalmasın.
	trail.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	get_parent().add_child(trail)

	trail.global_position = (
		global_position
	)

	var trail_tween := (
		trail.create_tween()
	)

	trail_tween.set_parallel(true)

	var target_scale := (
		Vector2(0.26, 0.26)
		if OS.has_feature("mobile")
		else Vector2(0.20, 0.20)
	)

	trail_tween.tween_property(
		trail,
		"scale",
		target_scale,
		0.10
	)

	trail_tween.tween_property(
		trail,
		"modulate:a",
		0.0,
		0.10
	)

	trail_tween.chain().tween_callback(
		trail.queue_free
	)
