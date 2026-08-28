extends Node

const FIRE_INTERVAL := 1.2
const LEVEL_ANGLES_DEGREES := {
	1: [-14.0, 0.0, 14.0],
	2: [-24.0, -12.0, 0.0, 12.0, 24.0],
	3: [-24.0, -12.0, 0.0, 12.0, 24.0],
}
const SCATTER_PROJECTILE_SCENE: PackedScene = preload("res://scatter_projectile.tscn")

var game: Node
var paddle: Node2D
var cooldown_left := 0.0


func configure(game_node: Node, paddle_node: Node2D) -> void:
	game = game_node
	paddle = paddle_node


func _process(delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(paddle):
		return
	var scatter_level := GameManager.get_weapon_level(GameManager.WEAPON_SCATTER_CANNON)
	if scatter_level <= 0:
		cooldown_left = 0.0
		return
	if game.get("game_over") == true or game.get("choosing_card") == true:
		return
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	if cooldown_left > 0.0:
		return
	cooldown_left = FIRE_INTERVAL
	_fire(scatter_level)


func _fire(level: int) -> void:
	var safe_level := clampi(level, 1, 3)
	var angles: Array = LEVEL_ANGLES_DEGREES[safe_level]
	var split_enabled := safe_level >= 3
	for angle_degrees: float in angles:
		var projectile := SCATTER_PROJECTILE_SCENE.instantiate()
		game.add_child(projectile)
		projectile.global_position = paddle.global_position + Vector2.UP * 22.0
		projectile.configure_scatter(Vector2.UP.rotated(deg_to_rad(angle_degrees)), split_enabled, false)
	if OS.is_debug_build():
		print("SCATTER LV%d FIRE: %d%s" % [safe_level, angles.size(), " | SPLIT" if split_enabled else ""])