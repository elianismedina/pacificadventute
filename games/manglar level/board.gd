extends Control

@export var board_size: int = 3
@export var tile_size: int = 80
@export var tile_scene: PackedScene
@export var slide_duration: float = 0.15

var board = []
var tiles = []
var empty = Vector2()
var is_animating = false
var tiles_animating = 0

var move_count = 0
var number_visible = true
var background_texture = null
var _settings_panel = null
var _victory_overlay = null

enum GAME_STATES {
	NOT_STARTED,
	STARTED,
	WON
}
var game_state = GAME_STATES.NOT_STARTED

signal game_started
signal game_won
signal moves_updated(move_count: int)

func gen_board():
	var value = 1
	board = []
	for r in range(board_size):
		board.append([])
		for c in range(board_size):

			# choose which is empty cell
			if (value == board_size*board_size):
				board[r].append(0)
				empty = Vector2(c, r)
			else:
				board[r].append(value)

				# generate a new tile
				var tile = tile_scene.instantiate()
				tile.set_position(Vector2(c * tile_size, r * tile_size))
				tile.set_text(value)
				if background_texture:
					tile.set_sprite_texture(background_texture)
				tile.set_sprite(value-1, board_size, tile_size)
				tile.set_number_visible(number_visible)
				tile.tile_pressed.connect(_on_Tile_pressed)
				tile.slide_completed.connect(_on_Tile_slide_completed)
				add_child(tile)
				tiles.append(tile)

			value += 1

func is_board_solved():
	var count = 1
	for r in range(board_size):
		for c in range(board_size):
			if (board[r][c] != count):
				if r == c and c == board_size - 1 and board[r][c] == 0:
					return true
				else:
					return false
			count += 1
	return true

func print_board():
	print('------board------')
	for r in range(board_size):
		var row = ''
		for c in range(board_size):
			row += str(board[r][c]).pad_zeros(2) + ' '
		print(row)

func value_to_grid(value):
	for r in range(board_size):
		for c in range(board_size):
			if (board[r][c] == value):
				return Vector2(c, r)
	return null

func get_tile_by_value(value):
	for tile in tiles:
		if tile.number == value:
			return tile
	return null

# testing
func _ready() -> void:
	randomize()
	var viewport_size: Vector2 = get_viewport_rect().size
	# To fit in a 1600x900 screen, we use the smaller dimension (900)
	# and leave a small margin (90% of screen height)
	var max_board_dim: float = minf(viewport_size.x, viewport_size.y) * 0.9
	tile_size = int(max_board_dim / board_size)
	
	if tile_size <= 0:
		tile_size = 180 # Fallback for 900px height with 4x4 board
		
	# Update the board size to fit the tiles exactly
	# Center alignment is now handled by anchors in board.tscn
	custom_minimum_size = Vector2(tile_size * board_size, tile_size * board_size)
	size = custom_minimum_size
	
	# This ensures the board stays centered even if we change its size in code
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	gen_board()
	scramble_board()
	print("Board scrambled on start")
	print_board()
	game_state = GAME_STATES.STARTED
	game_started.emit()
	_create_settings_ui()
	_create_victory_overlay()
	game_won.connect(_show_victory_overlay)
	game_started.connect(_hide_victory_overlay)

func _on_Tile_pressed(number: int):
	if is_animating:
		return

	if game_state == GAME_STATES.WON:
		reset_move_count()
		scramble_board()
		game_state = GAME_STATES.STARTED
		game_started.emit()
		return

	var tile_pos = value_to_grid(number)
	var empty_pos = value_to_grid(0)

	if tile_pos == null or empty_pos == null:
		return

	if (tile_pos.x != empty_pos.x and tile_pos.y != empty_pos.y):
		return

	$TileMoveSound.play()
	var dir = (empty_pos - tile_pos).normalized()
	var move_steps = int(round(tile_pos.distance_to(empty_pos)))
	
	for i in range(1, move_steps + 1):
		var curr_p = empty_pos - dir * i
		var val = board[int(curr_p.y)][int(curr_p.x)]
		var tile_node = get_tile_by_value(val)
		if tile_node:
			var target_pos = (curr_p + dir) * tile_size
			tile_node.slide_to(target_pos, slide_duration)
			is_animating = true
			tiles_animating += 1

	var temp_curr = empty_pos
	for i in range(move_steps):
		var prev = temp_curr - dir
		board[int(temp_curr.y)][int(temp_curr.x)] = board[int(prev.y)][int(prev.x)]
		temp_curr = prev
	board[int(tile_pos.y)][int(tile_pos.x)] = 0
	empty = tile_pos

	move_count += 1
	moves_updated.emit(move_count)

	if is_board_solved():
		game_state = GAME_STATES.WON
		game_won.emit()

func is_board_solvable(flat):
	var parity = 0
	var grid_width = board_size
	var row = 0
	var blank_row = 0
	for i in range(board_size*board_size):
		if i % grid_width == 0:
			row += 1

		if flat[i] == 0:
			blank_row = row
			continue

		for j in range(i+1, board_size*board_size):
			if flat[i] > flat[j] and flat[j] != 0:
				parity += 1

	if grid_width % 2 != 0:
		return parity % 2 == 0
	else:
		var row_from_bottom = grid_width - blank_row + 1
		if row_from_bottom % 2 == 0:
			return parity % 2 != 0
		else:
			return parity % 2 == 0

func scramble_board():
	print("Scrambling board...")
	var temp_flat_board = []
	for i in range(1, board_size * board_size):
		temp_flat_board.append(i)
	temp_flat_board.append(0)

	var attempts = 0
	while attempts < 1000:
		temp_flat_board.shuffle()
		if is_board_solvable(temp_flat_board) and not is_board_solved_flat(temp_flat_board):
			break
		attempts += 1
	
	print("Scrambled layout: ", temp_flat_board)

	for r in range(board_size):
		for c in range(board_size):
			var val = temp_flat_board[r * board_size + c]
			board[r][c] = val
			if val != 0:
				set_tile_position(r, c, val)
	
	empty = value_to_grid(0)
	reset_move_count()
	print("Board scrambled. Empty at: ", empty)

func is_board_solved_flat(flat):
	for i in range(flat.size() - 1):
		if flat[i] != i + 1:
			return false
	return flat[flat.size() - 1] == 0

func reset_board():
	reset_move_count()
	board = []
	for r in range(board_size):
		board.append([])
		for c in range(board_size):
			var val = r * board_size + c + 1
			if val == board_size * board_size:
				board[r].append(0)
			else:
				board[r].append(val)
				set_tile_position(r, c, val)
	empty = value_to_grid(0)

func set_tile_position(r: int, c: int, val: int):
	var object = get_tile_by_value(val)
	if object:
		object.set_position(Vector2(c, r) * tile_size)

func _process(_delta):
	if is_animating or game_state == GAME_STATES.WON:
		return
		
	var dir = Vector2.ZERO
	if Input.is_action_just_pressed("move_left"):
		dir.x = -1 # Move hole left -> move tile from the left
	elif Input.is_action_just_pressed("move_right"):
		dir.x = 1
	elif Input.is_action_just_pressed("move_up"):
		dir.y = -1
	elif Input.is_action_just_pressed("move_down"):
		dir.y = 1
	
	if dir != Vector2.ZERO:
		var empty_p = value_to_grid(0)
		var nr = int(empty_p.y + dir.y)
		var nc = int(empty_p.x + dir.x)
		
		if nr >= 0 and nr < board_size and nc >= 0 and nc < board_size:
			_on_Tile_pressed(board[nr][nc])

func _on_Tile_slide_completed(_number):
	tiles_animating -= 1
	if tiles_animating <= 0:
		tiles_animating = 0
		is_animating = false

func reset_move_count():
	move_count = 0
	moves_updated.emit(move_count)

func set_tile_numbers(state):
	number_visible = state
	for tile in tiles:
		tile.set_number_visible(state)

func update_size(new_size):
	board_size = int(new_size)
	var viewport_size: Vector2 = get_viewport_rect().size
	var max_board_dim: float = minf(viewport_size.x, viewport_size.y) * 0.9
	tile_size = int(max_board_dim / board_size)
	if tile_size <= 0:
		tile_size = 180
	custom_minimum_size = Vector2(tile_size * board_size, tile_size * board_size)
	size = custom_minimum_size
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	for tile in tiles:
		tile.queue_free()
	tiles = []
	gen_board()
	game_state = GAME_STATES.NOT_STARTED
	reset_move_count()

func update_background_texture(texture):
	background_texture = texture
	for tile in tiles:
		tile.set_sprite_texture(texture)
		tile.update_size(board_size, tile_size)

func _create_settings_ui() -> void:
	var ui_layer = $UI_Layer
	var vp_size = get_viewport_rect().size

	var settings_btn = Button.new()
	settings_btn.text = "Tamaño del tablero"
	settings_btn.position = Vector2(vp_size.x - 180.0, 20.0)
	settings_btn.size = Vector2(160.0, 40.0)
	settings_btn.pressed.connect(_on_settings_pressed)
	ui_layer.add_child(settings_btn)

	_settings_panel = PanelContainer.new()
	_settings_panel.position = Vector2(vp_size.x - 180.0, 70.0)
	_settings_panel.visible = false
	ui_layer.add_child(_settings_panel)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(160.0, 0.0)
	vbox.add_theme_constant_override("separation", 8)
	_settings_panel.add_child(vbox)

	var label = Label.new()
	label.text = "Tamaño del tablero"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	for size_val in [3, 4, 5]:
		var btn = Button.new()
		btn.text = "%d x %d" % [size_val, size_val]
		btn.disabled = (size_val == board_size)
		btn.pressed.connect(_on_size_selected.bind(size_val))
		vbox.add_child(btn)

func _on_settings_pressed() -> void:
	if _settings_panel:
		_settings_panel.visible = not _settings_panel.visible

func _on_size_selected(new_size: int) -> void:
	if _settings_panel:
		_settings_panel.visible = false
	if new_size == board_size:
		return
	update_size(new_size)
	scramble_board()
	game_state = GAME_STATES.STARTED
	game_started.emit()
	_update_size_buttons()

func _update_size_buttons() -> void:
	if _settings_panel == null:
		return
	var vbox = _settings_panel.get_child(0)
	var sizes = [3, 4, 5]
	for i in range(sizes.size()):
		var btn = vbox.get_child(i + 1)
		if btn is Button:
			btn.disabled = (sizes[i] == board_size)

func _create_victory_overlay() -> void:
	var ui_layer = $UI_Layer
	var vp_size = get_viewport_rect().size

	_victory_overlay = ColorRect.new()
	_victory_overlay.color = Color(0.0, 0.0, 0.0, 0.65)
	_victory_overlay.position = Vector2.ZERO
	_victory_overlay.size = vp_size
	_victory_overlay.visible = false
	ui_layer.add_child(_victory_overlay)

	var center = CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = vp_size
	_victory_overlay.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 32)
	center.add_child(vbox)

	var title = Label.new()
	title.text = "¡Lo lograste!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	title.modulate = Color(1.0, 0.88, 0.1)
	vbox.add_child(title)

	var play_again_btn = Button.new()
	play_again_btn.text = "Jugar de nuevo"
	play_again_btn.custom_minimum_size = Vector2(260, 64)
	play_again_btn.add_theme_font_size_override("font_size", 28)
	play_again_btn.pressed.connect(_on_play_again_pressed)
	vbox.add_child(play_again_btn)

func _show_victory_overlay() -> void:
	if _victory_overlay:
		_victory_overlay.visible = true

func _hide_victory_overlay() -> void:
	if _victory_overlay:
		_victory_overlay.visible = false

func _on_play_again_pressed() -> void:
	scramble_board()
	game_state = GAME_STATES.STARTED
	game_started.emit()
