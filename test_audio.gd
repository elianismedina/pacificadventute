extends Node

func test_audio() -> void:
	print("Buses count: ", AudioServer.bus_count)
	for i in range(AudioServer.bus_count):
		print("Bus ", i, " (", AudioServer.get_bus_name(i), "): Volume=", AudioServer.get_bus_volume_db(i), ", Mute=", AudioServer.is_bus_mute(i))
	
	var stream = load("res://assets/sounds/main_menu_sound.wav")
	if stream:
		print("Stream type: ", stream.get_class())
		print("Stream Length: ", stream.get_length())
		if stream is AudioStreamWAV:
			print("Stream loop mode: ", stream.loop_mode)
	else:
		print("Failed to load stream")
