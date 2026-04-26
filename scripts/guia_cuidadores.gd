extends Control

@export_file("*.tscn") var back_scene_path: String = "res://scenes/main_menu.tscn"
const GUIDE_PATH = "res://assets/files/GuiaActividadesOffline.pdf"

func _on_download_button_pressed() -> void:
	# Convert res:// path to global path for OS.shell_open
	var global_path = ProjectSettings.globalize_path(GUIDE_PATH)
	OS.shell_open(global_path)

func _on_back_button_pressed() -> void:
	if ResourceLoader.exists(back_scene_path):
		get_tree().change_scene_to_file(back_scene_path)
	else:
		push_error("Back scene path not found: " + back_scene_path)
