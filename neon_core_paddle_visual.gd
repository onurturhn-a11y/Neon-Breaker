extends Node2D

const LAYER_SCALE := Vector2(0.087477, 0.087477)
const ENERGY_PERIOD := 1.5
const CORE_PERIOD := 1.1

@onready var body: Sprite2D = $Body
@onready var energy: Sprite2D = $Energy
@onready var core: Sprite2D = $Core

var animation_time := 0.0
var flash_strength := 0.0
var flash_tween: Tween
var plasma_active := false


func _ready() -> void:
	body.scale = LAYER_SCALE
	energy.scale = LAYER_SCALE
	core.scale = LAYER_SCALE


func _process(delta: float) -> void:
	animation_time += delta
	var energy_phase := (sin(animation_time * TAU / ENERGY_PERIOD) + 1.0) * 0.5
	var energy_brightness := lerpf(0.90, 1.06, energy_phase) + flash_strength * 0.60
	energy.modulate = Color(
		energy_brightness,
		energy_brightness,
		energy_brightness + flash_strength * 0.08,
		minf(lerpf(0.80, 1.0, energy_phase) + flash_strength * 0.12, 1.0)
	)

	var active_core_period := 0.75 if plasma_active else CORE_PERIOD
	var core_phase := (sin(animation_time * TAU / active_core_period + 0.3) + 1.0) * 0.5
	core.scale = LAYER_SCALE * lerpf(0.96, 1.04, core_phase)
	var core_brightness := lerpf(0.94, 1.10, core_phase) + (0.08 if plasma_active else 0.0) + flash_strength * 0.70
	core.modulate = Color(core_brightness, core_brightness, core_brightness, 1.0)


func play_hit_flash() -> void:
	if is_instance_valid(flash_tween):
		flash_tween.kill()
	flash_strength = 1.0
	flash_tween = create_tween()
	flash_tween.tween_interval(0.04)
	flash_tween.tween_property(self, "flash_strength", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func set_plasma_active(value: bool) -> void:
	plasma_active = value