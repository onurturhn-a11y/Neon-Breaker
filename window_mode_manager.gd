extends Node


const REFERENCE_SIZE := Vector2i(1152, 648)
const WINDOW_MARGIN := Vector2i(64, 64)


func _ready() -> void:
	# Pencere kısayolu kart ekranı oyunu pause ettiğinde de kullanılabilsin.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var is_f11: bool = key_event.keycode == KEY_F11
	var is_alt_enter: bool = key_event.alt_pressed and (
		key_event.keycode == KEY_ENTER
		or key_event.keycode == KEY_KP_ENTER
	)
	if not (is_f11 or is_alt_enter):
		return

	toggle_fullscreen()
	get_viewport().set_input_as_handled()


func toggle_fullscreen() -> void:
	var current_mode := DisplayServer.window_get_mode()
	var is_fullscreen := current_mode in [
		DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
	]

	if is_fullscreen:
		_set_safe_windowed_mode()
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _set_safe_windowed_mode() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	var screen := DisplayServer.window_get_current_screen()
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)
	var available_size := Vector2i(
		maxi(320, usable_rect.size.x - WINDOW_MARGIN.x),
		maxi(180, usable_rect.size.y - WINDOW_MARGIN.y)
	)
	var fit_scale := minf(
		1.0,
		minf(
			float(available_size.x) / float(REFERENCE_SIZE.x),
			float(available_size.y) / float(REFERENCE_SIZE.y)
		)
	)
	var target_size := Vector2i(
		roundi(REFERENCE_SIZE.x * fit_scale),
		roundi(REFERENCE_SIZE.y * fit_scale)
	)

	DisplayServer.window_set_size(target_size)
	DisplayServer.window_set_position(
		usable_rect.position + (usable_rect.size - target_size) / 2
	)
