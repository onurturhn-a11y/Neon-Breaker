extends Area2D

@export_range(320.0, 380.0, 5.0) var projectile_speed: float = 350.0

var direction := Vector2.DOWN
var game: Node
var consumed := false

# Varsayilan THE CORE turuncusu. Bosslar apply_palette ile kendi
# renklerini verebilir; vermezlerse eski davranis aynen korunur.
var impact_paddle_color := Color(1.0, 0.30, 0.08, 1.0)
var impact_ball_color := Color(1.0, 0.60, 0.16, 1.0)
var impact_spark_color := Color(1.0, 0.82, 0.44, 1.0)
var suppress_impact_vfx := false


func apply_palette(texture: Texture2D, paddle_color: Color, ball_color: Color, spark_color: Color) -> void:
	if texture != null:
		$ProjectileTexture.texture = texture
	impact_paddle_color = paddle_color
	impact_ball_color = ball_color
	impact_spark_color = spark_color


func _ready() -> void:
	if OS.has_feature("mobile"):
		$OuterGlow.scale *= 1.12
		$Bolt.scale *= 1.12
		$Core.scale *= 1.12
		$OuterGlow.self_modulate = Color(1.12, 1.08, 1.04, 1.0)
		$Bolt.self_modulate = Color(1.10, 1.08, 1.04, 1.0)
	add_to_group("boss_projectile")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func setup(game_node: Node, travel_direction: Vector2, speed_override: float = -1.0, heavy_visual: bool = false, lightweight_impact: bool = false) -> void:
	game = game_node
	suppress_impact_vfx = lightweight_impact
	direction = travel_direction.normalized()
	if speed_override > 0.0:
		projectile_speed = speed_override
	if heavy_visual:
		$OuterGlow.scale *= 1.45
		$Bolt.scale *= 1.28
		$Core.scale *= 1.22
		$OuterGlow.self_modulate = Color(1.35, 0.62, 0.22, 1.0)
		$Bolt.self_modulate = Color(1.25, 0.72, 0.30, 1.0)
	rotation = direction.angle()


func _process(delta: float) -> void:
	global_position += direction * projectile_speed * delta
	var viewport_size: Vector2 = get_viewport_rect().size
	if (
		global_position.x < -60.0
		or global_position.x > viewport_size.x + 60.0
		or global_position.y < GameManager.PLAYFIELD_TOP - 60.0
		or global_position.y > viewport_size.y + 60.0
	):
		queue_free()


func _on_body_entered(body: Node) -> void:
	if consumed:
		return
	if body.is_in_group("game_paddle"):
		consumed = true
		_spawn_impact(impact_paddle_color)
		if is_instance_valid(game) and game.has_method("apply_enemy_projectile_damage"):
			game.apply_enemy_projectile_damage()
		queue_free()
	elif body.is_in_group("game_ball"):
		consumed = true
		_spawn_impact(impact_ball_color)
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if consumed or not area.is_in_group("plasma_projectile"):
		return
	consumed = true
	_spawn_impact(Color(0.62, 0.94, 1.0, 1.0))
	area.queue_free()
	queue_free()


func _spawn_impact(base_color: Color) -> void:
	if suppress_impact_vfx:
		return
	var scene := get_tree().current_scene
	if not is_instance_valid(scene):
		return
	var effect := Node2D.new()
	effect.add_to_group("boss_projectile_impact_vfx")
	if OS.has_feature("mobile"):
		effect.scale = Vector2.ONE * 1.20
	effect.global_position = global_position
	effect.z_index = 45
	scene.add_child(effect)
	for spark_index: int in range(5):
		var spark := Polygon2D.new()
		spark.polygon = PackedVector2Array([
			Vector2(-1.0, -0.6), Vector2(2.8, 0.0), Vector2(-1.0, 0.6)
		])
		spark.color = base_color if spark_index % 2 == 0 else impact_spark_color
		effect.add_child(spark)
		var angle := randf_range(0.0, TAU)
		spark.rotation = angle
		var tween := spark.create_tween().set_parallel(true)
		tween.tween_property(spark, "position", Vector2.from_angle(angle) * randf_range(9.0, 18.0), 0.16)
		tween.tween_property(spark, "scale", Vector2(0.12, 0.12), 0.16)
		tween.tween_property(spark, "modulate:a", 0.0, 0.16)
	get_tree().create_timer(0.18).timeout.connect(effect.queue_free)
