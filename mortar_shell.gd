extends Node2D

const SOURCE_ID: StringName = &"mortar"
const TARGETING := preload("res://weapon_targeting.gd")
const ARC_HEIGHT_MIN := 95.0
const ARC_HEIGHT_MAX := 180.0
const MARKER_SEGMENTS := 32
const IMPACT_DURATION := 0.20
const MOBILE_IMPACT_VFX_LIMIT := 2
const IMPACT_VFX_GROUP: StringName = &"mortar_impact_vfx"

enum State { TRAVEL, IMPACT, RETIRED }

var game: Node
var start_position := Vector2.ZERO
var impact_position := Vector2.ZERO
var travel_duration := 0.82
var explosion_radius := 78.0
var weapon_level := 1
var elapsed := 0.0
var impact_elapsed := 0.0
var arc_height := 120.0
var state := State.TRAVEL
var marker: Line2D
var shell_rotation := 0.0
var impact_visual_enabled := true


func configure_shell(
	game_node: Node,
	target_position: Vector2,
	duration: float,
	radius: float,
	level: int
) -> void:
	game = game_node
	start_position = global_position
	impact_position = target_position
	travel_duration = maxf(duration, 0.10)
	explosion_radius = maxf(radius, 1.0)
	weapon_level = clampi(level, 1, 3)
	arc_height = clampf(start_position.distance_to(impact_position) * 0.24, ARC_HEIGHT_MIN, ARC_HEIGHT_MAX)
	_create_marker()
	queue_redraw()


func _process(delta: float) -> void:
	if state == State.RETIRED:
		return
	if not is_instance_valid(game):
		retire()
		return
	if game.get("game_over") == true:
		retire()
		return
	if game.get("choosing_card") == true:
		return
	if state == State.TRAVEL:
		elapsed = minf(elapsed + delta, travel_duration)
		var progress := elapsed / travel_duration
		var base_position := start_position.lerp(impact_position, progress)
		global_position = base_position + Vector2.UP * sin(progress * PI) * arc_height
		shell_rotation += delta * 5.2
		rotation = shell_rotation
		_update_marker(progress)
		queue_redraw()
		if progress >= 1.0:
			global_position = impact_position
			_impact()
	else:
		impact_elapsed += delta
		queue_redraw()
		if impact_elapsed >= IMPACT_DURATION:
			retire()


func _draw() -> void:
	if state == State.TRAVEL:
		draw_circle(Vector2.ZERO, 7.0, Color(0.055, 0.08, 0.12, 1.0))
		draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 18, Color(1.0, 0.62, 0.16, 0.95), 2.2)
		draw_line(Vector2(-4.0, 0.0), Vector2(4.0, 0.0), Color(1.0, 0.84, 0.35, 0.9), 1.5)
	else:
		if not impact_visual_enabled:
			return
		var progress := clampf(impact_elapsed / IMPACT_DURATION, 0.0, 1.0)
		draw_circle(Vector2.ZERO, explosion_radius * progress, Color(1.0, 0.34, 0.08, (1.0 - progress) * 0.24))
		draw_arc(Vector2.ZERO, explosion_radius * progress, 0.0, TAU, 40, Color(1.0, 0.78, 0.28, 1.0 - progress), 3.0)


func _create_marker() -> void:
	marker = Line2D.new()
	marker.name = "ImpactMarker"
	marker.top_level = true
	add_child(marker)
	marker.global_position = impact_position
	marker.width = 1.8
	marker.default_color = Color(1.0, 0.42, 0.12, 0.62)
	marker.closed = true
	var marker_radius := explosion_radius * 0.38
	for index in range(MARKER_SEGMENTS):
		marker.add_point(Vector2.from_angle(TAU * float(index) / float(MARKER_SEGMENTS)) * marker_radius)


func _update_marker(progress: float) -> void:
	if not is_instance_valid(marker):
		return
	var pulse := 0.5 + 0.5 * sin(elapsed * 8.0)
	marker.modulate.a = 0.46 + pulse * 0.30
	marker.scale = Vector2.ONE * (0.96 + pulse * 0.06)
	marker.width = 1.5 + progress * 1.2


func _impact() -> void:
	if state != State.TRAVEL:
		return
	state = State.IMPACT
	impact_elapsed = 0.0
	if OS.has_feature("mobile"):
		impact_visual_enabled = get_tree().get_nodes_in_group(IMPACT_VFX_GROUP).size() < MOBILE_IMPACT_VFX_LIMIT
		if impact_visual_enabled:
			add_to_group(IMPACT_VFX_GROUP)
	if is_instance_valid(marker):
		marker.queue_free()
	var hit_count := _damage_bricks_once()
	if OS.is_debug_build():
		print("MORTAR IMPACT | HIT %d" % hit_count)
	queue_redraw()


func _damage_bricks_once() -> int:
	var circle := CircleShape2D.new()
	circle.radius = explosion_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, impact_position)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var results := get_world_2d().direct_space_state.intersect_shape(query, 128)
	var hit_ids: Dictionary = {}
	var hit_count := 0
	for result: Dictionary in results:
		var brick := result.get("collider") as Node
		if not TARGETING.is_valid_brick(brick):
			continue
		var instance_id := brick.get_instance_id()
		if hit_ids.has(instance_id):
			continue
		hit_ids[instance_id] = true
		brick.call("hit", SOURCE_ID)
		hit_count += 1
	return hit_count


func retire() -> void:
	if state == State.RETIRED:
		return
	state = State.RETIRED
	if is_instance_valid(marker):
		marker.queue_free()
	queue_free()