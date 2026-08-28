extends Node2D

# ==================================================
# TEKILLIK - THE VOID ENTITY'nin imza saldirisi
#
# Oyun alanina birakilan kara delik. Menzilindeki toplarin
# HIZINI degistirmeden yonunu kendine dogru kivirir; yani top
# yavaslamaz, yorungesi bozulur. Cok yakinda etki kesilir ki
# top yorungeye kilitlenip sonsuza kadar donmesin.
# ==================================================

@export var radius: float = 135.0
@export var lifetime: float = 3.0
## Saniyede kac radyan bukebilecegi (menzil kenarinda sifira duser).
@export var turn_rate: float = 3.0

const INNER_DEAD_ZONE := 30.0

var elapsed := 0.0
var collapsing := false
var core: Polygon2D
var glow: Sprite2D
var swirl_root: Node2D


func _ready() -> void:
	z_index = 6
	add_to_group("void_singularity")
	_build_visual()
	_play_open()


func _build_visual() -> void:
	# Genis hale cok yayilinca gorunmez oluyordu: dis + ic olarak iki katman.
	var blob := _make_blob_texture()
	var outer := Sprite2D.new()
	outer.texture = blob
	outer.modulate = Color(0.18, 0.70, 0.78, 0.75)
	outer.scale = Vector2.ONE * (radius * 2.0 / 64.0)
	outer.material = _additive()
	add_child(outer)

	glow = Sprite2D.new()
	glow.texture = blob
	glow.modulate = Color(0.42, 1.0, 0.98, 0.95)
	glow.scale = Vector2.ONE * (radius * 0.95 / 64.0)
	glow.material = _additive()
	add_child(glow)

	swirl_root = Node2D.new()
	add_child(swirl_root)
	for index in range(4):
		var arc := Line2D.new()
		arc.width = 3.2
		arc.default_color = Color(0.46, 1.0, 0.96, 0.90 - index * 0.14)
		arc.antialiased = true
		arc.material = _additive()
		var points := PackedVector2Array()
		var turns := 1.35
		var start := TAU * float(index) / 4.0
		for step in range(46):
			var t := float(step) / 45.0
			var angle := start + t * TAU * turns
			var r := lerpf(radius * 0.24, radius * 1.02, t)
			points.append(Vector2(cos(angle), sin(angle)) * r)
		arc.points = points
		swirl_root.add_child(arc)

	# Olay ufku: tam siyah disk, etrafinda ince parlak halka.
	core = Polygon2D.new()
	var core_points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		core_points.append(Vector2(cos(angle), sin(angle)) * radius * 0.20)
	core.polygon = core_points
	core.color = Color(0.01, 0.01, 0.03, 1.0)
	add_child(core)

	var ring := Line2D.new()
	ring.width = 2.6
	ring.default_color = Color(0.55, 1.0, 0.98, 0.95)
	ring.antialiased = true
	ring.material = _additive()
	var ring_points := PackedVector2Array()
	for index in range(25):
		var angle := TAU * float(index) / 24.0
		ring_points.append(Vector2(cos(angle), sin(angle)) * radius * 0.215)
	ring.points = ring_points
	add_child(ring)


func _additive() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat


func _make_blob_texture() -> ImageTexture:
	var image := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	for x in range(64):
		for y in range(64):
			var d := Vector2(float(x) - 31.5, float(y) - 31.5).length() / 31.5
			var v := clampf(1.0 - d, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, v * v * (3.0 - 2.0 * v)))
	return ImageTexture.create_from_image(image)


func _play_open() -> void:
	scale = Vector2.ONE * 0.12
	modulate.a = 0.0
	var open := create_tween().set_parallel(true)
	open.tween_property(self, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	open.tween_property(self, "modulate:a", 1.0, 0.20)


func _physics_process(delta: float) -> void:
	swirl_root.rotation += delta * 3.1
	core.scale = Vector2.ONE * (1.0 + sin(elapsed * 7.0) * 0.06)

	elapsed += delta
	if elapsed >= lifetime and not collapsing:
		_collapse()
		return
	if collapsing:
		return
	_bend_balls(delta)


func _bend_balls(delta: float) -> void:
	for ball: Node in get_tree().get_nodes_in_group("game_ball"):
		if not is_instance_valid(ball) or not (ball is Node2D):
			continue
		if ball.is_in_group("manual_launch_waiting"):
			continue
		var current = ball.get("direction")
		if not (current is Vector2) or current == Vector2.ZERO:
			continue
		var offset: Vector2 = global_position - (ball as Node2D).global_position
		var distance := offset.length()
		if distance > radius or distance < INNER_DEAD_ZONE:
			continue
		var falloff := 1.0 - distance / radius
		var desired := offset / distance
		var turn := clampf(
			(current as Vector2).angle_to(desired),
			-turn_rate * delta * falloff,
			turn_rate * delta * falloff
		)
		ball.set("direction", (current as Vector2).rotated(turn).normalized())


func _collapse() -> void:
	collapsing = true
	for index in range(12):
		var mote := Polygon2D.new()
		mote.polygon = PackedVector2Array([
			Vector2(0.0, -4.0), Vector2(9.0, 0.0), Vector2(0.0, 4.0), Vector2(-9.0, 0.0)
		])
		mote.color = Color(0.45, 1.0, 0.96, 0.9)
		mote.material = _additive()
		var angle := TAU * float(index) / 12.0
		mote.position = Vector2.from_angle(angle) * radius * 0.85
		mote.rotation = angle
		add_child(mote)
		var suck := mote.create_tween().set_parallel(true)
		suck.tween_property(mote, "position", Vector2.ZERO, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		suck.tween_property(mote, "modulate:a", 0.0, 0.30)

	var implode := create_tween().set_parallel(true)
	implode.tween_property(self, "scale", Vector2.ONE * 0.05, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	implode.tween_property(self, "modulate:a", 0.0, 0.32)
	implode.chain().tween_callback(queue_free)
