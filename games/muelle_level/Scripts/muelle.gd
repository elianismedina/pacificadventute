extends Control

@export var piece_scene: PackedScene = preload("res://games/muelle_level/muelle_piece.tscn")
@export var slot_scene: PackedScene = preload("res://games/muelle_level/muelle_slot.tscn")

@onready var pieces_container = $PiecesContainer
@onready var slots_container = $SlotsContainer
@onready var win_overlay = $UI_Layer/WinOverlay

var shapes = ["circle", "diamond", "heart", "rectangle"]
var images = {
	"circle": "res://assets/textures/muelle level/circle_piece.png",
	"diamond": "res://assets/textures/muelle level/diamond_piece.png",
	"heart": "res://assets/textures/muelle level/heart_pice.png",
	"rectangle": "res://assets/textures/muelle level/rectangle_piece.png"
}

var slots_images = {
	"circle": "res://assets/textures/muelle level/circle_slot.png",
	"diamond": "res://assets/textures/muelle level/diamond_slot.png",
	"heart": "res://assets/textures/muelle level/heart_slot.png",
	"rectangle": "res://assets/textures/muelle level/rectangle_slot.png"
}

var pieces_placed = 0

func _ready():
	_setup_level()
	win_overlay.visible = false

func _setup_level():
	# Safety checks
	if not pieces_container or not slots_container:
		printerr("MuelleLevel: Required containers not found!")
		return

	# Clean up
	for child in pieces_container.get_children():
		child.queue_free()
	for child in slots_container.get_children():
		child.queue_free()
	
	pieces_placed = 0
	
	var viewport_size = get_viewport_rect().size
	var spacing = viewport_size.x / (shapes.size() + 1)
	
	# Create slots
	var slots_shapes = shapes.duplicate()
	
	for i in range(slots_shapes.size()):
		var shape = slots_shapes[i]
		var slot = slot_scene.instantiate()
		slots_container.add_child(slot)
		slot.setup(shape, slots_images[shape])
		# Correctly centered positioning
		slot.position = Vector2(spacing * (i + 1) - slot.custom_minimum_size.x / 2.0, viewport_size.y * 0.3)
	
	# Create pieces
	var piece_shapes = shapes.duplicate()
	piece_shapes.shuffle()
	
	for i in range(piece_shapes.size()):
		var shape = piece_shapes[i]
		var piece = piece_scene.instantiate()
		pieces_container.add_child(piece)
		piece.setup(shape, images[shape])
		# Position them in the bottom half
		piece.position = Vector2(spacing * (i + 1) - piece.custom_minimum_size.x / 2.0, viewport_size.y * 0.7)
		piece.drag_ended.connect(_on_piece_drag_ended)

func _on_piece_drag_ended(successful):
	if successful:
		$SuccessSound.play()
		pieces_placed += 1
		if pieces_placed == shapes.size():
			_on_level_complete()
	else:
		$WrongSound.play()

func _on_level_complete():
	print("Level Complete!")
	win_overlay.visible = true
	# Use a tween for a nice fade-in
	win_overlay.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(win_overlay, "modulate:a", 1.0, 1.0)

func _on_volver_menu_pressed():
	GameLoader.load_scene("res://scenes/levels_map.tscn")

func _on_retry_pressed():
	_setup_level()
	win_overlay.visible = false
