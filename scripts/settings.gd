extends Control

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var sign_language_toggle: CheckButton = %SignLanguageToggle

func _ready() -> void:
	# Inicializar sliders con niveles de volumen actuales
	var music_bus_idx = AudioServer.get_bus_index("Music")
	var sfx_bus_idx = AudioServer.get_bus_index("SFX")
	
	if music_bus_idx != -1:
		music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_idx))
	if sfx_bus_idx != -1:
		sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_idx))
	
	# Aquí podrías cargar el estado de lengua de señas desde un archivo de guardado o Global
	# sign_language_toggle.button_pressed = Global.sign_language_enabled

func _on_music_slider_value_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_sfx_slider_value_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_sign_language_toggle_toggled(toggled_on: bool) -> void:
	# Actualizar configuración de accesibilidad global
	# Global.sign_language_enabled = toggled_on
	print("Lengua de señas activada: ", toggled_on)

func _on_back_button_pressed() -> void:
	# Usamos GameLoader si está disponible, o simplemente volvemos al menú
	if has_node("/root/GameLoader"):
		get_node("/root/GameLoader").load_scene("res://scenes/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
