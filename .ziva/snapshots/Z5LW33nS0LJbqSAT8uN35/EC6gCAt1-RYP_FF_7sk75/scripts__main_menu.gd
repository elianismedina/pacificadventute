extends Control

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var button_pressed_sound: AudioStreamPlayer = $ButtonPressedSound

func _ready() -> void:
	# Ensure music is playing
	if audio_stream_player.stream and not audio_stream_player.playing:
		audio_stream_player.play()

func _on_play_button_pressed() -> void:
	_play_button_sound_and_stop_music()
	await button_pressed_sound.finished
	get_tree().change_scene_to_file("res://scenes/levels_map.tscn")

func _on_settings_button_pressed() -> void:
	_play_button_sound_and_stop_music()
	await button_pressed_sound.finished
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_guia_cuidadores_button_pressed() -> void:
	_play_button_sound_and_stop_music()
	# Add logic for guides here when implemented

func _play_button_sound_and_stop_music() -> void:
	if audio_stream_player.playing:
		audio_stream_player.stop()
	
	button_pressed_sound.play()
