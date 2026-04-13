extends Control

signal level_selected(level_id: String)

@onready var marker: Sprite2D = $Marker
@onready var level_buttons: Control = $LevelButtons

var marker_tween: Tween

func _ready() -> void:
	# Connect signals for each level button
	for button: Button in level_buttons.get_children():
		button.modulate.a = 1.0 # Fully visible
		button.mouse_entered.connect(func() -> void: _on_level_button_hovered(button))
		button.mouse_exited.connect(func() -> void: _on_level_button_unhovered(button))

func _on_level_button_hovered(button: Button) -> void:
	marker.visible = true
	# Position the marker above the button
	marker.global_position = button.global_position + Vector2(button.size.x / 2.0, -20)
	
	# Hover effect for the button
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.1)
	
	# Marker animation
	if marker_tween:
		marker_tween.kill()
	marker_tween = create_tween().set_loops()
	var base_y = marker.position.y
	marker_tween.tween_property(marker, "position:y", base_y - 10, 0.5).set_trans(Tween.TRANS_SINE)
	marker_tween.tween_property(marker, "position:y", base_y, 0.5).set_trans(Tween.TRANS_SINE)

func _on_level_button_unhovered(button: Button) -> void:
	marker.visible = false
	if marker_tween:
		marker_tween.kill()
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_level_button_pressed(level_id: String) -> void:
	print("Level selected: ", level_id)
	level_selected.emit(level_id)

func _on_pier_pressed() -> void:
	_on_level_button_pressed("pier")

func _on_manglar_pressed() -> void:
	_on_level_button_pressed("mangrove")

func _on_mural_pressed() -> void:
	_on_level_button_pressed("mural")

func _on_bosque_pressed() -> void:
	_on_level_button_pressed("forest")

func _on_celebration_pressed() -> void:
	_on_level_button_pressed("celebration")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
