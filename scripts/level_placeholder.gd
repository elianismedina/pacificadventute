extends Control

@export_file("*.tscn") var back_scene_path: String = "res://scenes/levels_map.tscn"

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(back_scene_path)
