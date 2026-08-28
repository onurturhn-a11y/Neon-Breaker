extends Area2D

@export var fall_speed := 170.0
var collected := false
var animation_time := 0.0

@onready var visual_root: Node2D = $VisualRoot
@onready var base: Sprite2D = $VisualRoot/Base
@onready var energy: Sprite2D = $VisualRoot/Energy
@onready var core: Sprite2D = $VisualRoot/Core

const LAYER_BASE_SCALE := Vector2(0.042, 0.042)
const BASE_ROTATION_SPEED := deg_to_rad(18.0)


func _ready() -> void:
	add_to_group("collectible")
	add_to_group("building_part_pickup")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if collected:
		return
	animation_time += delta
	visual_root.position.y = sin(animation_time * 2.1) * 0.65
	base.rotation += BASE_ROTATION_SPEED * delta

	var energy_pulse := (sin(animation_time * 3.4) + 1.0) * 0.5
	energy.scale = LAYER_BASE_SCALE * lerpf(0.985, 1.025, energy_pulse)
	energy.self_modulate = Color(1.0, 0.96, 0.72, lerpf(0.60, 1.0, energy_pulse))

	var core_pulse := (sin(animation_time * 5.1 + 0.9) + 1.0) * 0.5
	core.scale = LAYER_BASE_SCALE * lerpf(0.94, 1.06, core_pulse)
	core.self_modulate = Color(1.0, lerpf(0.88, 1.0, core_pulse), lerpf(0.58, 0.82, core_pulse), 1.0)

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
	tween.tween_property(energy, "self_modulate", Color(1.0, 0.94, 0.58, 1.0), 0.08)
	tween.tween_property(core, "scale", LAYER_BASE_SCALE * 1.16, 0.12)
	tween.tween_property(core, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE * 1.35, 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	await tween.finished
	queue_free()