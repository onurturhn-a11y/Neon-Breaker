extends Area2D


@export var fall_speed = 190.0
@export var xp_value = 10
@export var magnet_radius = 120.0

const COLLECT_FLIGHT_DURATION = 0.22
const TRAIL_INTERVAL = 0.04

var collected = false
var paddle: Node2D
var trail_time = 0.0
var boost_magnet_motion = CollectibleMagnetMotion.new()


func _ready():
	if OS.has_feature("mobile"):
		scale *= 1.25
		$Glow.color = Color(0.10, 0.88, 1.0, 0.43)
		$Orb.color = Color(0.20, 0.96, 1.0, 1.0)
	add_to_group("collectible")
	body_entered.connect(_on_body_entered)
	paddle = get_tree().get_first_node_in_group("game_paddle") as Node2D


func _process(delta):
	if collected:
		trail_time -= delta
		if trail_time <= 0.0:
			trail_time = TRAIL_INTERVAL
			spawn_flight_trail()
		return

	if GameManager.magnet_time_remaining > 0.0:
		boost_magnet_motion.move_collectible(self, paddle, fall_speed, delta)
		if global_position.y > GameManager.get_gameplay_bottom(get_viewport_rect().size) + 30.0:
			queue_free()
		return

	boost_magnet_motion.reset()

	var movement = Vector2.DOWN * fall_speed

	if is_instance_valid(paddle):
		var to_paddle = paddle.global_position - global_position
		var distance = to_paddle.length()
		if distance < magnet_radius and distance > 0.01:
			var proximity = 1.0 - distance / magnet_radius
			var magnet_motion = to_paddle.normalized() * fall_speed * 1.25
			movement = movement.lerp(magnet_motion, proximity * 0.62)

	global_position += movement * delta

	if global_position.y > GameManager.get_gameplay_bottom(get_viewport_rect().size) + 30.0:
		queue_free()


func _on_body_entered(body):
	if collected or not body.is_in_group("game_paddle"):
		return

	collected = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	var game = get_parent()
	if game.has_method("spawn_mobile_pickup_burst"):
		game.spawn_mobile_pickup_burst(global_position, Color(0.20, 0.94, 1.0, 1.0))
	game.show_xp_pickup_feedback(xp_value, global_position)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(
		self,
		"global_position",
		game.get_xp_bar_target_position(),
		COLLECT_FLIGHT_DURATION
	)
	tween.tween_property(self, "scale", Vector2(0.35, 0.35), COLLECT_FLIGHT_DURATION)
	tween.tween_property(self, "modulate", Color(1.18, 1.25, 1.25, 1.0), COLLECT_FLIGHT_DURATION)

	await tween.finished
	game.add_xp(xp_value)
	XPOrbAudio.play_collect()
	queue_free()


func spawn_flight_trail():
	var trail = Polygon2D.new()
	trail.polygon = PackedVector2Array([
		Vector2(0, -3),
		Vector2(3, 0),
		Vector2(0, 3),
		Vector2(-3, 0)
	])
	trail.color = Color(0.40, 0.95, 1.0, 0.62 if OS.has_feature("mobile") else 0.5)
	trail.z_index = 19
	trail.process_mode = Node.PROCESS_MODE_ALWAYS

	get_parent().add_child(trail)
	trail.global_position = global_position

	var tween = trail.create_tween()
	tween.set_parallel(true)
	tween.tween_property(trail, "scale", Vector2(0.26, 0.26) if OS.has_feature("mobile") else Vector2(0.2, 0.2), 0.10)
	tween.tween_property(trail, "modulate:a", 0.0, 0.10)
	tween.chain().tween_callback(trail.queue_free)
