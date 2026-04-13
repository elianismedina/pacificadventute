extends Control

@export var board_size: int = 4
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
		if str(tile.number) == str(value):
			return tile
	return null

# testing
func _ready():
	randomize()
	if get_size().x > 0:
		tile_size = floor(get_size().x / board_size)
	
	if tile_size <= 0:
		tile_size = 80
		
	set_size(Vector2(tile_size * board_size, tile_size * board_size))
	gen_board()

func _on_Tile_pressed(number: int):
	if is_animating:
		return

	if game_state == GAME_STATES.NOT_STARTED:
		scramble_board()
		game_state = GAME_STATES.STARTED
		game_started.emit()
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
	var temp_flat_board = []
	for i in range(1, board_size * board_size):
		temp_flat_board.append(i)
	temp_flat_board.append(0)

	temp_flat_board.shuffle()
	while not is_board_solvable(temp_flat_board) or is_board_solved_flat(temp_flat_board):
		temp_flat_board.shuffle()

	for r in range(board_size):
		for c in range(board_size):
			board[r][c] = temp_flat_board[r * board_size + c]
			if board[r][c] != 0:
				set_tile_position(r, c, board[r][c])
	empty = value_to_grid(0)
	reset_move_count()

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
	if Input.is_action_just_pressed("ui_left"):
		dir.x = -1
	elif Input.is_action_just_pressed("ui_right"):
		dir.x = 1
	elif Input.is_action_just_pressed("ui_up"):
		dir.y = -1
	elif Input.is_action_just_pressed("ui_down"):
		dir.y = 1
	
	if dir != Vector2.ZERO:
		empty = value_to_grid(0)
		var nr = int(empty.y + dir.y)
		var nc = int(empty.x + dir.x)
		
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
	tile_size = floor(get_size().x / board_size)
	if tile_size <= 0: tile_size = 80
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
