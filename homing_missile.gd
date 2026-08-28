extends Area2D

const TARGETING := preload("res://weapon_targeting.gd")
const MICRO_BLAST_VISUAL := preload("res://homing_micro_blast_visual.gd")
const SPEED := 430.0
const MICRO_BLAST_RADIUS := 62.0
const MICRO_BLAST_MAX_EXTRA_TARGETS := 2
var game: Node
var target_ref: WeakRef
var direction := Vector2.UP
var turn_speed_radians := deg_to_rad(220.0)
var micro_blast_enabled := false
var retarget_used := false
var impact_resolved := false

func _ready() -> void:
	add_to_group("homing_missile")
	body_entered.connect(_on_body_entered)

func configure(game_node: Node, target: Node2D, turn_speed: float, micro_blast: bool) -> void:
	game = game_node
	target_ref = weakref(target) if is_instance_valid(target) else null
	turn_speed_radians = turn_speed
	micro_blast_enabled = micro_blast
	direction = Vector2.UP
	rotation = 0.0

func _physics_process(delta: float) -> void:
	var target := _get_valid_target()
	if target == null and not retarget_used:
		retarget_used = true
		target = _retarget_once()
	if target != null:
		var desired := global_position.direction_to(target.global_position)
		if desired != Vector2.ZERO:
			var step := clampf(direction.angle_to(desired), -turn_speed_radians * delta, turn_speed_radians * delta)
			direction = direction.rotated(step).normalized()
	global_position += direction * SPEED * delta
	rotation = direction.angle() + PI * 0.5
	_cleanup_outside_playfield()

func _get_valid_target() -> Node2D:
	if target_ref == null: return null
	var target := target_ref.get_ref() as Node2D
	return target if TARGETING.is_valid_brick(target) else null

func _retarget_once() -> Node2D:
	if not is_instance_valid(game): return null
	var paddle := game.get_tree().get_first_node_in_group("game_paddle") as Node2D
	var reference := paddle.global_position if is_instance_valid(paddle) else global_position
	var targets := TARGETING.select_danger_targets(game.get_tree(), reference, 1)
	if targets.is_empty():
		target_ref = null
		return null
	target_ref = weakref(targets[0])
	return targets[0]

func _on_body_entered(body: Node) -> void:
	if impact_resolved or is_queued_for_deletion(): return
	if body.is_in_group("game_wall"): return
	if body.is_in_group("game_boss") and body.has_method("hit_from_plasma"):
		impact_resolved = true
		body.hit_from_plasma(get_instance_id())
		queue_free()
		return
	if not TARGETING.is_valid_brick(body): return
	impact_resolved = true
	var hit_brick := body as Node2D
	var impact_position: Vector2 = hit_brick.global_position
	hit_brick.hit("homing_missile")
	if micro_blast_enabled: _apply_micro_blast(impact_position, hit_brick)
	queue_free()

func _apply_micro_blast(origin: Vector2, main_target: Node2D) -> int:
	_spawn_micro_blast_visual(origin)
	var candidates := TARGETING.get_active_bricks(get_tree(), [main_target])
	candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool: return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position))
	var extra_hits := 0
	for brick in candidates:
		if origin.distance_to(brick.global_position) > MICRO_BLAST_RADIUS: break
		if not TARGETING.is_valid_brick(brick): continue
		brick.hit("homing_micro_blast")
		extra_hits += 1
		if extra_hits >= MICRO_BLAST_MAX_EXTRA_TARGETS: break
	return extra_hits

func _spawn_micro_blast_visual(origin: Vector2) -> void:
	if not is_instance_valid(game): return
	var visual := Node2D.new()
	visual.set_script(MICRO_BLAST_VISUAL)
	game.add_child(visual)
	visual.setup(origin, MICRO_BLAST_RADIUS)

func _cleanup_outside_playfield() -> void:
	if not GameManager.get_gameplay_rect(get_viewport_rect().size).grow(90.0).has_point(global_position): queue_free()
