extends Area2D

@export var fall_speed := 145.0
var collected := false
var pulse_time := 0.0


func _ready() -> void:
	add_to_group("collectible")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if collected:
		return
	pulse_time += delta
	var pulse := (sin(pulse_time * 5.0) + 1.0) * 0.5
	$Visual.scale = Vector2.ONE * lerpf(0.94, 1.06, pulse)
	$Visual/Glow.modulate.a = lerpf(0.22, 0.42, pulse)
	global_position.y += fall_speed * delta
	if global_position.y > GameManager.get_gameplay_bottom(get_viewport_rect().size) + 32.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if collected or not body.is_in_group("game_paddle"):
		return
	collected = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var game := get_parent()
	if game.has_method("spawn_mobile_pickup_burst"):
		game.spawn_mobile_pickup_burst(global_position, Color(1.0, 0.78, 0.12, 1.0))
	if game.has_method("collect_coin"):
		game.collect_coin(global_position)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * 1.35, 0.10)
	tween.tween_property(self, "modulate:a", 0.0, 0.10)
	await tween.finished
	queue_free()