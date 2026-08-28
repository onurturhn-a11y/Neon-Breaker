extends Node2D


signal finished

@export_range(320.0, 520.0, 5.0) var projectile_speed = 365.0
@export_range(0.25, 0.40, 0.01) var entry_duration = 0.32
@export_range(0.40, 0.80, 0.05) var hold_duration = 0.55
@export_range(0.25, 0.35, 0.01) var telegraph_duration = 0.30
@export_range(0.20, 0.40, 0.01) var exit_delay = 0.30
@export_range(540.0, 720.0, 10.0) var barrel_rotate_speed_degrees = 630.0
@export_range(4.0, 8.0, 0.5) var recoil_distance = 6.0

const PROJECTILE_SCENE = preload("res://enemy_projectile.tscn")
const LEFT_TEXTURE = preload("res://assets/bricks/enemies/side_attacker/side_attacker_left.png")
const RIGHT_TEXTURE = preload("res://assets/bricks/enemies/side_attacker/side_attacker_right.png")
const LEFT_REGION := Rect2(0.0, 32.0, 295.0, 333.0)
const RIGHT_REGION := Rect2(0.0, 32.0, 300.0, 333.0)

var game: Node
var side = -1
var outside_position := Vector2.ZERO
var inside_position := Vector2.ZERO
var tracking_target := false
@onready var attacker_sprite: Sprite2D = $AttackerSprite
@onready var barrel_pivot: Node2D = $BarrelPivot
@onready var barrel_visual: Node2D = $BarrelPivot/BarrelVisual
@onready var barrel_core: Polygon2D = $BarrelPivot/BarrelVisual/BarrelCore


func _process(delta: float) -> void:
	if not tracking_target:
		return
	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		return
	var target_angle: float = (paddle.global_position - barrel_pivot.global_position).angle()
	var max_rotation_step: float = deg_to_rad(barrel_rotate_speed_degrees) * delta
	var rotation_delta: float = angle_difference(barrel_pivot.global_rotation, target_angle)
	barrel_pivot.global_rotation += clampf(rotation_delta, -max_rotation_step, max_rotation_step)


func setup(game_node: Node, spawn_side: int, speed_override = -1.0) -> void:
	game = game_node
	side = spawn_side
	if speed_override > 0.0:
		projectile_speed = speed_override
	var viewport_size: Vector2 = game.get_viewport_rect().size
	var safe_rect := GameManager.get_gameplay_rect(viewport_size)
	var spawn_y: float = randf_range(
		GameManager.PLAYFIELD_TOP + 45.0,
		minf(GameManager.PLAYFIELD_TOP + 285.0, safe_rect.position.y + safe_rect.size.y - 300.0)
	) if OS.has_feature("mobile") else randf_range(190.0, 430.0)
	var safe_right := safe_rect.position.x + safe_rect.size.x
	outside_position = Vector2(safe_rect.position.x - 55.0, spawn_y) if side < 0 else Vector2(safe_right + 55.0, spawn_y)
	inside_position = Vector2(safe_rect.position.x + 42.0, spawn_y) if side < 0 else Vector2(safe_right - 42.0, spawn_y)
	global_position = outside_position
	var atlas := AtlasTexture.new()
	atlas.atlas = LEFT_TEXTURE if side < 0 else RIGHT_TEXTURE
	atlas.region = LEFT_REGION if side < 0 else RIGHT_REGION
	attacker_sprite.texture = atlas
	barrel_pivot.rotation = 0.0 if side < 0 else PI
	call_deferred("_run_attack_sequence")


func _run_attack_sequence() -> void:
	var entry := create_tween()
	entry.tween_property(self, "global_position", inside_position, entry_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await entry.finished
	await get_tree().create_timer(hold_duration).timeout

	var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
	if not is_instance_valid(paddle):
		await _exit_attacker()
		return
	tracking_target = true
	# Visual-only telegraph: the barrel keeps tracking while its own core charges.
	var charge := create_tween().set_parallel(true)
	charge.tween_property(barrel_core, "modulate", Color(1.35, 1.12, 0.78, 1.0), telegraph_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	charge.tween_property(barrel_core, "scale", Vector2(1.45, 1.45), telegraph_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await charge.finished

	var target_snapshot: Vector2 = paddle.global_position
	tracking_target = false
	_fire_projectile((target_snapshot - global_position).normalized())
	_play_barrel_recoil()
	barrel_core.modulate = Color.WHITE
	barrel_core.scale = Vector2.ONE
	await get_tree().create_timer(exit_delay).timeout
	await _exit_attacker()


func _play_barrel_recoil() -> void:
	var recoil := barrel_visual.create_tween()
	recoil.tween_property(barrel_visual, "position:x", -recoil_distance, 0.045).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	recoil.tween_property(barrel_visual, "position:x", 0.0, 0.085).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _fire_projectile(fire_direction: Vector2) -> void:
	var projectile: Node2D = PROJECTILE_SCENE.instantiate()
	game.add_child(projectile)
	projectile.global_position = global_position + fire_direction * 24.0
	projectile.setup(game, fire_direction, projectile_speed)


func _exit_attacker() -> void:
	var exit_tween := create_tween()
	exit_tween.tween_property(self, "global_position", outside_position, entry_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await exit_tween.finished
	finished.emit()
	queue_free()
