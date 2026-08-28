extends Control


signal rank_changed(rank_index)

@export var combo_timeout = 0.85
var base_combo_timeout = 0.85

const WARNING_TIME = 0.24
const FADE_DURATION = 0.25
const RANKS = ["F", "E", "D", "C", "B", "A", "S", "SS", "SSS"]
const THRESHOLDS = [3, 6, 9, 12, 15, 18, 21, 24, 27]
const SHAKE_AMPLITUDES = [1.5, 1.7, 1.9, 2.1, 2.3, 2.5, 2.8, 3.1, 3.5]
const NO_RANK_SHAKE = 1.6

@onready var rank_label = $RankLabel

var combo_hits = 0
var time_left = 0.0
var rank_index = -1
var fade_tween: Tween
var punch_tween: Tween


func _ready():

	visible = false
	rank_label.pivot_offset = rank_label.size * 0.5
	base_combo_timeout = combo_timeout
	refresh_card_modifiers()


func refresh_card_modifiers() -> void:
	# Zincir Bellegi karti combo penceresini uzatir.
	combo_timeout = base_combo_timeout * GameManager.get_combo_timeout_multiplier()


func _process(delta):

	if combo_hits <= 0:
		return

	time_left = maxf(time_left - delta, 0.0)

	if rank_index >= 0 and time_left <= WARNING_TIME:
		var warning_ratio = time_left / WARNING_TIME
		modulate.a = lerpf(0.68, 1.0, warning_ratio)

	if time_left <= 0.0:
		expire_combo()


func register_break():

	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()

	combo_hits += 1
	time_left = combo_timeout
	modulate.a = 1.0

	var new_rank_index = get_rank_index(combo_hits)
	if new_rank_index < 0:
		visible = false
		return NO_RANK_SHAKE

	visible = true
	rank_label.text = RANKS[new_rank_index]

	if new_rank_index != rank_index:
		rank_index = new_rank_index
		rank_changed.emit(rank_index)
		play_rank_punch()
	else:
		rank_index = new_rank_index
	if OS.has_feature("mobile"):
		var combo_visual_gain := 1.06 + float(rank_index) * 0.012
		rank_label.self_modulate = Color(combo_visual_gain, combo_visual_gain, combo_visual_gain, 1.0)

	return SHAKE_AMPLITUDES[rank_index]


func get_rank_name(index: int) -> String:
	if index < 0 or index >= RANKS.size():
		return "-"
	return RANKS[index]


func get_rank_index(hits):

	var result = -1
	for i in range(THRESHOLDS.size()):
		if hits >= THRESHOLDS[i]:
			result = i
		else:
			break
	return result


func play_rank_punch():

	if punch_tween and punch_tween.is_valid():
		punch_tween.kill()

	rank_label.scale = Vector2.ONE
	punch_tween = rank_label.create_tween()
	punch_tween.set_trans(Tween.TRANS_BACK)
	punch_tween.set_ease(Tween.EASE_OUT)
	var punch_scale := 1.25 if OS.has_feature("mobile") else 1.18
	punch_tween.tween_property(rank_label, "scale", Vector2.ONE * punch_scale, 0.08)
	punch_tween.set_trans(Tween.TRANS_QUAD)
	punch_tween.tween_property(rank_label, "scale", Vector2.ONE, 0.10)


func expire_combo():

	combo_hits = 0
	time_left = 0.0
	rank_index = -1
	rank_changed.emit(rank_index)

	if not visible:
		return

	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	fade_tween.tween_callback(hide)


func reset_combo():

	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	if punch_tween and punch_tween.is_valid():
		punch_tween.kill()

	combo_hits = 0
	time_left = 0.0
	rank_index = -1
	rank_changed.emit(rank_index)
	modulate.a = 0.0
	rank_label.scale = Vector2.ONE
	rank_label.self_modulate = Color.WHITE
	hide()
