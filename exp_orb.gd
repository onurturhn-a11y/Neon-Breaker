extends Area2D

@export var fall_speed := 170.0
@export var exp_value := 10
@export var magnet_radius := 120.0
@export var shell_rotation_period := 5.0
@export var glow_rotation_period := 7.0
@export var glow_pulse_period := 1.4
@export var core_pulse_period := 1.0

const VISUAL_SCALE := 0.021
const COLLECT_DURATION := 0.18

var collected := false
var animation_time := 0.0
var paddle: Node2D
var magnet_motion := CollectibleMagnetMotion.new()


func _ready() -> void:
	add_to_group("collectible")
	add_to_group("exp_orb_pickup")
	body_entered.connect(_on_body_entered)
	paddle = get_tree().get_first_node_in_group("game_paddle") as Node2D


func _process(delta: float) -> void:
	if collected:
		return
	animation_time += delta
	$Shell.rotation += TAU * delta / shell_rotation_period
	$Glow.rotation -= TAU * delta / glow_rotation_period

	var glow_phase := (sin(TAU * animation_time / glow_pulse_period) + 1.0) * 0.5
	$Glow.modulate.a = lerpf(0.55, 0.90, glow_phase)

	var core_phase := (sin(TAU * animation_time / core_pulse_period) + 1.0) * 0.5
	var core_scale := VISUAL_SCALE * lerpf(0.94, 1.04, core_phase)
	$Core.scale = Vector2.ONE * core_scale
	var core_brightness := lerpf(0.94, 1.08, core_phase)
	$Core.self_modulate = Color(core_brightness, core_brightness, core_brightness, 1.0)

	if GameManager.magnet_time_remaining > 0.0:
		magnet_motion.move_collectible(self, paddle, fall_speed, delta)
	else:
		magnet_motion.reset()
		global_position.y += fall_speed * delta

	if global_position.y > GameManager.get_gameplay_bottom(get_viewport_rect().size) + 36.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if collected or not body.is_in_group("game_paddle"):
		return
	collected = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	var game := get_parent()
	if game.has_method("spawn_mobile_pickup_burst"):
		game.spawn_mobile_pickup_burst(global_position, Color(0.20, 0.94, 1.0, 1.0))
	if game.has_method("show_xp_pickup_feedback"):
		game.show_xp_pickup_feedback(exp_value, global_position)
	if game.has_method("add_xp"):
		game.add_xp(exp_value)
	print("EXP ORB COLLECTED - +%d EXP - TOTAL: %d" % [exp_value, GameManager.current_xp])
	XPOrbAudio.play_collect()

	var collect_tween := create_tween().set_parallel(true)
	collect_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	collect_tween.tween_property($Core, "self_modulate", Color(1.55, 1.55, 1.55, 1.0), COLLECT_DURATION * 0.55)
	collect_tween.tween_property($Core, "scale", Vector2.ONE * VISUAL_SCALE * 1.18, COLLECT_DURATION)
	collect_tween.tween_property($Glow, "scale", Vector2.ONE * VISUAL_SCALE * 1.35, COLLECT_DURATION)
	collect_tween.tween_property($Shell, "scale", Vector2.ONE * VISUAL_SCALE * 0.78, COLLECT_DURATION)
	collect_tween.tween_property(self, "modulate:a", 0.0, COLLECT_DURATION)
	await collect_tween.finished
	queue_free()
