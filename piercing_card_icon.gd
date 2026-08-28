extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.48, size.y * 0.50)
	var radius := minf(size.x, size.y) * 0.105

	# Topun gerisindeki hız izleri.
	for index in range(3):
		var y_offset := (float(index) - 1.0) * radius * 0.78
		var start := center + Vector2(-radius * (3.2 + index * 0.35), y_offset)
		var finish := center + Vector2(-radius * 1.35, y_offset)
		draw_line(start, finish, Color(0.28, 0.86, 1.0, 0.36 + index * 0.12), 2.0, true)

	# Delinen tuğlayı iki parçalı, sakin bir neon siluetle anlat.
	var brick_x := center.x + radius * 2.45
	draw_rect(Rect2(brick_x, center.y - radius * 1.55, radius * 0.55, radius * 1.05), Color(0.5, 0.3, 0.95, 0.70), true)
	draw_rect(Rect2(brick_x, center.y + radius * 0.50, radius * 0.55, radius * 1.05), Color(0.5, 0.3, 0.95, 0.70), true)

	# Ön taraftaki delme ışını ve ok ucu.
	var beam_start := center + Vector2(radius * 1.05, 0.0)
	var beam_end := center + Vector2(radius * 4.15, 0.0)
	draw_line(beam_start, beam_end, Color(0.85, 0.98, 1.0, 0.92), 3.0, true)
	draw_polyline(PackedVector2Array([
		beam_end + Vector2(-radius * 0.75, -radius * 0.55),
		beam_end,
		beam_end + Vector2(-radius * 0.75, radius * 0.55),
	]), Color(0.85, 0.98, 1.0, 0.92), 3.0, true)

	# Doygun dış katman ve sıcak çekirdek, +1 Top ikonundan net ayrılır.
	draw_circle(center, radius * 1.22, Color(0.08, 0.64, 1.0, 0.24))
	draw_circle(center, radius, Color(0.12, 0.78, 1.0, 0.95))
	draw_circle(center - Vector2(radius * 0.18, radius * 0.18), radius * 0.56, Color(0.92, 0.99, 1.0, 1.0))
