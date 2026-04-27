extends Control

@export_file("*.tscn") var back_scene_path: String = "res://scenes/main_menu.tscn"
const GUIDE_PATH = "res://assets/files/GuiaActividadesOffline.pdf"

@onready var download_button: TextureButton = %DownloadButton
@onready var back_button: TextureButton = %BackButton
@onready var content_container: VBoxContainer = $CenterContainer/VBoxContainer
@onready var button_sound: AudioStreamPlayer = %ButtonSound

func _ready() -> void:
	# Initial state for fade-in
	modulate.a = 0
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	
	# Setup button animations
	_setup_button_animations(download_button)
	_setup_button_animations(back_button)
	
	# Subtle floating animation for the content
	_start_floating_animation()

func _setup_button_animations(button: TextureButton) -> void:
	button.pivot_offset = button.size / 2
	
	button.mouse_entered.connect(func():
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	
	button.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	
	button.button_down.connect(func():
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(0.9, 0.9), 0.1)
	)
	
	button.button_up.connect(func():
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.1)
	)

func _start_floating_animation() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(content_container, "position:y", content_container.position.y + 10, 2.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(content_container, "position:y", content_container.position.y, 2.0).set_trans(Tween.TRANS_SINE)

func _on_download_button_pressed() -> void:
	button_sound.play()
	var global_path = ProjectSettings.globalize_path(GUIDE_PATH)
	OS.shell_open(global_path)

func _on_back_button_pressed() -> void:
	button_sound.play()
	# Fade out before changing scene
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await fade_tween.finished
	
	if ResourceLoader.exists(back_scene_path):
		get_tree().change_scene_to_file(back_scene_path)
	else:
		push_error("Back scene path not found: " + back_scene_path)
