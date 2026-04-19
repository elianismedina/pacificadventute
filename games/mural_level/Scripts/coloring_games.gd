## Coloring Game - Vol.1 Game 02
## Features: Object zooming, color mixing logic, area-based painting, sequential sub-games.
extends Node2D

@export_group("Required Nodes")
@export var brush: Node2D
@export var brush_head: Sprite2D
@export var things_node: Node2D
@export var palette_node: Node2D

@export_group("Content")
@export var object_titles: Array[Texture2D] = []

var active_colors: Dictionary = {}
var current_color: Color = Color.TRANSPARENT
var is_brush_active: bool = false
var is_object_focused: bool = false

var objects: Array[Node2D] = []
var current_object_index: int = 0
var initial_data: Dictionary = {}
var _active_tween: Tween = null
var title_display: TextureRect

const COLOR_DICT: Dictionary = {
	"blue": Color(0.0, 0.68, 0.94),
	"red": Color(1.0, 0.0, 0.0),
	"yellow": Color(1.0, 1.0, 0.0),
	"black": Color(0.0, 0.0, 0.0),
	"white": Color(1.0, 1.0, 1.0)
}

var SCREEN_CENTER: Vector2
var next_button: Button

func _ready() -> void:
	var canvas_inv: Transform2D = get_canvas_transform().affine_inverse()
	var view_size: Vector2 = get_viewport_rect().size
	SCREEN_CENTER = canvas_inv * (view_size / 2.0)

	if brush:
		brush.global_position = canvas_inv * Vector2(view_size.x - 150, view_size.y - 70)
	if brush_head:
		brush_head.visible = false

	if things_node:
		for obj in things_node.get_children():
			if obj is Node2D:
				objects.append(obj)
				initial_data[obj] = {
					"pos": obj.global_position,
					"scale": obj.scale
				}
		for i in range(objects.size()):
			_set_object_active(objects[i], i == 0)

	_setup_ui()

func _setup_ui() -> void:
	var ui_layer: CanvasLayer = null
	for child in get_children():
		if child is CanvasLayer:
			ui_layer = child
			break
	if not ui_layer:
		ui_layer = CanvasLayer.new()
		add_child(ui_layer)

	title_display = TextureRect.new()
	title_display.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title_display.offset_bottom = 120
	title_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ui_layer.add_child(title_display)
	_update_title()

	next_button = Button.new()
	next_button.text = "Siguiente"
	next_button.custom_minimum_size = Vector2(160, 60)
	next_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	next_button.offset_left = -200
	next_button.offset_top = -130
	next_button.offset_right = -20
	next_button.offset_bottom = -60
	next_button.pressed.connect(_on_next_pressed)
	ui_layer.add_child(next_button)

func _update_title() -> void:
	if not title_display:
		return
	if current_object_index < object_titles.size():
		title_display.texture = object_titles[current_object_index]
	else:
		title_display.texture = null

# Toggle visibility and collision detection together so hidden objects can't be hit.
func _set_object_active(obj: Node2D, active: bool) -> void:
	obj.visible = active
	for area in _collect_areas(obj):
		area.monitorable = active
		area.monitoring = active

func _collect_areas(node: Node) -> Array:
	var areas: Array = []
	for child in node.get_children():
		if child is Area2D:
			areas.append(child)
		areas.append_array(_collect_areas(child))
	return areas

func _on_next_pressed() -> void:
	if _active_tween:
		_active_tween.kill()
		_active_tween = null

	var current_obj: Node2D = objects[current_object_index]
	if initial_data.has(current_obj):
		var data: Dictionary = initial_data[current_obj]
		current_obj.global_position = data["pos"]
		current_obj.scale = data["scale"]
		current_obj.z_index = 0
	is_object_focused = false
	_set_object_active(current_obj, false)

	current_object_index += 1
	if current_object_index >= objects.size():
		GameLoader.load_scene("res://scenes/levels_map.tscn")
		return

	_set_object_active(objects[current_object_index], true)
	_update_title()
	if current_object_index == objects.size() - 1:
		next_button.text = "Terminar"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos: Vector2 = get_global_mouse_position()

		if _check_palette_click(mouse_pos):
			return

		var space_state := get_world_2d().direct_space_state
		var query := PhysicsPointQueryParameters2D.new()
		query.position = mouse_pos
		query.collide_with_areas = true

		var results := space_state.intersect_point(query)

		if results.is_empty():
			_reset_current_object()
			return

		_handle_interaction(results)

func _handle_interaction(results: Array) -> void:
	var hit_patch: Node2D = null
	var hit_object_root: Node2D = null

	for i in range(results.size() - 1, -1, -1):
		var area = results[i].collider as Area2D
		if not area: continue
		var parent = area.get_parent()

		if parent.is_in_group("paintable") or parent.name.begins_with("patch"):
			hit_patch = parent
		elif parent.is_in_group("interactable_root") or parent.name.begins_with("Object"):
			hit_object_root = parent

	if not is_object_focused:
		var target = hit_object_root if hit_object_root else (hit_patch.get_parent() if hit_patch else null)
		if target: _focus_object(target)
	else:
		if hit_patch and is_brush_active:
			hit_patch.self_modulate = current_color

func _focus_object(target: Node2D) -> void:
	if _active_tween:
		_active_tween.kill()
	_active_tween = create_tween().set_parallel(true)
	_active_tween.tween_property(target, "global_position", SCREEN_CENTER, 0.5).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(target, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_QUINT)
	target.z_index = 10
	is_object_focused = true

func _reset_current_object() -> void:
	if not is_object_focused: return
	if objects.is_empty(): return
	var obj: Node2D = objects[current_object_index]
	if is_instance_valid(obj) and initial_data.has(obj):
		var data: Dictionary = initial_data[obj]
		if _active_tween:
			_active_tween.kill()
		_active_tween = create_tween().set_parallel(true)
		_active_tween.tween_property(obj, "global_position", data["pos"], 0.4).set_trans(Tween.TRANS_SINE)
		_active_tween.tween_property(obj, "scale", data["scale"], 0.4).set_trans(Tween.TRANS_SINE)
		obj.z_index = 0
	is_object_focused = false

func _check_palette_click(mouse_pos: Vector2) -> bool:
	if not palette_node: return false

	for color_btn in palette_node.get_children():
		if color_btn is Sprite2D:
			if color_btn.get_rect().has_point(color_btn.to_local(mouse_pos)):
				var c_name: String = color_btn.name.to_lower()
				if c_name == "clean":
					active_colors.clear()
				else:
					_handle_color_mixing(c_name)
				_update_brush_visuals()
				return true
	return false

func _handle_color_mixing(c_name: String) -> void:
	if c_name in ["blue", "red", "yellow"]:
		active_colors.erase("white"); active_colors.erase("black")
		active_colors[c_name] = true
	elif c_name in ["black", "white"]:
		active_colors.clear()
		active_colors[c_name] = true

func _update_brush_visuals() -> void:
	var length: int = active_colors.size()
	if length == 0:
		is_brush_active = false
		if brush_head: brush_head.visible = false
		return

	var r: float = 0.0; var g: float = 0.0; var b: float = 0.0
	for c in active_colors.keys():
		r += COLOR_DICT[c].r
		g += COLOR_DICT[c].g
		b += COLOR_DICT[c].b

	current_color = Color(r / length, g / length, b / length, 1.0)
	is_brush_active = true
	if brush_head:
		brush_head.visible = true
		brush_head.self_modulate = current_color
