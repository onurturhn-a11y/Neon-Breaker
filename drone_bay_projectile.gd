extends Area2D

const TARGETING := preload("res://weapon_targeting.gd")
const OVERLOAD_RADIUS := 46.0
const OVERLOAD_MAX_EXTRA_TARGETS := 1
const MAX_LIFETIME := 2.4
var game: Node
var target_ref: WeakRef
var speed := 540.0
var overload := false
var lifetime := 0.0
var resolved := false

func _ready() -> void:
	add_to_group("drone_bay_projectile")
	body_entered.connect(_on_body_entered)
	queue_redraw()

func configure_projectile(game_node: Node, target: Node2D, projectile_speed: float, is_overload: bool) -> void:
	game = game_node
	target_ref = weakref(target) if is_instance_valid(target) else null
	speed = projectile_speed
	overload = is_overload
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(game) or game.get("game_over") == true or GameManager.get_weapon_level(GameManager.WEAPON_DRONE_BAY) <= 0:
		queue_free()
		return
	if game.get("choosing_card") == true:
		return
	lifetime += delta
	if lifetime >= MAX_LIFETIME:
		queue_free()
		return
	var target := _get_target()
	if target == null:
		queue_free()
		return
	var direction := global_position.direction_to(target.global_position)
	if direction == Vector2.ZERO:
		_resolve_impact(target)
		return
	global_position += direction * speed * delta
	rotation = direction.angle() + PI * 0.5

func _get_target() -> Node2D:
	if target_ref == null:
		return null
	var target := target_ref.get_ref() as Node2D
	return target if TARGETING.is_valid_brick(target) else null

func _on_body_entered(body: Node) -> void:
	if resolved or not TARGETING.is_valid_brick(body):
		return
	_resolve_impact(body as Node2D)

func _resolve_impact(target: Node2D) -> void:
	if resolved or not TARGETING.is_valid_brick(target):
		return
	resolved = true
	var impact_position := target.global_position
	target.hit("drone_bay")
	if overload:
		_apply_overload(impact_position, target)
	queue_free()

func _apply_overload(origin: Vector2, primary: Node2D) -> void:
	var candidates := TARGETING.get_active_bricks(get_tree(), [primary])
	candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position))
	var extra_hits := 0
	for brick in candidates:
		if origin.distance_to(brick.global_position) > OVERLOAD_RADIUS:
			break
		if not TARGETING.is_valid_brick(brick):
			continue
		brick.hit("drone_overload")
		extra_hits += 1
		if extra_hits >= OVERLOAD_MAX_EXTRA_TARGETS:
			break

func _draw() -> void:
	var color := Color(1.0, 0.82, 0.28, 1.0) if overload else Color(0.40, 0.92, 1.0, 1.0)
	draw_line(Vector2(0, 7), Vector2(0, -7), Color(color.r, color.g, color.b, 0.48), 2.0, true)
	draw_circle(Vector2(0, -4), 2.8 if overload else 2.1, color)
