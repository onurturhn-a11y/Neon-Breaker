extends Area2D

# ==================================================
# VOID KUYRUKLU YILDIZI - THE VOID ARCHITECT'in 1. saldirisi
#
# Yavas ama agir. Ilk saniyede rakete dogru HAFIF yoneliyor, sonra
# yonu kilitleniyor: kacilabilir ama yerinde durursan yakalar.
# Omru dolunca ya da rakete degince halka seklinde patliyor.
# ==================================================

@export var speed: float = 210.0
@export var homing_duration: float = 0.9
@export var homing_rate: float = 1.6
@export var lifetime: float = 4.5

var direction := Vector2.DOWN
var game: Node
var elapsed := 0.0
var consumed := false
var blob_texture: ImageTexture


func setup(game_node: Node, initial_direction: Vector2) -> void:
	game = game_node
	direction = initial_direction.normalized()


func _ready() -> void:
	add_to_group("boss_projectile")
	add_to_group("void_comet")
	z_index = 7
	collision_layer = 128
	collision_mask = 112
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 26.0
	shape.shape = circle
	add_child(shape)
	_build_visual()
	body_entered.connect(_on_body_entered)


func _make_blob() -> ImageTexture:
	if blob_texture == null:
		var image := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
		for x in range(64):
			for y in range(64):
				var d := Vector2(float(x) - 31.5, float(y) - 31.5).length() / 31.5
				var v := clampf(1.0 - d, 0.0, 1.0)
				image.set_pixel(x, y, Color(1, 1, 1, v * v * (3.0 - 2.0 * v)))
		blob_texture = ImageTexture.create_from_image(image)
	return blob_texture


func _additive() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat


func _build_visual() -> void:
	for entry in [[128.0, Color(0.16, 0.72, 0.80, 0.70)], [64.0, Color(0.42, 1.0, 0.98, 0.90)]]:
		var glow := Sprite2D.new()
		glow.texture = _make_blob()
		glow.modulate = entry[1]
		glow.scale = Vector2.ONE * (float(entry[0]) / 64.0)
		glow.material = _additive()
		add_child(glow)

	# Cekirdek: void oldugu icin ortasi karanlik.
	var core := Polygon2D.new()
	var points := PackedVector2Array()
	for index in range(18):
		var angle := TAU * float(index) / 18.0
		points.append(Vector2(cos(angle), sin(angle)) * 13.0)
	core.polygon = points
	core.color = Color(0.02, 0.03, 0.06, 1.0)
	add_child(core)

	var spin := create_tween().set_loops()
	spin.tween_property(self, "rotation", TAU, 1.6).from(0.0)


func _physics_process(delta: float) -> void:
	if consumed:
		return
	elapsed += delta
	if elapsed < homing_duration:
		var paddle := get_tree().get_first_node_in_group("game_paddle") as Node2D
		if is_instance_valid(paddle):
			var desired := (paddle.global_position - global_position).normalized()
			var turn := clampf(direction.angle_to(desired), -homing_rate * delta, homing_rate * delta)
			direction = direction.rotated(turn).normalized()
	global_position += direction * speed * delta
	_trail()

	var viewport_size: Vector2 = get_viewport_rect().size
	if (
		elapsed >= lifetime
		or global_position.y > viewport_size.y + 80.0
		or global_position.x < -120.0
		or global_position.x > viewport_size.x + 120.0
	):
		_detonate()


func _trail() -> void:
	if randf() > 0.45:
		return
	var mote := Polygon2D.new()
	mote.polygon = PackedVector2Array([
		Vector2(0.0, -5.0), Vector2(8.0, 0.0), Vector2(0.0, 5.0), Vector2(-8.0, 0.0)
	])
	mote.color = Color(0.35, 0.96, 0.94, 0.85)
	mote.material = _additive()
	mote.global_position = global_position + Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0))
	mote.rotation = randf_range(0.0, TAU)
	get_parent().add_child(mote)
	var fade := mote.create_tween().set_parallel(true)
	fade.tween_property(mote, "scale", Vector2.ONE * 0.2, 0.32)
	fade.tween_property(mote, "modulate:a", 0.0, 0.32)
	fade.chain().tween_callback(mote.queue_free)


func _on_body_entered(body: Node) -> void:
	if consumed:
		return
	if body.is_in_group("game_paddle"):
		if is_instance_valid(game) and game.has_method("apply_enemy_projectile_damage"):
			game.apply_enemy_projectile_damage()
		_detonate()


func _detonate() -> void:
	if consumed:
		return
	consumed = true
	set_deferred("monitoring", false)

	var burst := Node2D.new()
	burst.z_index = 8
	burst.global_position = global_position
	get_parent().add_child(burst)

	var flash := Sprite2D.new()
	flash.texture = _make_blob()
	flash.modulate = Color(0.62, 1.0, 0.98, 0.95)
	flash.scale = Vector2.ONE * (110.0 / 64.0)
	flash.material = _additive()
	burst.add_child(flash)
	var flash_tween := flash.create_tween().set_parallel(true)
	flash_tween.tween_property(flash, "scale", Vector2.ONE * (240.0 / 64.0), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.28)

	var count := 8 if OS.has_feature("mobile") else 14
	for index in range(count):
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([
			Vector2(0.0, -5.0), Vector2(13.0, 0.0), Vector2(0.0, 5.0), Vector2(-6.0, 0.0)
		])
		shard.color = Color(0.45, 1.0, 0.96, 0.9) if index % 2 == 0 else Color(0.20, 0.62, 0.78, 0.85)
		shard.material = _additive()
		var angle := TAU * float(index) / float(count) + randf_range(-0.15, 0.15)
		shard.rotation = angle
		burst.add_child(shard)
		var fly := shard.create_tween().set_parallel(true)
		fly.tween_property(shard, "position", Vector2.from_angle(angle) * randf_range(80.0, 165.0), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fly.tween_property(shard, "modulate:a", 0.0, 0.36)

	get_tree().create_timer(0.5).timeout.connect(burst.queue_free)
	queue_free()
