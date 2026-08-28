extends CanvasLayer


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		var game := get_parent()
		if game.has_method("resume_from_pause_menu"):
			game.call("resume_from_pause_menu")
		get_viewport().set_input_as_handled()
