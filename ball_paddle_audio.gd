extends Node


const POOL_SIZE := 4
const RETRIGGER_PROTECTION_MSEC := 50
const PADDLE_HIT_STREAM = preload("res://assets/audio/sfx/ball_paddle_hit.wav")

var players: Array[AudioStreamPlayer] = []
var next_player := 0
var last_played_msec := -RETRIGGER_PROTECTION_MSEC


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for voice_index in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "PaddleHitVoice%d" % (voice_index + 1)
		player.stream = PADDLE_HIT_STREAM
		player.volume_db = -8.0
		player.bus = &"SFX"
		add_child(player)
		players.append(player)


func play_hit() -> void:
	var now_msec := Time.get_ticks_msec()
	if now_msec - last_played_msec < RETRIGGER_PROTECTION_MSEC:
		return
	last_played_msec = now_msec
	var player := players[next_player]
	next_player = (next_player + 1) % players.size()
	player.pitch_scale = randf_range(0.97, 1.03)
	player.play()
