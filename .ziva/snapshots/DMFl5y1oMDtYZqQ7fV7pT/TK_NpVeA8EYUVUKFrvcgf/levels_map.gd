extends Control

signal level_selected(level_id: String)

@onready var marker: Sprite2D = $Marker
@onready var level_buttons: Control = $LevelButtons

func _ready() -> void:
	# Connect signals for each level button
	for button: Button in level_buttons.get_children():
		var level_id := button.name.to_lower()
		button.mouse_entered.connect(func() -> void: _on_level_button_hovered(button))
		button.mouse_exited.connect(func() -> void: _on_level_button_unhovered(button))

func _on_level_button_pressed(level_id: String) -> void:
	print("Level selected: ", level_id)
	level_selected.emit(level_id)
	# Here you would typically change scene:
	# get_tree().change_scene_to_file("res://levels/" + level_id + ".tscn")

func _on_level_button_hovered(button: Button) -> void:
	marker.visible = true
	# Position the marker above the button
	marker.global_position = button.global_position + button.size / 2.0
	marker.global_position.y -= 32.0 # Offset upwards
	
	# Hover effect for the button
	var tween := create_tween()
	tween.tween_property(button, "modulate:a", 0.5, 0.2)
	
	# Marker animation
	var marker_tween := create_tween().set_loops()
	marker_tween.tween_property(marker, "position:y", marker.position.y - 10, 0.5).set_trans(Tween.TRANS_SINE)
	marker_tween.tween_property(marker, "position:y", marker.position.y, 0.5).set_trans(Tween.TRANS_SINE)

func _on_level_button_unhovered(button: Button) -> void:
	marker.visible = false
	var tween := create_tween()
	tween.tween_property(button, "modulate:a", 0.0, 0.2)

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
