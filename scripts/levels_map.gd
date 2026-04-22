extends Control

signal level_selected(level_id: String)

@onready var marker: Sprite2D = $Marker
@onready var level_buttons: Control = $LevelButtons
@onready var button_pressed_sound: ButtonPressedSound = $ButtonPressedSound

var marker_tween: Tween

func _ready() -> void:
	if marker:
		marker.hide()

	for child in level_buttons.get_children():
		if child is TextureButton:
			var button: TextureButton = child
			button.pivot_offset = button.size / 2.0
			button.resized.connect(func() -> void: button.pivot_offset = button.size / 2.0)

			button.mouse_entered.connect(func() -> void: _on_level_button_hovered(button))
			button.mouse_exited.connect(func() -> void: _on_level_button_unhovered(button))

			button.visible = true


func _on_level_button_hovered(button: TextureButton) -> void:
	marker.show()
	marker.global_position = button.global_position + Vector2(button.size.x / 2.0, -20)

	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.1)

	if marker_tween:
		marker_tween.kill()
	marker_tween = create_tween().set_loops()
	marker_tween.tween_property(marker, "offset:y", -40, 0.5).set_trans(Tween.TRANS_SINE)
	marker_tween.tween_property(marker, "offset:y", -20, 0.5).set_trans(Tween.TRANS_SINE)

func _on_level_button_unhovered(button: TextureButton) -> void:
	marker.hide()
	if marker_tween:
		marker_tween.kill()
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_level_button_pressed(level_id: String) -> void:
	print("Level selected: ", level_id)
	level_selected.emit(level_id)
	await button_pressed_sound.play_and_await()
	var scene_path = "res://scenes/levels/%s.tscn" % level_id
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		print("Scene not found: ", scene_path)

func _on_pier_pressed() -> void:
	print("Level selected: muelle")
	level_selected.emit("muelle")
	await button_pressed_sound.play_and_await()
	GameLoader.load_scene("res://games/muelle_level/muelle.tscn")

func _on_manglar_pressed() -> void:
	print("Level selected: mangrove (using board scene)")
	level_selected.emit("mangrove")
	await button_pressed_sound.play_and_await()
	get_tree().change_scene_to_file("res://games/manglar level/board.tscn")

func _on_mural_pressed() -> void:
	print("Level selected: mural")
	level_selected.emit("mural")
	await button_pressed_sound.play_and_await()
	get_tree().change_scene_to_file("res://games/mural_level/murallevel.tscn")

func _on_bosque_pressed() -> void:
	level_selected.emit("bosque")
	await button_pressed_sound.play_and_await()
	get_tree().change_scene_to_file("res://games/bosque_level/bosquelevel.tscn")

func _on_celebration_pressed() -> void:
	_on_level_button_pressed("celebration")

func _on_back_button_pressed() -> void:
	await button_pressed_sound.play_and_await()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
