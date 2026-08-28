extends Node2D

var glow_line: Line2D
var core_line: Line2D

func _ready() -> void:
	global_position = Vector2.ZERO
	z_index = 44
	glow_line = Line2D.new()
	core_line = Line2D.new()
	for line in [glow_line, core_line]:
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.antialiased = true
		add_child(line)
	glow_line.default_color = Color(0.30, 0.42, 1.0, 0.34)
	core_line.default_color = Color(0.82, 0.94, 1.0, 0.96)

func configure(beam_width: float) -> void:
	glow_line.width = beam_width * 2.2
	core_line.width = maxf(1.5, beam_width * 0.42)

func update_beam(from_position: Vector2, to_position: Vector2) -> void:
	var points := PackedVector2Array([from_position, to_position])
	glow_line.points = points
	core_line.points = points

func play_overload() -> void:
	var flash := create_tween().set_parallel(true)
	flash.tween_property(glow_line, "width", glow_line.width * 1.7, 0.08)
	flash.tween_property(core_line, "width", core_line.width * 1.5, 0.08)
	flash.tween_property(glow_line, "modulate", Color(1.25, 1.15, 1.45, 1.0), 0.08)

func finish() -> void:
	var fade := create_tween().set_parallel(true)
	fade.tween_property(glow_line, "modulate:a", 0.0, 0.12)
	fade.tween_property(core_line, "modulate:a", 0.0, 0.12)
	fade.chain().tween_callback(queue_free)
