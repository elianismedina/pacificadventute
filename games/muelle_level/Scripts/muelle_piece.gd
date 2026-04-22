extends Control

signal drag_started
signal drag_ended(successful)

@onready var texture_rect = $TextureRect
@onready var frame = $Frame

var shape_type: String = "" # circle, square, triangle, rectangle
var image_path: String = ""
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var target_slot = null

func _ready():
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func setup(shape: String, image: String):
	shape_type = shape
	image_path = image
	
	if texture_rect and image_path:
		texture_rect.texture = load(image_path)
	
	if frame:
		frame.visible = false
	
	# Wait for layout to settle before capturing original position
	await get_tree().process_frame
	original_position = position

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag()
			elif is_dragging:
				_stop_drag()
	
	if event is InputEventMouseMotion and is_dragging:
		position += event.relative

func _start_drag():
	is_dragging = true
	move_to_front()
	drag_started.emit()

func _stop_drag():
	is_dragging = false
	
	var found_slot = _find_slot_under_mouse()
	
	if found_slot and found_slot.can_accept(self):
		target_slot = found_slot
		target_slot.accept_piece(self)
		_snap_to_slot()
		drag_ended.emit(true)
	else:
		_return_to_original()
		drag_ended.emit(false)

func _find_slot_under_mouse():
	var slots_container = get_tree().current_scene.find_child("SlotsContainer", true, false)
	
	if not slots_container:
		return null
	
	for slot in slots_container.get_children():
		var rect = slot.get_global_rect()
		if rect.has_point(get_global_mouse_position()):
			return slot
	return null

func _snap_to_slot():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	# Use global position for snapping to ensure target accuracy
	tween.tween_property(self, "global_position", target_slot.global_position, 0.2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE 
	tween.parallel().tween_property(self, "size", target_slot.size, 0.2)

func _return_to_original():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", original_position, 0.3)

