extends CanvasLayer


@onready var panel: Control = $Panel
@onready var overcharge_button: Button = $Panel/OverchargeCard
@onready var ricochet_button: Button = $Panel/RicochetCard


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func _unhandled_key_input(event: InputEvent) -> void:
	if OS.has_feature("mobile"):
		return
	if not panel.visible or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode in [KEY_LEFT, KEY_A]:
		overcharge_button.grab_focus()
		get_viewport().set_input_as_handled()
	elif key_event.keycode in [KEY_RIGHT, KEY_D]:
		ricochet_button.grab_focus()
		get_viewport().set_input_as_handled()
	elif key_event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		var focused := get_viewport().gui_get_focus_owner()
		if focused == overcharge_button or focused == ricochet_button:
			focused.emit_signal("pressed")
			get_viewport().set_input_as_handled()
