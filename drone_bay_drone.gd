extends Node2D

const PROJECTILE_SCENE: PackedScene = preload("res://drone_bay_projectile.tscn")
const TARGETING := preload("res://weapon_targeting.gd")
const FOLLOW_RESPONSE := 8.5
const FORMATION_SPACING := 48.0
const FORMATION_HEIGHT := 34.0
var game: Node
var paddle: Node2D
var drone_index := 0
var drone_count := 1
var weapon_level := 1
var fire_interval := 1.35
var projectile_speed := 540.0
var overload_every := 0
var fire_cooldown := 0.28
var shot_count := 0
var phase := 0.0

func _ready() -> void:
	add_to_group("drone_bay_drone")
	queue_redraw()

func configure_drone(game_node: Node, paddle_node: Node2D, index: int, count: int, level: int, config: Dictionary) -> void:
	game = game_node
	paddle = paddle_node
	drone_index = index
	drone_count = count
	weapon_level = level
	fire_interval = float(config["fire_interval"])
	projectile_speed = float(config["projectile_speed"])
	overload_every = int(config["overload_every"])
	phase = float(index) * PI + float(get_instance_id() % 17) * 0.11
	fire_cooldown = minf(fire_cooldown, 0.28 + float(index) * 0.16)
	queue_redraw()

func _process(delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(paddle):
		queue_free()
		return
	if game.get("game_over") == true:
		queue_free()
		return
	if game.get("choosing_card") == true:
		return
	phase += delta * (1.65 + float(drone_index) * 0.12)
	var side := 0.0 if drone_count == 1 else (-1.0 if drone_index == 0 else 1.0)
	var desired_position := paddle.global_position + Vector2(side * FORMATION_SPACING, -FORMATION_HEIGHT) + Vector2(sin(phase) * 8.0, cos(phase * 0.83) * 5.0)
	global_position = global_position.lerp(desired_position, 1.0 - exp(-FOLLOW_RESPONSE * delta))
	fire_cooldown = maxf(fire_cooldown - delta, 0.0)
	if fire_cooldown <= 0.0:
		_try_fire()
	queue_redraw()

func _try_fire() -> void:
	var candidates := TARGETING.select_danger_targets(get_tree(), paddle.global_position, maxi(drone_count, 1))
	if candidates.is_empty():
		fire_cooldown = 0.20
		return
	var target: Node2D = candidates[mini(drone_index, candidates.size() - 1)]
	if not TARGETING.is_valid_brick(target):
		fire_cooldown = 0.20
		return
	shot_count += 1
	var projectile := PROJECTILE_SCENE.instantiate()
	game.add_child(projectile)
	projectile.global_position = global_position + Vector2.UP * 8.0
	projectile.call("configure_projectile", game, target, projectile_speed, overload_every > 0 and shot_count % overload_every == 0)
	fire_cooldown = fire_interval

func _draw() -> void:
	var theme := Color(0.92, 0.66, 0.16, 1.0) if weapon_level < 3 else Color(1.0, 0.78, 0.24, 1.0)
	var pulse := 0.72 + sin(phase * 2.2) * 0.16
	draw_circle(Vector2.ZERO, 11.0, Color(0.05, 0.08, 0.14, 0.96))
	draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 24, theme, 2.2, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-16, 2), Vector2(-8, -4), Vector2(-8, 6)]), theme.darkened(0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(16, 2), Vector2(8, -4), Vector2(8, 6)]), theme.darkened(0.15))
	draw_circle(Vector2(0, -1), 4.2, Color(theme.r, theme.g, theme.b, pulse))
	draw_line(Vector2(-5, 7), Vector2(5, 7), theme, 1.5, true)
