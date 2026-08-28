extends Node2D


func setup(from_position: Vector2, to_position: Vector2, telegraph: bool) -> void:
	global_position = Vector2.ZERO
	z_index = 46
	var glow := Line2D.new()
	var core := Line2D.new()
	var points := PackedVector2Array([from_position, to_position])
	glow.points = points
	core.points = points
	glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	core.end_cap_mode = Line2D.LINE_CAP_ROUND
	glow.antialiased = true
	core.antialiased = true
	if telegraph:
		glow.width = 2.0
		core.width = 0.7
		glow.default_color = Color(0.28, 0.72, 1.0, 0.16)
		core.default_color = Color(0.72, 0.90, 1.0, 0.38)
	else:
		glow.width = 8.0
		core.width = 2.0
		glow.default_color = Color(0.22, 0.62, 1.0, 0.38)
		core.default_color = Color(0.88, 0.98, 1.0, 1.0)
	add_child(glow)
	add_child(core)
	var lifetime := 0.24 if telegraph else 0.16
	var fade := create_tween().set_parallel(true)
	fade.tween_property(glow, "modulate:a", 0.0, lifetime)
	fade.tween_property(core, "modulate:a", 0.0, lifetime)
	fade.chain().tween_callback(queue_free)