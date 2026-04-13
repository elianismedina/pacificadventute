extends SceneTree

func _init():
	var stream = load("res://assets/sounds/main_menu_sound.wav")
	if not stream:
		printerr("FAILED: main_menu_sound.wav not found or corrupted.")
		quit()
		return
	print("INFO: Stream loaded: ", stream)
	print("INFO: Length: ", stream.get_length())
	if stream is AudioStreamWAV:
		print("INFO: Format: ", stream.format)
		print("INFO: Stereo: ", stream.stereo)
		print("INFO: Mix Rate: ", stream.mix_rate)
		print("INFO: Loop Mode: ", stream.loop_mode)
	quit()
