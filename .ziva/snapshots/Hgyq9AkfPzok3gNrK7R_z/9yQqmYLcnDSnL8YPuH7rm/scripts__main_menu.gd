extends Control

func _ready() -> void:
	# Ensure the main menu sound loops
	if $AudioStreamPlayer.stream is AudioStreamWAV:
		$AudioStreamPlayer.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	$AudioStreamPlayer.play()

func _on_play_button_pressed() -> void:
	print("Play button pressed!")
	_play_button_sound_and_stop_music()
	await $ButtonPressedSound.finished
	get_tree().change_scene_to_file("res://scenes/levels_map.tscn")

func _on_settings_button_pressed() -> void:
	print("Settings button pressed!")
	_play_button_sound_and_stop_music()
	# Add logic for settings here when implemented

func _on_guia_cuidadores_button_pressed() -> void:
	print("Guia Cuidadores button pressed!")
	_play_button_sound_and_stop_music()
	# Add logic for guides here when implemented

func _play_button_sound_and_stop_music() -> void:
	if $AudioStreamPlayer.playing:
		$AudioStreamPlayer.stop()
	
	$ButtonPressedSound.stream = preload("res://assets/sounds/on_button_pressed_sound.wav")
	$ButtonPressedSound.play()
