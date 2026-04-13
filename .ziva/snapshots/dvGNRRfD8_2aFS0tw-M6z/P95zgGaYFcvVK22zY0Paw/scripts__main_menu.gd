extends Control

func _on_play_button_pressed() -> void:
	$ButtonPressedSound.play()
	await $ButtonPressedSound.finished
	get_tree().change_scene_to_file("res://scenes/levels_map.tscn")
