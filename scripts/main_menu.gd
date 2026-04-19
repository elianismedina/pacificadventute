extends Control

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var button_pressed_sound: ButtonPressedSound = $ButtonPressedSound

func _ready() -> void:
	if audio_stream_player.stream and not audio_stream_player.playing:
		audio_stream_player.play()

func _on_play_button_pressed() -> void:
	await _play_button_sound_and_stop_music()
	GameLoader.load_scene("res://scenes/levels_map.tscn")

func _on_settings_button_pressed() -> void:
	await _play_button_sound_and_stop_music()
	GameLoader.load_scene("res://scenes/settings.tscn")

func _on_guia_cuidadores_button_pressed() -> void:
	await _play_button_sound_and_stop_music()
	GameLoader.load_scene("res://scenes/guia_cuidadores.tscn")

func _play_button_sound_and_stop_music() -> void:
	if audio_stream_player.playing:
		audio_stream_player.stop()
	await button_pressed_sound.play_and_await()
