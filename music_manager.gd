extends Node


var music_player: AudioStreamPlayer


func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.stream = preload("res://01 - Genesis - Soma Animus.wav")
	music_player.volume_db = -8.0
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)
	music_player.play()
	set_music_enabled(GameManager.music_enabled)


func set_music_enabled(enabled: bool) -> void:
	GameManager.music_enabled = enabled
	if not is_instance_valid(music_player):
		return
	if enabled and not music_player.playing:
		music_player.play()
	music_player.stream_paused = not enabled


func is_music_enabled() -> bool:
	return GameManager.music_enabled


func _on_music_finished():
	if GameManager.music_enabled:
		music_player.play()
