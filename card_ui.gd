extends Button


var normal_scale = Vector2(1.0, 1.0)
var selected_scale = Vector2(1.07, 1.07)

var animation: Tween
var mobile_touch_pressed := false


func _ready():

	# Kart merkezinden büyüsün
	pivot_offset = size / 2.0
	if OS.has_feature("mobile"):
		_configure_mobile_touch_visuals()
		button_down.connect(_on_mobile_button_down)
		button_up.connect(_on_mobile_button_up)

	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_focus_entered():

	if OS.has_feature("mobile"):
		return
	highlight_card()


func _on_focus_exited():

	if OS.has_feature("mobile"):
		return
	unhighlight_card()


func _on_mouse_entered():

	if OS.has_feature("mobile"):
		return
	grab_focus()


func _on_mouse_exited():

	if OS.has_feature("mobile") and mobile_touch_pressed:
		_on_mobile_button_up()
	# Desktop'ta klavye focus'unu koruyoruz.


func _configure_mobile_touch_visuals() -> void:
	focus_mode = Control.FOCUS_NONE
	var normal_style := get_theme_stylebox("normal").duplicate() as StyleBox
	add_theme_stylebox_override("focus", normal_style)
	add_theme_stylebox_override("hover", normal_style)
	var pressed_style := normal_style.duplicate() as StyleBoxFlat
	if is_instance_valid(pressed_style):
		pressed_style.bg_color = Color(0.025, 0.055, 0.12, 0.99)
		pressed_style.border_color = Color(0.32, 0.96, 1.0, 1.0)
		pressed_style.set_border_width_all(3)
		pressed_style.shadow_color = Color(0.05, 0.82, 1.0, 0.58)
		pressed_style.shadow_size = 8
		add_theme_stylebox_override("pressed", pressed_style)


func _on_mobile_button_down() -> void:
	if not OS.has_feature("mobile"):
		return
	mobile_touch_pressed = true
	if animation:
		animation.kill()
	z_index = 10
	animation = create_tween().set_parallel(true)
	animation.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animation.tween_property(self, "scale", Vector2.ONE * 1.07, 0.08)
	animation.tween_property(self, "modulate", Color(1.10, 1.10, 1.10, 1.0), 0.08)


func _on_mobile_button_up() -> void:
	if not OS.has_feature("mobile"):
		return
	mobile_touch_pressed = false
	if animation:
		animation.kill()
	z_index = 0
	animation = create_tween().set_parallel(true)
	animation.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animation.tween_property(self, "scale", Vector2.ONE, 0.12)
	animation.tween_property(self, "modulate", Color.WHITE, 0.12)


func highlight_card():

	if animation:
		animation.kill()

	z_index = 10

	animation = create_tween()

	animation.set_trans(Tween.TRANS_BACK)
	animation.set_ease(Tween.EASE_OUT)

	animation.tween_property(
		self,
		"scale",
		selected_scale,
		0.15
	)


func unhighlight_card():

	if animation:
		animation.kill()

	z_index = 0

	animation = create_tween()

	animation.set_trans(Tween.TRANS_QUAD)
	animation.set_ease(Tween.EASE_OUT)

	animation.tween_property(
		self,
		"scale",
		normal_scale,
		0.12
	)
