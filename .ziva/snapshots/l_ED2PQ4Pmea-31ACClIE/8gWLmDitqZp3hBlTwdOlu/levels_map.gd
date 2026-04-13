extends Control

signal level_selected(level_id: String)

func _on_level_button_pressed(level_id: String) -> void:
	print("Level selected: ", level_id)
	level_selected.emit(level_id)
	# Here you would typically change scene:
	# get_tree().change_scene_to_file("res://levels/" + level_id + ".tscn")

func _on_pier_pressed() -> void:
	_on_level_button_pressed("pier")

func _on_mangrove_pressed() -> void:
	_on_level_button_pressed("mangrove")

func _on_mural_pressed() -> void:
	_on_level_button_pressed("mural")

func _on_forest_pressed() -> void:
	_on_level_button_pressed("forest")

func _on_celebration_pressed() -> void:
	_on_level_button_pressed("celebration")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
