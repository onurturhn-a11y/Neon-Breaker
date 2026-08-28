extends Node2D


const LIFETIME = 0.14

@onready var glow_line = $GlowLine
@onready var core_line = $CoreLine


func setup(from_position, to_position, rank_index):

	global_position = Vector2.ZERO
	var rank_ratio = float(rank_index) / 8.0
	glow_line.width = lerpf(3.5, 5.0, rank_ratio)
	core_line.width = lerpf(1.2, 1.8, rank_ratio)
	glow_line.default_color.a = lerpf(0.20, 0.34, rank_ratio)
	var points = build_arc_points(from_position, to_position)
	glow_line.points = points
	core_line.points = points

	var fade = create_tween()
	fade.set_parallel(true)
	fade.tween_property(glow_line, "modulate:a", 0.0, LIFETIME)
	fade.tween_property(core_line, "modulate:a", 0.0, LIFETIME)
	fade.chain().tween_callback(queue_free)


func build_arc_points(from_position, to_position):

	var points = PackedVector2Array()
	var direction = to_position - from_position
	var normal = direction.normalized().orthogonal()
	var intermediate_count = randi_range(4, 7)

	points.append(from_position)
	for i in range(1, intermediate_count + 1):
		var ratio = float(i) / float(intermediate_count + 1)
		var edge_fade = sin(ratio * PI)
		var jitter = randf_range(-8.0, 8.0) * edge_fade
		points.append(from_position.lerp(to_position, ratio) + normal * jitter)
	points.append(to_position)
	return points
