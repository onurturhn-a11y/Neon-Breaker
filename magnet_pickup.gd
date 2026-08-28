extends Area2D


@export var fall_speed = 165.0
@export var magnet_duration = 10.0

var collected = false
var pulse_time = 0.0
var paddle: Node2D
var magnet_motion = CollectibleMagnetMotion.new()


func _ready():
	if OS.has_feature("mobile"):
		scale *= 1.25

	add_to_group("collectible")
	body_entered.connect(_on_body_entered)
	paddle = get_tree().get_first_node_in_group("game_paddle") as Node2D


func _process(delta):

	if collected:
		return

	pulse_time += delta
	var pulse = (sin(pulse_time * TAU / 0.9) + 1.0) * 0.5
	$Visual.scale = Vector2.ONE * (
		lerpf(0.93, 1.07, pulse) if OS.has_feature("mobile")
		else lerpf(0.95, 1.05, pulse)
	)
	$Visual/Glow.modulate.a = (
		lerpf(0.31, 0.53, pulse) if OS.has_feature("mobile")
		else lerpf(0.18, 0.34, pulse)
	)
	if GameManager.magnet_time_remaining > 0.0:
		magnet_motion.move_collectible(self, paddle, fall_speed, delta)
	else:
		magnet_motion.reset()
		global_position.y += fall_speed * delta

	if global_position.y > GameManager.get_gameplay_bottom(get_viewport_rect().size) + 30.0:
		queue_free()


func _on_body_entered(body):

	if collected or not body.is_in_group("game_paddle"):
		return

	collected = true
	set_deferred("monitoring", false)
	if get_parent().has_method("spawn_mobile_pickup_burst"):
		get_parent().spawn_mobile_pickup_burst(global_position, Color(0.46, 0.38, 1.0, 1.0))
	get_parent().activate_magnet(magnet_duration)
	queue_free()
