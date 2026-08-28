extends TextureRect

@export_range(70.0, 90.0, 1.0) var cycle_duration: float = 80.0
@export var drift_offset: Vector2 = Vector2(15.0, -10.0)
@export var base_visual_scale: float = 1.04
@export var peak_visual_scale: float = 1.055

var _drift_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("mobile"):
		self_modulate = Color(1.06, 1.07, 1.09, 1.0)
	resized.connect(_refresh_pivot)
	_refresh_pivot()
	position = Vector2.ZERO
	scale = Vector2.ONE * base_visual_scale
	_start_drift_loop()


func _refresh_pivot() -> void:
	pivot_offset = size * 0.5


func _start_drift_loop() -> void:
	if _drift_tween != null:
		_drift_tween.kill()

	var half_cycle: float = cycle_duration * 0.5
	_drift_tween = create_tween().set_loops()
	_drift_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_drift_tween.tween_property(self, "position", drift_offset, half_cycle)
	_drift_tween.parallel().tween_property(
		self,
		"scale",
		Vector2.ONE * peak_visual_scale,
		half_cycle
	)
	_drift_tween.tween_property(self, "position", Vector2.ZERO, half_cycle)
	_drift_tween.parallel().tween_property(
		self,
		"scale",
		Vector2.ONE * base_visual_scale,
		half_cycle
	)
