extends Node2D

const LIFETIME := 0.16
var effect_radius := 72.0


func setup(world_position: Vector2, radius: float) -> void:
	global_position = world_position
	effect_radius = radius
	queue_redraw()
	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(self, "modulate:a", 0.0, LIFETIME)
	fade.tween_property(self, "scale", Vector2.ONE * 1.12, LIFETIME)
	fade.chain().tween_callback(queue_free)


func _draw() -> void:
	var glow := Color(0.12, 0.78, 1.0, 0.30)
	var core := Color(0.76, 0.98, 1.0, 0.92)
	draw_arc(Vector2.ZERO, effect_radius * 0.62, 0.0, TAU, 32, glow, 5.0, true)
	draw_arc(Vector2.ZERO, effect_radius * 0.58, 0.0, TAU, 32, core, 1.5, true)
	for index in range(6):
		var angle := TAU * float(index) / 6.0
		var inner := Vector2.from_angle(angle) * effect_radius * 0.20
		var outer := Vector2.from_angle(angle + 0.10) * effect_radius * 0.72
		draw_line(inner, outer, glow, 4.0, true)
		draw_line(inner, outer, core, 1.2, true)