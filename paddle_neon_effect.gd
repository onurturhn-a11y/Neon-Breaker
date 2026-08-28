extends Node2D


@onready var energy_layer = $VisualLayers/EnergyLayer
@onready var side_glow_layer = $VisualLayers/SideGlowLayer
@onready var aura_layer = $VisualLayers/AuraLayer

var pulse_time = 0.0
var flash_strength = 0.0
var flash_tween: Tween
var aura_base_scale = Vector2.ONE
var special_paddle_sprite: Sprite2D
var special_paddle_glow: Sprite2D
var special_glow_color := Color.WHITE
var special_paddle_active := false
var cosmetic_visual: Node

const SPECIAL_IDLE_GLOW_MULTIPLIER: float = 1.35
const SPECIAL_IDLE_ALPHA_MULTIPLIER: float = 1.30
const SPECIAL_IDLE_PULSE_MULTIPLIER: float = 1.15


func _ready():

	aura_base_scale = aura_layer.scale


func _process(delta):

	pulse_time += delta

	var energy_pulse = (
		sin(pulse_time * TAU / 2.0) + 1.0
	) * 0.5

	var side_pulse = (
		sin(pulse_time * TAU / 2.15 + 1.1) + 1.0
	) * 0.5

	var aura_pulse = (
		sin(pulse_time * TAU / 2.8 + 0.4) + 1.0
	) * 0.5

	var energy_idle_brightness := lerpf(0.85, 1.15, energy_pulse)
	var energy_idle_alpha := lerpf(0.72, 1.0, energy_pulse)
	if special_paddle_active:
		energy_idle_brightness = _boost_idle_pulse(
			energy_idle_brightness, 1.0, SPECIAL_IDLE_GLOW_MULTIPLIER
		)
		energy_idle_alpha = minf(
			_boost_idle_pulse(
				energy_idle_alpha, 0.86, SPECIAL_IDLE_ALPHA_MULTIPLIER
			),
			1.0
		)
	var energy_flash_color := Color.WHITE
	if special_paddle_active:
		energy_flash_color = special_glow_color
	energy_layer.modulate = Color(
		energy_idle_brightness + energy_flash_color.r * flash_strength * 0.65,
		energy_idle_brightness + energy_flash_color.g * flash_strength * 0.65,
		energy_idle_brightness + energy_flash_color.b * flash_strength * 0.65,
		energy_idle_alpha + flash_strength * 0.12
	)

	var side_brightness := lerpf(0.78, 1.18, side_pulse)
	var side_alpha := lerpf(0.55, 0.95, side_pulse)
	if special_paddle_active:
		side_brightness = _boost_idle_pulse(
			side_brightness, 0.98, SPECIAL_IDLE_GLOW_MULTIPLIER
		)
		side_alpha = minf(side_alpha * SPECIAL_IDLE_ALPHA_MULTIPLIER, 1.0)

	side_glow_layer.modulate = Color(
		side_brightness,
		side_brightness,
		side_brightness,
		side_alpha
	)

	var aura_idle_brightness := lerpf(0.70, 1.12, aura_pulse)
	var aura_idle_alpha := lerpf(0.28, 0.48, aura_pulse)
	if special_paddle_active:
		aura_idle_brightness = _boost_idle_pulse(
			aura_idle_brightness, 0.91, SPECIAL_IDLE_GLOW_MULTIPLIER
		)
		aura_idle_alpha = minf(
			aura_idle_alpha * SPECIAL_IDLE_ALPHA_MULTIPLIER, 1.0
		)
	var aura_brightness: float = aura_idle_brightness + flash_strength * 0.60

	aura_layer.modulate = Color(
		aura_brightness,
		aura_brightness,
		lerp(0.90, 1.18, aura_pulse)
		+ flash_strength * 0.48,
		aura_idle_alpha + flash_strength * 0.30
	)

	var aura_scale_factor = lerp(0.93, 1.08, aura_pulse)
	aura_layer.scale = aura_base_scale * aura_scale_factor

	if special_paddle_active:
		aura_layer.modulate = Color(
			special_glow_color.r * (aura_idle_brightness + flash_strength * 0.60),
			special_glow_color.g * (aura_idle_brightness + flash_strength * 0.60),
			special_glow_color.b * (aura_idle_brightness + flash_strength * 0.60),
			aura_idle_alpha + flash_strength * 0.30
		)


func _boost_idle_pulse(value: float, center: float, intensity: float) -> float:
	var boosted_amplitude: float = (value - center) * SPECIAL_IDLE_PULSE_MULTIPLIER
	return (center + boosted_amplitude) * intensity

func configure_special_paddle(
	paddle_sprite: Sprite2D,
	glow_sprite: Sprite2D,
	glow_color: Color
) -> void:
	special_paddle_sprite = paddle_sprite
	special_paddle_glow = glow_sprite
	special_glow_color = glow_color
	special_paddle_active = is_instance_valid(special_paddle_sprite)
	if not special_paddle_active:
		aura_layer.modulate = Color.WHITE

func configure_cosmetic_visual(visual: Node) -> void:
	cosmetic_visual = visual


func set_plasma_active(value: bool) -> void:
	if is_instance_valid(cosmetic_visual) and cosmetic_visual.has_method("set_plasma_active"):
		cosmetic_visual.set_plasma_active(value)


func flash():

	if is_instance_valid(cosmetic_visual) and cosmetic_visual.has_method("play_hit_flash"):
		cosmetic_visual.play_hit_flash()
	if flash_tween:
		flash_tween.kill()

	flash_strength = 1.0
	flash_tween = create_tween()

	flash_tween.tween_interval(0.10)

	flash_tween.tween_property(
		self,
		"flash_strength",
		0.0,
		0.15
	)