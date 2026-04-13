extends Control

func _ready() -> void:
	print("MainMenu: _ready called")
	var master_idx = AudioServer.get_bus_index("Master")
	print("MainMenu: Master Muted: ", AudioServer.is_bus_mute(master_idx))
	print("MainMenu: Master Volume DB: ", AudioServer.get_bus_volume_db(master_idx))
	print("MainMenu: AudioStreamPlayer Stream: ", audio_stream_player.stream)
	if audio_stream_player.stream:
		print("MainMenu: Stream Length: ", audio_stream_player.stream.get_length())
	print("MainMenu: AudioStreamPlayer Volume DB: ", audio_stream_player.volume_db)
	print("MainMenu: AudioStreamPlayer Bus: ", audio_stream_player.bus)
	# Ensure the main menu sound loops
	if $AudioStreamPlayer.stream:
		print("MainMenu: AudioStreamPlayer has stream: ", $AudioStreamPlayer.stream.resource_path)
		print("MainMenu: Stream length: ", $AudioStreamPlayer.stream.get_length())
		if $AudioStreamPlayer.stream is AudioStreamWAV:
			$AudioStreamPlayer.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			print("MainMenu: Set loop mode for WAV")
		elif $AudioStreamPlayer.stream is AudioStreamMP3 or $AudioStreamPlayer.stream is AudioStreamOggVorbis:
			$AudioStreamPlayer.stream.loop = true
			print("MainMenu: Set loop mode for MP3/OGG")
		
		$AudioStreamPlayer.stream_paused = false
		$AudioStreamPlayer.play.call_deferred()
		print("MainMenu: AudioStreamPlayer.play() called deferred. Playing: ", $AudioStreamPlayer.playing)
	else:
		print("MainMenu ERROR: AudioStreamPlayer has NO stream!")

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
