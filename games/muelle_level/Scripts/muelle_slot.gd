extends Control

@onready var silhouette = $Silhouette
@onready var frame = $Frame

var shape_type: String = "" # circle, square, triangle, rectangle
var is_occupied: bool = false

func setup(shape: String, texture_path: String):
	shape_type = shape
	if silhouette and texture_path:
		silhouette.texture = load(texture_path)
		# Make the silhouette brighter and more visible
		silhouette.modulate = Color(1, 1, 1, 1.0) 

	# Hide the programmatic frame
	if frame:
		frame.visible = false

func can_accept(piece) -> bool:
	return not is_occupied and piece.shape_type == shape_type

func accept_piece(_piece):
	is_occupied = true
	
	# Ensure scaling happens from the center
	pivot_offset = size / 2.0
	
	var tween = create_tween()
	# Pop animation: scale up then back to normal
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Flash green effect
	var color_tween = create_tween()
	color_tween.tween_property(silhouette, "modulate", Color.GREEN, 0.2)
	color_tween.tween_property(silhouette, "modulate", Color.WHITE, 0.2)

