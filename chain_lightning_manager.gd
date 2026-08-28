extends Node


@export var chain_radius = 150.0

const RANK_TARGET_COUNTS = [1, 1, 2, 2, 3, 3, 4, 5, 6]
const CHARGE_THRESHOLDS = [3, 6, 9, 12, 15, 18, 21, 24, 27]
const LEGACY_CHARGE_TIMEOUT = 0.85
const DIRECT_BALL_SOURCES: Array[StringName] = [&"ball", &"piercing_ball", &"fireball_ball"]

const LIGHTNING_VISUAL = preload("res://chain_lightning_visual.tscn")
var charge_hits := 0
var charge_time_left := 0.0
var charge_rank_index := -1


func _process(delta: float) -> void:
	if charge_hits <= 0:
		return
	charge_time_left = maxf(charge_time_left - delta, 0.0)
	if charge_time_left <= 0.0:
		reset_charge()


func register_brick_kill(source: String, damage_context = null) -> void:
	# Fireball'ın eski combat-balance sınırı yalnız Chain Lightning charge'ına aittir.
	if source == "fireball" and damage_context is Dictionary:
		var event_hits := int(damage_context.get("chain_charge_fireball_hits", 0))
		if event_hits >= 3:
			return
		damage_context["chain_charge_fireball_hits"] = event_hits + 1
	charge_hits += 1
	charge_time_left = LEGACY_CHARGE_TIMEOUT
	charge_rank_index = _get_charge_rank(charge_hits)


func _get_charge_rank(hits: int) -> int:
	var result := -1
	for index in range(CHARGE_THRESHOLDS.size()):
		if hits < CHARGE_THRESHOLDS[index]:
			break
		result = index
	return result


func get_charge_rank() -> int:
	return charge_rank_index


func reset_charge() -> void:
	charge_hits = 0
	charge_time_left = 0.0
	charge_rank_index = -1


func trigger(origin_position, primary_brick, source: StringName = &"ball"):

	if source not in DIRECT_BALL_SOURCES:
		return false
	var rank_index := charge_rank_index
	if rank_index < 0:
		return false
	var max_additional_targets = RANK_TARGET_COUNTS[rank_index]

	var candidates = []
	for brick in get_tree().get_nodes_in_group("game_brick"):
		if (
			brick == primary_brick
			or not is_instance_valid(brick)
			or brick.is_destroyed
			or not brick.has_method("hit")
		):
			continue

		var distance = origin_position.distance_to(brick.global_position)
		if distance <= chain_radius:
			candidates.append({
				"brick": brick,
				"distance": distance
			})

	candidates.sort_custom(
		func(a, b): return a["distance"] < b["distance"]
	)

	var target_count = mini(max_additional_targets, candidates.size())
	if target_count <= 0:
		return false
	print("CHAIN LIGHTNING PROC | source=%s | targets=%d" % [source, target_count])
	for i in range(target_count):
		var target = candidates[i]["brick"]
		var target_position = target.global_position
		spawn_lightning_visual(origin_position, target_position, rank_index)
		target.hit("chain")

	return true


func trigger_arc(
	origin_position: Vector2,
	primary_brick: Node2D,
	max_chain_jumps: int,
	arc_radius: float,
	arc_level: int = 1,
	terminal_radius: float = 0.0,
	candidate_bricks: Array[Node2D] = []
) -> Array[Node2D]:
	var hit_bricks: Array[Node2D] = []
	if not _is_valid_arc_target(primary_brick):
		return hit_bricks
	if candidate_bricks.is_empty():
		candidate_bricks = _get_arc_candidates()
	var current_origin := origin_position
	var current_target := primary_brick
	var terminal_position := primary_brick.global_position
	for chain_index in range(max_chain_jumps + 1):
		if not _is_valid_arc_target(current_target) or current_target in hit_bricks:
			break
		var target_position := current_target.global_position
		terminal_position = target_position
		spawn_lightning_visual(current_origin, target_position, 0)
		hit_bricks.append(current_target)
		current_target.hit("arc_cannon")
		if chain_index >= max_chain_jumps:
			break
		current_origin = target_position
		current_target = _find_nearest_arc_target(
			target_position,
			hit_bricks,
			arc_radius,
			candidate_bricks
		)
		if current_target == null:
			break
	var terminal_hits := 0
	if arc_level >= 3 and terminal_radius > 0.0 and not hit_bricks.is_empty():
		terminal_hits = _apply_terminal_discharge(
			terminal_position,
			terminal_radius,
			hit_bricks,
			candidate_bricks
		)
	if OS.is_debug_build():
		var names: Array[String] = []
		for brick in hit_bricks:
			names.append(brick.name)
		var message := "ARC LV%d: %s" % [arc_level, " -> ".join(names)]
		if arc_level >= 3:
			message += " | TERMINAL: %d" % terminal_hits
		print(message)
	return hit_bricks


func _get_arc_candidates() -> Array[Node2D]:
	var candidates: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("game_brick"):
		if node is Node2D and _is_valid_arc_target(node):
			candidates.append(node as Node2D)
	return candidates


func _find_nearest_arc_target(
	origin_position: Vector2,
	excluded: Array[Node2D],
	arc_radius: float,
	candidate_bricks: Array[Node2D]
) -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	for brick in candidate_bricks:
		if brick in excluded or not _is_valid_arc_target(brick):
			continue
		var distance := origin_position.distance_to(brick.global_position)
		if distance <= arc_radius and distance < nearest_distance:
			nearest = brick
			nearest_distance = distance
	return nearest


func _apply_terminal_discharge(
	origin_position: Vector2,
	radius: float,
	chain_targets: Array[Node2D],
	candidate_bricks: Array[Node2D]
) -> int:
	spawn_terminal_discharge_visual(origin_position, radius)
	var terminal_hits := 0
	for brick in candidate_bricks:
		if brick in chain_targets or not _is_valid_arc_target(brick):
			continue
		if origin_position.distance_to(brick.global_position) > radius:
			continue
		brick.hit("arc_cannon_terminal")
		terminal_hits += 1
	return terminal_hits


func _is_valid_arc_target(brick: Node) -> bool:
	return (
		is_instance_valid(brick)
		and not bool(brick.get("is_destroyed"))
		and brick.has_method("hit")
	)


func spawn_terminal_discharge_visual(world_position: Vector2, radius: float) -> void:
	var visual := Node2D.new()
	visual.set_script(load("res://arc_terminal_discharge_visual.gd"))
	get_parent().add_child(visual)
	visual.setup(world_position, radius)

func spawn_lightning_visual(from_position, to_position, rank_index):

	var visual = LIGHTNING_VISUAL.instantiate()
	get_parent().add_child(visual)
	visual.setup(from_position, to_position, rank_index)
