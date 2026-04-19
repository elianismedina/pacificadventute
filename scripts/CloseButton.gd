extends TextureButton

func _on_pressed() -> void:
	await $ButtonPressedSound.play_and_await()
	if get_node_or_null("/root/GameLoader"):
		get_node("/root/GameLoader").load_scene("res://scenes/levels_map.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/levels_map.tscn")
