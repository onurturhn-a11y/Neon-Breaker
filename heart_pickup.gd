extends Area2D


@export var fall_speed = 165.0

const COLLECT_FLIGHT_DURATION = 0.20

var collected = false
var pulse_time = 0.0
var paddle: Node2D
var magnet_motion = CollectibleMagnetMotion.new()


func _ready():
	if OS.has_feature("mobile"):
		scale *= 1.25

	add_to_group("collectible")
	body_entered.connect(_on_body_entered)
	paddle = get_tree().get_first_node_in_group("game_paddle") as Node2D


func _process(delta):

	if collected:
		return

	pulse_time += delta
	var pulse = (sin(pulse_time * TAU / 1.0) + 1.0) * 0.5
	$Visual.scale = Vector2.ONE * (
		lerpf(0.93, 1.07, pulse) if OS.has_feature("mobile")
		else lerpf(0.95, 1.05, pulse)
	)
	$Visual/Glow.modulate.a = (
		lerpf(0.36, 0.58, pulse) if OS.has_feature("mobile")
		else lerpf(0.22, 0.38, pulse)
	)

	if GameManager.magnet_time_remaining > 0.0:
		magnet_motion.move_collectible(self, paddle, fall_speed, delta)
	else:
		magnet_motion.reset()
		global_position.y += fall_speed * delta
	if global_position.y > GameManager.get_gameplay_bottom(get_viewport_rect().size) + 30.0:
		queue_free()


func _on_body_entered(body):

	if collected or not body.is_in_group("game_paddle"):
		return

	# Tam candayken: Teknoloji Merkezi Lv2+ varsa Heart PARCA'ya donusur.
	# Karari main.collect_heart veriyor; burada erken elenirse o kod hic
	# calismiyordu (Faz 7.3'te bulundu).
	if (
		GameManager.lives >= GameManager.MAX_LIVES
		and GameManager.get_colony_full_life_heart_salvage() <= 0
	):
		queue_free()
		return

	collected = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	var game = get_parent()
	if game.has_method("spawn_mobile_pickup_burst"):
		game.spawn_mobile_pickup_burst(global_position, Color(1.0, 0.18, 0.42, 1.0))
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(
		self,
		"global_position",
		game.get_lives_hud_target_position(),
		COLLECT_FLIGHT_DURATION
	)
	tween.tween_property(self, "scale", Vector2(0.35, 0.35), COLLECT_FLIGHT_DURATION)
	tween.tween_property(self, "modulate", Color(1.25, 1.12, 1.18, 1.0), COLLECT_FLIGHT_DURATION)

	await tween.finished
	game.collect_heart()
	queue_free()
