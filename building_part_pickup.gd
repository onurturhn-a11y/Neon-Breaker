extends Area2D

@export var fall_speed := 170.0
@export var visual_rotation_speed_degrees := 55.0
var collected := false
var pulse_time := 0.0


func _ready() -> void:
	add_to_group("collectible")
	add_to_group("building_part_pickup")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if collected:
		return
	pulse_time += delta
	var pulse := (sin(pulse_time * 4.5) + 1.0) * 0.5
	$Visual.scale = Vector2.ONE * lerpf(0.96, 1.04, pulse)
	$Visual.rotation += deg_to_rad(visual_rotation_speed_degrees) * delta
	global_position.y += fall_speed * delta
	if global_position.y > GameManager.get_gameplay_bottom(get_viewport_rect().size) + 40.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if collected or not body.is_in_group("game_paddle"):
		return
	collected = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var game := get_parent()
	if game.has_method("spawn_mobile_pickup_burst"):
		game.spawn_mobile_pickup_burst(global_position, Color(0.30, 0.95, 1.0, 1.0))
	if game.has_method("collect_building_part"):
		game.collect_building_part(global_position)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * 1.35, 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	await tween.finished
	queue_free()