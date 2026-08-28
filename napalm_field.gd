extends Node2D

@export var duration: float = 2.5
@export var radius: float = 87.5
@export var tick_interval: float = 0.5

var _elapsed: float = 0.0
var _field_visual: Node2D


func _ready() -> void:
	z_index = 31
	_create_visual()
	_run_field()


func setup(field_radius: float, field_duration: float = 2.5, interval: float = 0.5) -> void:
	radius = field_radius
	duration = field_duration
	tick_interval = interval


func _run_field() -> void:
	while _elapsed + tick_interval <= duration + 0.001:
		await get_tree().create_timer(tick_interval).timeout
		_elapsed += tick_interval
		_apply_damage_tick()

	var fade := create_tween().set_parallel(true)
	fade.tween_property(_field_visual, "modulate:a", 0.0, 0.18)
	fade.tween_property(_field_visual, "scale", Vector2(1.04, 1.04), 0.18)
	await fade.finished
	queue_free()


func _apply_damage_tick() -> void:
	var damaged_this_tick: Dictionary = {}
	var context := {
		"damaged": damaged_this_tick,
		"detonated": {},
		"combo_hits": 0,
		"fireball_combo_hits": 0,
	}
	for brick: Node in get_tree().get_nodes_in_group("game_brick"):
		if not is_instance_valid(brick) or brick.get("is_destroyed") == true:
			continue
		if brick.global_position.distance_to(global_position) > radius:
			continue
		var brick_id: int = brick.get_instance_id()
		if damaged_this_tick.has(brick_id):
			continue
		damaged_this_tick[brick_id] = true
		if brick.has_method("hit"):
			brick.hit("napalm", context)


func _create_visual() -> void:
	_field_visual = Node2D.new()
	_field_visual.name = "NapalmVisual"
	_field_visual.modulate.a = 0.0
	add_child(_field_visual)

	var fill := Polygon2D.new()
	fill.name = "HeatField"
	fill.polygon = _circle_points(radius, 36)
	fill.color = Color(1.0, 0.19, 0.025, 0.075)
	_field_visual.add_child(fill)

	var inner_fill := Polygon2D.new()
	inner_fill.name = "HotCore"
	inner_fill.polygon = _circle_points(radius * 0.62, 32)
	inner_fill.color = Color(1.0, 0.48, 0.06, 0.065)
	_field_visual.add_child(inner_fill)

	var edge := Line2D.new()
	edge.name = "HeatEdge"
	edge.points = _circle_points(radius, 36, true)
	edge.width = 1.4
	edge.default_color = Color(1.0, 0.42, 0.08, 0.34)
	edge.antialiased = true
	_field_visual.add_child(edge)

	for ember_index: int in range(9):
		var ember := Polygon2D.new()
		ember.polygon = PackedVector2Array([
			Vector2(-1.0, -0.7), Vector2(2.6, 0.0), Vector2(-1.0, 0.7)
		])
		ember.color = Color(1.0, 0.66, 0.18, 0.52)
		var angle: float = TAU * float(ember_index) / 9.0 + randf_range(-0.18, 0.18)
		ember.position = Vector2.from_angle(angle) * randf_range(radius * 0.52, radius * 0.92)
		ember.rotation = angle - PI * 0.5
		_field_visual.add_child(ember)
		var ember_tween := ember.create_tween().set_loops()
		ember_tween.tween_property(ember, "modulate:a", 0.18, randf_range(0.35, 0.55))
		ember_tween.tween_property(ember, "modulate:a", 0.62, randf_range(0.45, 0.70))

	var appear := _field_visual.create_tween().set_parallel(true)
	appear.tween_property(_field_visual, "modulate:a", 1.0, 0.16)
	appear.tween_property(_field_visual, "scale", Vector2(1.025, 1.025), duration)


func _circle_points(circle_radius: float, segments: int, close_loop: bool = false) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in range(segments):
		points.append(Vector2.from_angle(TAU * float(index) / float(segments)) * circle_radius)
	if close_loop:
		points.append(points[0])
	return points
