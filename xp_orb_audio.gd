extends Node


const POOL_SIZE := 6
const PITCH_STEP := 0.04
const MAX_PITCH := 1.28
const CHAIN_RESET_MSEC := 450
const COLLECT_STREAM = preload("res://assets/audio/sfx/xp_orb_collect.wav")

var players: Array[AudioStreamPlayer] = []
var collect_chain_index := 0
var last_collect_msec := -CHAIN_RESET_MSEC


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for voice_index in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "XPCollectVoice%d" % (voice_index + 1)
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.stream = COLLECT_STREAM
		player.volume_db = -12.0
		player.bus = &"SFX"
		add_child(player)
		players.append(player)


func play_collect() -> void:
	var now_msec := Time.get_ticks_msec()
	if now_msec - last_collect_msec >= CHAIN_RESET_MSEC:
		collect_chain_index = 0
	else:
		collect_chain_index += 1
	last_collect_msec = now_msec

	var pitch := minf(1.0 + collect_chain_index * PITCH_STEP, MAX_PITCH)
	for player in players:
		if player.playing:
			continue
		player.pitch_scale = pitch
		player.play()
		return
