extends Area2D

@export var fall_speed := 155.0

var pickup_type: StringName = &"wide_paddle"
var collected := false
var pulse_time := 0.0
var paddle: Node2D
var magnet_motion = CollectibleMagnetMotion.new()


func configure(type: StringName) -> void:
	pickup_type = type
	queue_redraw()


func _ready() -> void:
	if OS.has_feature("mobile"):
		scale *= 1.25
	add_to_group("collectible")
	body_entered.connect(_on_body_entered)
	paddle = get_tree().get_first_node_in_group("game_paddle") as Node2D
	queue_redraw()


func _process(delta: float) -> void:
	if collected:
		return
	pulse_time += delta
	var pulse := (sin(pulse_time * 5.0) + 1.0) * 0.5
	modulate.a = lerpf(0.82, 1.0, pulse)
	if GameManager.magnet_time_remaining > 0.0:
		magnet_motion.move_collectible(self, paddle, fall_speed, delta)
	else:
		magnet_motion.reset()
		global_position.y += fall_speed * delta
	if global_position.y > GameManager.get_gameplay_bottom(get_viewport_rect().size) + 32.0:
		queue_free()


func _draw() -> void:
	var color := Color(0.32, 0.94, 1.0, 1.0) if pickup_type == &"wide_paddle" else Color(0.78, 0.48, 1.0, 1.0)
	draw_circle(Vector2.ZERO, 15.0, Color(color.r, color.g, color.b, 0.20))
	draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 28, color, 2.0, true)
	if pickup_type == &"wide_paddle":
		draw_rect(Rect2(-10.0, -3.0, 20.0, 6.0), color, true)
		draw_line(Vector2(-13.0, 0.0), Vector2(-8.0, 0.0), color, 2.0, true)
		draw_line(Vector2(8.0, 0.0), Vector2(13.0, 0.0), color, 2.0, true)
	else:
		draw_circle(Vector2(-4.0, 0.0), 4.5, color)
		draw_circle(Vector2(5.0, 0.0), 4.5, Color(0.90, 0.82, 1.0, 1.0))


func _on_body_entered(body: Node) -> void:
	if collected or not body.is_in_group("game_paddle"):
		return
	collected = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var game := get_parent()
	if pickup_type == &"wide_paddle" and game.has_method("activate_wide_paddle_pickup"):
		game.activate_wide_paddle_pickup()
	elif pickup_type == &"extra_ball" and game.has_method("activate_extra_ball_pickup"):
		game.activate_extra_ball_pickup()
	if game.has_method("spawn_mobile_pickup_burst"):
		var burst_color := Color(0.32, 0.94, 1.0, 1.0) if pickup_type == &"wide_paddle" else Color(0.78, 0.48, 1.0, 1.0)
		game.spawn_mobile_pickup_burst(global_position, burst_color)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", scale * 1.30, 0.10)
	tween.tween_property(self, "modulate:a", 0.0, 0.10)
	await tween.finished
	queue_free()
