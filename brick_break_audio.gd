extends Node


const POOL_SIZE = 8
const BREAK_STREAM = preload("res://assets/audio/sfx/brick_break.wav")
var players: Array[AudioStreamPlayer] = []
var next_player = 0

func _ready():

	for i in range(POOL_SIZE):

		var player = AudioStreamPlayer.new()
		player.stream = BREAK_STREAM
		player.volume_db = -4.0
		player.bus = &"SFX"
		add_child(player)
		players.append(player)


func play_break():

	var player = players[next_player]
	next_player = (next_player + 1) % players.size()
	player.pitch_scale = randf_range(0.96, 1.04)
	player.play()