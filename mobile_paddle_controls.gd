extends CanvasLayer


@export_range(0.88, 0.94, 0.01) var rail_width_ratio := 0.92
@export var rail_height := 56.0
@export_range(0.0, 100.0, 1.0) var mobile_extra_bottom_padding := 50.0
@export var knob_diameter := 92.16
@export_range(35.0, 50.0, 1.0) var paddle_above_knob_offset := 44.0
@export_range(-160.0, 0.0, 1.0) var mobile_paddle_y_offset := -80.0

@onready var paddle = get_parent().get_node("Paddle")
@onready var rail: Panel = $Rail
@onready var knob: Panel = $Rail/Knob
@onready var knob_core: ColorRect = $Rail/Knob/Core

var active_finger_index := -1
var aim_finger_index := -1
var aimed_ball: Node2D
var mobile_enabled := false
var knob_ratio := 0.5
var safe_area_debug_logged := false
var knob_feedback_tween: Tween
var knob_style: StyleBoxFlat


func _ready() -> void:
	mobile_enabled = OS.has_feature("mobile")
	visible = mobile_enabled
	if not mobile_enabled:
		set_process(false)
		set_process_input(false)
		return

	_configure_visuals()
	_layout_control()
	_set_knob_ratio(paddle.get_horizontal_position_ratio(), false)


func _notification(what: int) -> void:
	if not is_node_ready() or not mobile_enabled:
		return
	if what == NOTIFICATION_PAUSED:
		visible = false
		_cancel_drag()
		_cancel_mobile_aim(false)
	elif what == NOTIFICATION_UNPAUSED:
		visible = true
		_layout_control()


func _process(_delta: float) -> void:
	_layout_control()
	_log_safe_area_once()
	if active_finger_index == -1:
		# Dış sistem paddle konumunu değiştirirse slider göstergesi de güncel kalır.
		_set_knob_ratio(paddle.get_horizontal_position_ratio(), false)


func _input(event: InputEvent) -> void:
	if not mobile_enabled:
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			var control_hit := (
				rail.get_global_rect().has_point(touch.position)
				or knob.get_global_rect().has_point(touch.position)
			)
			if active_finger_index == -1 and control_hit:
				active_finger_index = touch.index
				_set_knob_pressed(true)
				_update_from_touch_x(touch.position.x)
				get_viewport().set_input_as_handled()
			elif active_finger_index == -1 and aim_finger_index == -1 and _begin_mobile_aim(
				touch.index,
				touch.position
			):
				get_viewport().set_input_as_handled()
		elif touch.index == active_finger_index:
			_cancel_drag()
			get_viewport().set_input_as_handled()
		elif touch.index == aim_finger_index:
			_update_mobile_aim(touch.position)
			_cancel_mobile_aim(true)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == active_finger_index:
			_update_from_touch_x(drag.position.x)
			get_viewport().set_input_as_handled()
		elif drag.index == aim_finger_index:
			_update_mobile_aim(drag.position)
			get_viewport().set_input_as_handled()


func _layout_control() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var safe_rect := GameManager.get_layout_safe_rect(viewport_size)
	var safe_bottom := safe_rect.position.y + safe_rect.size.y
	var rail_width: float = safe_rect.size.x * rail_width_ratio
	rail.size = Vector2(rail_width, rail_height)
	rail.position = Vector2(
		safe_rect.position.x + (safe_rect.size.x - rail_width) * 0.5,
		safe_bottom - rail_height - mobile_extra_bottom_padding
	)
	knob.size = Vector2(knob_diameter, knob_diameter)
	_update_knob_position()
	var knob_center_y: float = rail.position.y + rail.size.y * 0.5
	paddle.set_mobile_control_y(
		knob_center_y - paddle_above_knob_offset + mobile_paddle_y_offset
	)


func _log_safe_area_once() -> void:
	if safe_area_debug_logged:
		return
	var safe_rect := GameManager.get_layout_safe_rect(get_viewport().get_visible_rect().size)
	var safe_bottom := safe_rect.position.y + safe_rect.size.y
	print(
		"MOBILE SAFE AREA | rect=%s | safe_bottom=%.2f | mobile_extra_bottom_padding=%.2f"
		% [safe_rect, safe_bottom, mobile_extra_bottom_padding]
	)
	safe_area_debug_logged = true


func _update_from_touch_x(touch_x: float) -> void:
	var travel_width: float = maxf(1.0, rail.size.x - knob_diameter)
	var local_center_x: float = touch_x - rail.global_position.x
	var ratio := clampf((local_center_x - knob_diameter * 0.5) / travel_width, 0.0, 1.0)
	_set_knob_ratio(ratio, true)


func _set_knob_ratio(value: float, drive_paddle: bool) -> void:
	knob_ratio = clampf(value, 0.0, 1.0)
	_update_knob_position()
	if drive_paddle:
		paddle.set_mobile_slider_ratio(knob_ratio)


func _update_knob_position() -> void:
	if not is_instance_valid(knob):
		return
	# Knob görsel merkezi paddle'ın gerçek clamp mapping merkeziyle birebir aynıdır.
	var paddle_limits: Vector2 = paddle.get_horizontal_limits()
	var mapped_center_x := lerpf(paddle_limits.x, paddle_limits.y, knob_ratio)
	knob.position = Vector2(
		mapped_center_x - rail.position.x - knob_diameter * 0.5,
		(rail.size.y - knob_diameter) * 0.5
	)


func _cancel_drag() -> void:
	active_finger_index = -1
	_set_knob_pressed(false)
	if is_instance_valid(paddle):
		paddle.end_mobile_slider_drag()


func _begin_mobile_aim(finger_index: int, touch_position: Vector2) -> bool:
	if get_tree().paused or not _is_gameplay_touch(touch_position):
		return false
	var waiting_balls := get_tree().get_nodes_in_group("manual_launch_waiting")
	if waiting_balls.is_empty():
		return false

	aimed_ball = waiting_balls[0] as Node2D
	if not is_instance_valid(aimed_ball):
		return false
	aim_finger_index = finger_index
	_update_mobile_aim(touch_position)
	return true


func _update_mobile_aim(touch_position: Vector2) -> void:
	if is_instance_valid(aimed_ball) and aimed_ball.has_method("set_mobile_aim_target"):
		aimed_ball.set_mobile_aim_target(touch_position)


func _cancel_mobile_aim(launch_on_release: bool) -> void:
	if launch_on_release and is_instance_valid(aimed_ball) and aimed_ball.has_method("launch_ball"):
		aimed_ball.launch_ball()
	aim_finger_index = -1
	aimed_ball = null


func _is_gameplay_touch(touch_position: Vector2) -> bool:
	var safe_rect := GameManager.get_layout_safe_rect(get_viewport().get_visible_rect().size)
	if not safe_rect.has_point(touch_position):
		return false
	# HUD üst bölgesi ve alt slider bölgesi aim/launch alanının dışında kalır.
	if touch_position.y < GameManager.PLAYFIELD_TOP:
		return false
	if touch_position.y >= rail.get_global_rect().position.y:
		return false
	for candidate in get_tree().root.find_children("*", "BaseButton", true, false):
		var button := candidate as BaseButton
		if is_instance_valid(button) and button.is_visible_in_tree():
			if button.get_global_rect().has_point(touch_position):
				return false
	return true


func _configure_visuals() -> void:
	var rail_style := StyleBoxFlat.new()
	rail_style.bg_color = Color(0.012, 0.055, 0.085, 0.56)
	rail_style.border_color = Color(0.08, 0.72, 0.88, 0.48)
	rail_style.set_border_width_all(2)
	rail_style.set_corner_radius_all(28)
	rail.add_theme_stylebox_override("panel", rail_style)

	knob_style = StyleBoxFlat.new()
	knob_style.bg_color = Color(0.025, 0.22, 0.29, 0.90)
	knob_style.border_color = Color(0.28, 0.94, 1.0, 0.92)
	knob_style.set_border_width_all(3)
	knob_style.set_corner_radius_all(int(knob_diameter * 0.5))
	knob_style.shadow_color = Color(0.0, 0.78, 1.0, 0.30)
	knob_style.shadow_size = 8
	knob.add_theme_stylebox_override("panel", knob_style)
	# Eski kısa yatay grip çizgisi yeni dairesel knob tasarımında kullanılmıyor.
	knob_core.visible = false
	_set_knob_pressed(false)


func _set_knob_pressed(pressed: bool) -> void:
	knob.pivot_offset = knob.size * 0.5
	if is_instance_valid(knob_feedback_tween):
		knob_feedback_tween.kill()
	var duration := 0.08 if pressed else 0.12
	var target_scale := Vector2.ONE * (1.12 if pressed else 1.0)
	var target_alpha := 1.0 if pressed else 0.78
	var target_bg := Color(0.06, 0.38, 0.48, 0.98) if pressed else Color(0.025, 0.22, 0.29, 0.90)
	var target_border := Color(0.72, 1.0, 1.0, 1.0) if pressed else Color(0.28, 0.94, 1.0, 0.92)
	var target_shadow := Color(0.08, 0.92, 1.0, 0.62) if pressed else Color(0.0, 0.78, 1.0, 0.30)
	knob_feedback_tween = create_tween().set_parallel(true)
	knob_feedback_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	knob_feedback_tween.tween_property(knob, "scale", target_scale, duration)
	knob_feedback_tween.tween_property(knob, "modulate:a", target_alpha, duration)
	knob_feedback_tween.tween_property(knob_style, "bg_color", target_bg, duration)
	knob_feedback_tween.tween_property(knob_style, "border_color", target_border, duration)
	knob_feedback_tween.tween_property(knob_style, "shadow_color", target_shadow, duration)
	knob_feedback_tween.tween_property(knob_style, "shadow_size", 13 if pressed else 8, duration)
