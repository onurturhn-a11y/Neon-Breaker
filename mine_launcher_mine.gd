extends Area2D

const TRAVEL_SPEED := 420.0
const ARMING_DELAY := 0.30
const BODY_RADIUS := 12.0
const SOURCE_ID: StringName = &"mine_launcher"

enum State { TRAVEL, ARMING, ARMED, DETONATING, RETIRED }

var game: Node
var weapon_level := 1
var target_position := Vector2.ZERO
var detection_radius := 58.0
var explosion_radius := 82.0
var chain_enabled := false
var state := State.TRAVEL
var arming_left := ARMING_DELAY
var pulse_time := 0.0
var explosion_scale := 0.0
var explosion_alpha := 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("mine_launcher_mine")
	monitoring = false
	body_entered.connect(_on_body_entered)
	queue_redraw()


func configure_mine(game_node: Node, level: int, target: Vector2, config: Dictionary) -> void:
	game = game_node
	weapon_level = clampi(level, 1, 3)
	target_position = target
	detection_radius = float(config.get("detection_radius", 58.0))
	explosion_radius = float(config.get("explosion_radius", 82.0))
	chain_enabled = bool(config.get("chain", false))
	var circle := collision_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = detection_radius


func _physics_process(delta: float) -> void:
	if state == State.RETIRED or state == State.DETONATING:
		return
	pulse_time += delta
	rotation += delta * 0.34
	queue_redraw()
	match state:
		State.TRAVEL:
			global_position = global_position.move_toward(target_position, TRAVEL_SPEED * delta)
			if global_position.distance_squared_to(target_position) <= 0.25:
				global_position = target_position
				state = State.ARMING
				arming_left = ARMING_DELAY
		State.ARMING:
			arming_left = maxf(arming_left - delta, 0.0)
			if arming_left <= 0.0:
				state = State.ARMED
				monitoring = true
				call_deferred("_check_initial_overlap")


func _draw() -> void:
	if state == State.DETONATING:
		var blast_color := Color(0.25, 0.95, 1.0, explosion_alpha * 0.24)
		draw_circle(Vector2.ZERO, explosion_radius * explosion_scale, blast_color)
		draw_arc(Vector2.ZERO, explosion_radius * explosion_scale, 0.0, TAU, 40, Color(1.0, 0.78, 0.20, explosion_alpha), 3.0)
		return
	var pulse := 0.5 + 0.5 * sin(pulse_time * (7.0 if state == State.ARMED else 3.5))
	var glow := Color(0.16, 0.95, 1.0, 0.30 + pulse * 0.25) if state == State.ARMED else Color(1.0, 0.70, 0.18, 0.45)
	draw_circle(Vector2.ZERO, BODY_RADIUS + 4.0 + pulse * 1.5, Color(glow.r, glow.g, glow.b, glow.a * 0.25))
	draw_circle(Vector2.ZERO, BODY_RADIUS, Color(0.025, 0.08, 0.12, 0.98))
	draw_arc(Vector2.ZERO, BODY_RADIUS - 1.0, 0.0, TAU, 24, glow, 2.5)
	for spoke in range(4):
		var angle := float(spoke) * TAU / 4.0
		draw_line(Vector2.from_angle(angle) * 4.0, Vector2.from_angle(angle) * 10.0, glow, 2.0)
	draw_circle(Vector2.ZERO, 3.5 + pulse * 0.7, Color(0.90, 1.0, 1.0, 0.85))


func _check_initial_overlap() -> void:
	if state != State.ARMED:
		return
	for body in get_overlapping_bodies():
		if _is_valid_brick(body):
			_explode()
			return


func _on_body_entered(body: Node) -> void:
	if state == State.ARMED and _is_valid_brick(body):
		_explode()


func _is_valid_brick(node: Node) -> bool:
	return (
		is_instance_valid(node)
		and not node.is_queued_for_deletion()
		and node.is_in_group("game_brick")
		and node.get("is_destroyed") != true
		and node.has_method("hit")
	)


func _explode(chain_state: Variant = null) -> void:
	if state != State.ARMED:
		return
	var is_chain_root := chain_state == null
	var shared_state: Dictionary = {"count": 0} if is_chain_root else chain_state as Dictionary
	state = State.DETONATING
	monitoring = false
	shared_state["count"] = int(shared_state.get("count", 0)) + 1
	var hit_count := _damage_bricks_in_radius()
	if OS.is_debug_build():
		print("MINE EXPLODE | HIT %d" % hit_count)
	if chain_enabled:
		_trigger_nearby_mines(shared_state)
	if is_chain_root and int(shared_state["count"]) > 1 and OS.is_debug_build():
		print("MINE LV3 CHAIN | %d MINES" % int(shared_state["count"]))
	_play_explosion_and_free()


func detonate_from_chain(chain_state: Dictionary) -> void:
	if state == State.ARMED:
		_explode(chain_state)


func _damage_bricks_in_radius() -> int:
	var circle := CircleShape2D.new()
	circle.radius = explosion_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var results := get_world_2d().direct_space_state.intersect_shape(query, 128)
	var hit_ids: Dictionary = {}
	var hit_count := 0
	for result: Dictionary in results:
		var brick := result.get("collider") as Node
		if not _is_valid_brick(brick):
			continue
		var instance_id := brick.get_instance_id()
		if hit_ids.has(instance_id):
			continue
		hit_ids[instance_id] = true
		brick.call("hit", SOURCE_ID)
		hit_count += 1
	return hit_count


func _trigger_nearby_mines(chain_state: Dictionary) -> void:
	for node in get_tree().get_nodes_in_group("mine_launcher_mine"):
		if node == self or not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		if not node.has_method("is_armed_mine") or not bool(node.call("is_armed_mine")):
			continue
		if global_position.distance_to((node as Node2D).global_position) <= explosion_radius:
			node.call("detonate_from_chain", chain_state)


func is_armed_mine() -> bool:
	return state == State.ARMED


func _play_explosion_and_free() -> void:
	explosion_scale = 0.10
	explosion_alpha = 1.0
	queue_redraw()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "explosion_scale", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "explosion_alpha", 0.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)


func retire() -> void:
	if state == State.RETIRED:
		return
	state = State.RETIRED
	monitoring = false
	queue_free()
