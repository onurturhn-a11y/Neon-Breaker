extends Node2D


const SHIELD_ACCENT := Color(0.68, 0.42, 1.0, 0.62)
const SOURCE_TEXTURE := preload("res://assets/bricks/brick_shield.png")
const OVERLAY_TEXTURE := preload("res://assets/bricks/shield_overlay.png")
const SOURCE_SCALE := Vector2(0.0695, 0.0695)
const OVERLAY_SCALE := Vector2(0.0715, 0.0715)
const OVERLAY_ALPHA := 0.72

var protected_bricks: Array[Node] = []
var overlays: Dictionary = {}
var released = false


func _ready() -> void:
	_apply_source_texture()


func setup_neighbors(left_brick: Node, right_brick: Node) -> void:
	for neighbor in [left_brick, right_brick]:
		if not is_instance_valid(neighbor):
			continue
		if neighbor.get("is_shield_brick") == true:
			continue
		_protect_neighbor(neighbor)


func _protect_neighbor(brick: Node) -> void:
	if protected_bricks.has(brick):
		return

	protected_bricks.append(brick)
	brick.set_shield_source(self, true)

	var overlay := _create_neighbor_overlay()
	brick.add_child(overlay)
	overlays[brick.get_instance_id()] = overlay


func play_block_feedback(brick: Node) -> void:
	if not is_instance_valid(brick):
		return

	var impact_position := _random_edge_position()
	var overlay = overlays.get(brick.get_instance_id())
	if is_instance_valid(overlay):
		_flash_overlay_sprite(overlay)
		_spawn_local_ripple(overlay, impact_position)

	for spark_index in range(randi_range(3, 5)):
		var spark := Polygon2D.new()
		spark.polygon = PackedVector2Array([
			Vector2(-1.2, -0.8),
			Vector2(2.8, 0.0),
			Vector2(-1.2, 0.8),
		])
		spark.color = Color(0.68, 0.96, 1.0, 1.0)
		spark.z_index = 12
		brick.add_child(spark)
		var angle := randf_range(-PI, 0.0)
		spark.position = impact_position + Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
		spark.rotation = angle
		var spark_tween := spark.create_tween().set_parallel(true)
		spark_tween.tween_property(spark, "position", spark.position + Vector2.from_angle(angle) * randf_range(8.0, 16.0), 0.16)
		spark_tween.tween_property(spark, "scale", Vector2(0.15, 0.15), 0.16)
		spark_tween.tween_property(spark, "modulate:a", 0.0, 0.16)
		spark_tween.chain().tween_callback(spark.queue_free)


func release_neighbors(play_break_effect: bool = false) -> void:
	if released:
		return
	released = true

	for brick in protected_bricks:
		if not is_instance_valid(brick):
			continue
		brick.set_shield_source(self, false)
		var overlay = overlays.get(brick.get_instance_id())
		if is_instance_valid(overlay):
			_play_overlay_break(overlay)
			overlay.modulate.a = 1.0
			var fade: Tween = overlay.create_tween()
			fade.tween_property(overlay, "modulate:a", 0.0, 0.26)
			fade.tween_callback(overlay.queue_free)

	protected_bricks.clear()
	if play_break_effect:
		_spawn_shield_break_effect()


func _exit_tree() -> void:
	release_neighbors(false)


func _create_neighbor_overlay() -> Node2D:
	var overlay := Node2D.new()
	overlay.name = "ShieldOverlay"
	overlay.z_index = 8

	var sprite := Sprite2D.new()
	sprite.name = "ShieldOverlaySprite"
	sprite.texture = OVERLAY_TEXTURE
	sprite.scale = OVERLAY_SCALE
	sprite.modulate = Color(1.0, 1.0, 1.0, OVERLAY_ALPHA)
	sprite.z_index = 8
	overlay.add_child(sprite)
	return overlay


func _apply_source_texture() -> void:
	var source_sprite := get_parent().get_node_or_null("BrickVisual/Sprite2D") as Sprite2D
	if not is_instance_valid(source_sprite):
		return
	source_sprite.texture = SOURCE_TEXTURE
	source_sprite.scale = SOURCE_SCALE
	source_sprite.modulate = Color.WHITE
	source_sprite.self_modulate = Color.WHITE


func _flash_overlay_sprite(overlay: Node2D) -> void:
	var sprite := overlay.get_node_or_null("ShieldOverlaySprite") as Sprite2D
	if not is_instance_valid(sprite):
		return
	var active_tween = sprite.get_meta("shield_hit_tween", null)
	if active_tween is Tween and active_tween.is_valid():
		active_tween.kill()
	sprite.modulate = Color(1.28, 1.28, 1.28, 0.86)
	var tween := sprite.create_tween()
	sprite.set_meta("shield_hit_tween", tween)
	tween.tween_property(
		sprite,
		"modulate",
		Color(1.0, 1.0, 1.0, OVERLAY_ALPHA),
		0.13
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _rounded_shield_points(extents: Vector2, radius: float, corner_steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var centers = [
		Vector2(extents.x - radius, extents.y - radius),
		Vector2(-extents.x + radius, extents.y - radius),
		Vector2(-extents.x + radius, -extents.y + radius),
		Vector2(extents.x - radius, -extents.y + radius),
	]
	var start_angles = [0.0, PI / 2.0, PI, PI * 1.5]
	for corner_index in range(4):
		for step_index in range(corner_steps + 1):
			var angle = start_angles[corner_index] + (PI / 2.0) * float(step_index) / float(corner_steps)
			points.append(centers[corner_index] + Vector2.from_angle(angle) * radius)
	points.append(points[0])
	return points


func _random_edge_position() -> Vector2:
	if randf() < 0.5:
		return Vector2(randf_range(-48.0, 48.0), 20.5 if randf() < 0.5 else -20.5)
	return Vector2(54.0 if randf() < 0.5 else -54.0, randf_range(-14.0, 14.0))


func _spawn_local_ripple(overlay: Node2D, impact_position: Vector2) -> void:
	var ripple := Line2D.new()
	ripple.position = impact_position
	ripple.points = _rounded_shield_points(Vector2(5.0, 3.0), 2.0, 3)
	ripple.width = 1.35
	ripple.antialiased = true
	ripple.default_color = Color(0.78, 0.98, 1.0, 0.92)
	overlay.add_child(ripple)

	var tween := ripple.create_tween().set_parallel(true)
	tween.tween_property(ripple, "scale", Vector2(2.1, 2.1), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ripple, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(ripple.queue_free)


func _play_overlay_break(overlay: Node2D) -> void:
	var shield_points := _rounded_shield_points(Vector2(54.0, 20.5), 7.0, 4)
	for fragment_index in range(6):
		var point_index := fragment_index * 3
		var start := shield_points[point_index]
		var finish := shield_points[mini(point_index + 2, shield_points.size() - 1)]
		var fragment := Line2D.new()
		fragment.points = PackedVector2Array([start, finish])
		fragment.width = 1.6
		fragment.antialiased = true
		fragment.default_color = Color(0.68, 0.95, 1.0, 0.9)
		overlay.add_child(fragment)
		var outward := (start + finish).normalized() * randf_range(7.0, 14.0)
		var tween := fragment.create_tween().set_parallel(true)
		tween.tween_property(fragment, "position", outward, 0.24)
		tween.tween_property(fragment, "modulate:a", 0.0, 0.24)
		tween.tween_property(fragment, "scale", Vector2(0.45, 0.45), 0.24)
		tween.chain().tween_callback(fragment.queue_free)


func _spawn_shield_break_effect() -> void:
	var effect := Node2D.new()
	effect.name = "ShieldBreakEffect"
	effect.global_position = global_position
	effect.z_index = 36
	get_tree().current_scene.add_child(effect)

	var ring := Line2D.new()
	var points := PackedVector2Array()
	for point_index in range(7):
		points.append(Vector2.from_angle(TAU * point_index / 6.0) * 11.0)
	ring.points = points
	ring.width = 2.0
	ring.antialiased = true
	ring.default_color = SHIELD_ACCENT
	effect.add_child(ring)

	var tween := ring.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(2.2, 2.2), 0.22)
	tween.tween_property(ring, "modulate:a", 0.0, 0.22)
	get_tree().create_timer(0.24).timeout.connect(effect.queue_free)
