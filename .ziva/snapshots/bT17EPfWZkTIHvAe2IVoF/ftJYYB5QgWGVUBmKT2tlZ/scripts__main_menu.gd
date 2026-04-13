extends Control

func _on_play_button_pressed() -> void:
	print("Play button pressed!")
	$ButtonPressedSound.stream = preload("res://assets/sounds/on_button_pressed_sound.wav")
	$ButtonPressedSound.play()
	await $ButtonPressedSound.finished
	get_tree().change_scene_to_file("res://scenes/levels_map.tscn")
