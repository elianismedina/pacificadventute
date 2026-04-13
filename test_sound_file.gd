extends Node

func _ready():
	var stream = load("res://assets/sounds/main_menu_sound.wav")
	if not stream:
		print("TEST_RESULT: FAILED to load stream")
		return
	
	print("TEST_RESULT: Stream loaded: ", stream)
	print("TEST_RESULT: Stream length: ", stream.get_length())
	
	var player = AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()
	
	await get_tree().create_timer(1.0).timeout
	print("TEST_RESULT: Playing after 1s: ", player.playing)
	print("TEST_RESULT: Playback position: ", player.get_playback_position())
	
	# Quit the scene to see logs
	get_tree().quit()
