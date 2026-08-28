extends "res://plasma_bullet.gd"

const SHARD_ANGLE_DEGREES := 20.0
const SCATTER_COLOR := Color(0.38, 0.82, 1.0, 1.0)
const SCATTER_CORE_COLOR := Color(0.78, 0.46, 1.0, 1.0)

var can_split := false
var split_spawned := false
var is_shard := false


func _ready() -> void:
	add_to_group("scatter_projectile")
	body_entered.connect(_on_body_entered)
	_apply_scatter_visual()


func configure_scatter(shot_direction: Vector2, split_allowed: bool, shard: bool) -> void:
	direction = shot_direction.normalized()
	can_split = split_allowed and not shard
	is_shard = shard
	speed = 780.0 if shard else 820.0
	if is_node_ready():
		_apply_scatter_visual()


func _apply_scatter_visual() -> void:
	var tint := SCATTER_CORE_COLOR if is_shard else SCATTER_COLOR
	sprite.scale = Vector2.ONE * (0.052 if is_shard else 0.070)
	sprite.self_modulate = tint
	trail.width = 1.0 if is_shard else 1.35
	trail.default_color = Color(tint.r, tint.g, tint.b, 0.58)
	trail.modulate.a = 0.70


func _on_body_entered(body: Node) -> void:
	if is_queued_for_deletion():
		return
	if body.is_in_group("game_wall"):
		queue_free()
		return
	if body.is_in_group("game_boss") and body.has_method("hit_from_plasma"):
		if body.has_method("hit_from_plasma_at"):
			body.hit_from_plasma_at(get_instance_id(), global_position)
		else:
			body.hit_from_plasma(get_instance_id())
		create_impact(false)
		queue_free()
		return
	if not body.has_method("hit"):
		return
	body.hit("scatter_shard" if is_shard else "scatter_cannon")
	if can_split and not split_spawned:
		split_spawned = true
		_spawn_shards()
	create_impact(body.get("is_destroyed") == true)
	queue_free()


func _spawn_shards() -> void:
	var projectile_scene := load("res://scatter_projectile.tscn") as PackedScene
	for angle_sign in [-1.0, 1.0]:
		var shard := projectile_scene.instantiate()
		get_parent().add_child(shard)
		shard.global_position = global_position + direction * 8.0
		shard.configure_scatter(
			direction.rotated(deg_to_rad(SHARD_ANGLE_DEGREES * angle_sign)),
			false,
			true
		)