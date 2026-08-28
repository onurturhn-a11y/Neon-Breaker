extends Node2D

const LIFETIME := 0.18
var radius := 62.0

func setup(world_position: Vector2, blast_radius: float) -> void:
	global_position = world_position
	radius = blast_radius
	z_index = 35
	queue_redraw()
	var fade := create_tween().set_parallel(true)
	fade.tween_property(self, "scale", Vector2.ONE * 1.12, LIFETIME)
	fade.tween_property(self, "modulate:a", 0.0, LIFETIME)
	fade.chain().tween_callback(queue_free)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius * 0.20, Color(1.0, 0.58, 0.16, 0.18))
	draw_arc(Vector2.ZERO, radius * 0.62, 0.0, TAU, 28, Color(1.0, 0.48, 0.10, 0.72), 2.0, true)
