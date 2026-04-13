extends Control

func _on_play_button_pressed() -> void:
	print("Play button pressed!")
	$ButtonPressedSound.play()
	await $ButtonPressedSound.finished
	get_tree().change_scene_to_file("res://scenes/levels_map.tscn")
