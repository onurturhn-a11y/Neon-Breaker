extends Area2D


@export_range(320.0, 520.0, 5.0) var projectile_speed = 365.0

const HIT_FX_TEXTURE = preload("res://assets/bricks/enemies/side_attacker/enemy_hit_fx.png")
const ASSET_MASK_SHADER = preload("res://side_attacker_asset_mask.gdshader")
const LARGE_HIT_REGION := Rect2(10.0, 25.0, 320.0, 180.0)
const SMALL_HIT_REGION := Rect2(15.0, 190.0, 125.0, 100.0)
const PROJECTILE_ART_FORWARD_ANGLE := deg_to_rad(146.0)

var direction := Vector2.LEFT
var game: Node
var consumed = false


func _ready() -> void:
	add_to_group("side_attacker_projectile")
	if OS.has_feature("mobile"):
		$ProjectileSprite.scale *= 1.12
		$ProjectileSprite.self_modulate = Color(1.12, 1.10, 1.06, 1.0)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func setup(game_node: Node, travel_direction: Vector2, speed_override = -1.0) -> void:
	game = game_node
	direction = travel_direction.normalized()
	if speed_override > 0.0:
		projectile_speed = speed_override
	# The V2 artwork's nose naturally points down-left at approximately 146 degrees.
	rotation = direction.angle() - PROJECTILE_ART_FORWARD_ANGLE


func _process(delta: float) -> void:
	global_position += direction * projectile_speed * delta
	var viewport_size: Vector2 = get_viewport_rect().size
	if (
		global_position.x < -80.0
		or global_position.x > viewport_size.x + 80.0
		or global_position.y < GameManager.PLAYFIELD_TOP - 80.0
		or global_position.y > viewport_size.y + 80.0
	):
		queue_free()


func _on_body_entered(body: Node) -> void:
	if consumed:
		return
	if body.is_in_group("game_paddle"):
		consumed = true
		_spawn_impact(Color(1.0, 0.35, 0.08, 1.0), true)
		if is_instance_valid(game) and game.has_method("apply_enemy_projectile_damage"):
			game.apply_enemy_projectile_damage()
		queue_free()
	elif body.is_in_group("game_ball"):
		consumed = true
		_spawn_impact(Color(0.65, 0.96, 1.0, 1.0))
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if consumed or not area.is_in_group("plasma_projectile"):
		return
	consumed = true
	_spawn_impact(Color(0.72, 0.9, 1.0, 1.0))
	area.queue_free()
	queue_free()


func _spawn_impact(base_color: Color, small := false) -> void:
	var effect := Node2D.new()
	if OS.has_feature("mobile"):
		effect.scale = Vector2.ONE * 1.20
	effect.global_position = global_position
	effect.z_index = 45
	get_tree().current_scene.add_child(effect)
	var atlas := AtlasTexture.new()
	atlas.atlas = HIT_FX_TEXTURE
	atlas.region = SMALL_HIT_REGION if small else LARGE_HIT_REGION
	var impact_sprite := Sprite2D.new()
	impact_sprite.texture = atlas
	impact_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var mask_material := ShaderMaterial.new()
	mask_material.shader = ASSET_MASK_SHADER
	impact_sprite.material = mask_material
	var target_scale := Vector2(0.18, 0.18) if small else Vector2(0.16, 0.16)
	impact_sprite.scale = target_scale * 0.55
	impact_sprite.modulate = Color(1.0, 1.0, 1.0, 0.9 if small else 1.0)
	effect.add_child(impact_sprite)
	var impact_tween := impact_sprite.create_tween().set_parallel(true)
	impact_tween.tween_property(impact_sprite, "scale", target_scale, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	impact_tween.tween_property(impact_sprite, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for spark_index in range(5):
		var spark := Polygon2D.new()
		spark.polygon = PackedVector2Array([
			Vector2(-1.0, -0.5), Vector2(2.5, 0.0), Vector2(-1.0, 0.5)
		])
		spark.color = base_color if spark_index % 2 == 0 else Color(1.0, 0.58, 0.12, 1.0)
		effect.add_child(spark)
		var angle := randf_range(0.0, TAU)
		spark.rotation = angle
		var tween := spark.create_tween().set_parallel(true)
		tween.tween_property(spark, "position", Vector2.from_angle(angle) * randf_range(9.0, 18.0), 0.16)
		tween.tween_property(spark, "scale", Vector2(0.12, 0.12), 0.16)
		tween.tween_property(spark, "modulate:a", 0.0, 0.16)
	get_tree().create_timer(0.18).timeout.connect(effect.queue_free)
