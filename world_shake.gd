extends Node


const SHAKE_DURATION = 0.12
const MAX_AMPLITUDE = 3.5
const Y_STRENGTH = 0.62
const DECAY_POWER = 2.2
const FIREBALL_SHAKE_DURATION = 0.10
const FIREBALL_SHAKE_COOLDOWN_MSEC = 160

var world: Node2D
var base_position = Vector2.ZERO
var remaining = 0.0
var active_amplitude = 0.0
var phase = 0.0
var current_duration = SHAKE_DURATION
var last_fireball_shake_msec = -FIREBALL_SHAKE_COOLDOWN_MSEC


func _ready():

	world = get_parent() as Node2D
	base_position = world.position
	set_process(false)


func start_break(amplitude):

	if remaining <= 0.0:
		phase = randf_range(0.0, TAU)

	active_amplitude = clampf(amplitude, 0.0, MAX_AMPLITUDE)
	current_duration = SHAKE_DURATION
	remaining = SHAKE_DURATION
	set_process(true)


func start_fireball(amplitude: float) -> void:
	var now_msec := Time.get_ticks_msec()
	if now_msec - last_fireball_shake_msec < FIREBALL_SHAKE_COOLDOWN_MSEC:
		return
	last_fireball_shake_msec = now_msec
	if remaining <= 0.0:
		phase = randf_range(0.0, TAU)
	active_amplitude = maxf(active_amplitude, clampf(amplitude, 0.0, MAX_AMPLITUDE))
	current_duration = FIREBALL_SHAKE_DURATION
	remaining = maxf(remaining, FIREBALL_SHAKE_DURATION)
	set_process(true)

func _process(delta):

	remaining = maxf(remaining - delta, 0.0)

	if remaining <= 0.0:
		world.position = base_position
		active_amplitude = 0.0
		set_process(false)
		return

	phase += delta * 72.0
	var time_ratio = remaining / maxf(current_duration, 0.001)
	var decayed_amplitude = active_amplitude * pow(time_ratio, DECAY_POWER)

	world.position = base_position + Vector2(
		sin(phase) * decayed_amplitude,
		cos(phase * 1.37) * decayed_amplitude * Y_STRENGTH
	)


func _exit_tree():

	if is_instance_valid(world):
		world.position = base_position
