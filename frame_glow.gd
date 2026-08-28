extends Control


const PEAK_ALPHA = 0.19
const FADE_IN_DURATION = 0.22
const COLOR_BLEND_DURATION = 0.16
const FADE_OUT_DURATION = 0.58
const START_WIDTH = 60.0
const PEAK_WIDTH = 80.0

@onready var glow_material = $EdgeVignette.material as ShaderMaterial

var glow_tween: Tween


func _ready():

	glow_material.set_shader_parameter("glow_color", Color(0.0, 0.9, 1.0, 1.0))
	glow_material.set_shader_parameter("glow_strength", 0.0)
	glow_material.set_shader_parameter("glow_width", START_WIDTH)


func flash(brick_color):

	if glow_tween and glow_tween.is_valid():
		glow_tween.kill()

	var target_color = Color(brick_color.r, brick_color.g, brick_color.b, 1.0)
	var current_color = glow_material.get_shader_parameter("glow_color")

	glow_tween = create_tween()
	glow_tween.set_parallel(true)
	glow_tween.set_trans(Tween.TRANS_SINE)
	glow_tween.set_ease(Tween.EASE_OUT)
	glow_tween.tween_method(
		_set_glow_color,
		current_color,
		target_color,
		COLOR_BLEND_DURATION
	)
	glow_tween.tween_property(
		glow_material,
		"shader_parameter/glow_strength",
		PEAK_ALPHA,
		FADE_IN_DURATION
	)
	glow_tween.tween_property(
		glow_material,
		"shader_parameter/glow_width",
		PEAK_WIDTH,
		FADE_IN_DURATION
	)

	glow_tween.chain().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glow_tween.tween_property(
		glow_material,
		"shader_parameter/glow_strength",
		0.0,
		FADE_OUT_DURATION
	)
	glow_tween.chain().tween_callback(_reset_invisible_width)


func _reset_invisible_width():

	glow_material.set_shader_parameter("glow_width", START_WIDTH)


func _set_glow_color(color):

	glow_material.set_shader_parameter("glow_color", color)
