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


func spawn_lightning_visual(from_position, to_position, rank_index):

	var visual = LIGHTNING_VISUAL.instantiate()
	get_parent().add_child(visual)
	visual.setup(from_position, to_position, rank_index)
