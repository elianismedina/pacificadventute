extends Control

@export_file("*.tscn") var back_scene_path: String = "res://scenes/levels_map.tscn"
@export var grid_size: int = 4
@export var tile_size: float = 80.0
@export var spacing: float = 2.0
@export var puzzle_texture: Texture2D = preload("res://assets/textures/cangrejoPuzzle.png")

const TILE_SCENE = preload("res://games/manglar level/Tile.tscn")

var tiles: Array = []
var empty_tile_pos: Vector2i = Vector2i(3, 3) # Grid coordinates
var grid: Array = [] # 2D array of tile references

@onready var container = $PuzzleContainer

func _ready() -> void:
	# Calculate total puzzle size
	var total_size = grid_size * tile_size + (grid_size - 1) * spacing
	container.custom_minimum_size = Vector2(total_size, total_size)
	
	# Center the container
	container.position = (get_viewport_rect().size - Vector2(total_size, total_size)) / 2.0
	
	setup_puzzle()

func setup_puzzle() -> void:
	grid = []
	for y in range(grid_size):
		grid.append([])
		for x in range(grid_size):
			grid[y].append(null)
			
	var number = 1
	for y in range(grid_size):
		for x in range(grid_size):
			if x == grid_size - 1 and y == grid_size - 1:
				empty_tile_pos = Vector2i(x, y)
				continue
				
			var tile = TILE_SCENE.instantiate()
			container.add_child(tile)
			
			tile.number = number
			tile.grid_pos = Vector2i(x, y)
			tile.set_sprite(number - 1, grid_size, tile_size)
			tile.set_sprite_texture(puzzle_texture)
			
			# Position in world space
			tile.position = grid_to_world(tile.grid_pos)
			
			# Connect signals
			tile.tile_pressed.connect(_on_tile_pressed)
			
			grid[y][x] = tile
			number += 1
	
	# Shuffle after setup
	shuffle_puzzle()

func grid_to_world(pos: Vector2i) -> Vector2:
	return Vector2(pos.x, pos.y) * (tile_size + spacing)

func _on_tile_pressed(tile_number: int) -> void:
	# Find the tile in the grid
	var tile = null
	var tx = -1
	var ty = -1
	
	for y in range(grid_size):
		for x in range(grid_size):
			if grid[y][x] and grid[y][x].number == tile_number:
				tile = grid[y][x]
				tx = x
				ty = y
				break
		if tile: break
		
	if not tile: return
	
	# Check if empty space is adjacent
	var diff = (Vector2i(tx, ty) - empty_tile_pos).abs()
	if (diff.x == 1 and diff.y == 0) or (diff.x == 0 and diff.y == 1):
		move_tile(tile, tx, ty)

func move_tile(tile, x: int, y: int) -> void:
	var old_pos = Vector2i(x, y)
	var new_pos = empty_tile_pos
	
	# Swap in grid
	grid[new_pos.y][new_pos.x] = tile
	grid[old_pos.y][old_pos.x] = null
	empty_tile_pos = old_pos
	
	# Update tile metadata
	tile.grid_pos = new_pos
	
	# Animate move
	tile.slide_to(grid_to_world(new_pos), 0.2)
	
	# Check win condition
	check_win()

func check_win() -> void:
	var expected_number = 1
	for y in range(grid_size):
		for x in range(grid_size):
			if x == grid_size - 1 and y == grid_size - 1:
				continue
			var tile = grid[y][x]
			if not tile or tile.number != expected_number:
				return
			expected_number += 1
	
	print("Puzzle solved!")
	# Maybe show a victory screen?
	$VictoryLabel.visible = true

func shuffle_puzzle() -> void:
	# Randomly move the empty space multiple times
	var moves = 0
	while moves < 200:
		var neighbors = []
		var x = empty_tile_pos.x
		var y = empty_tile_pos.y
		
		if x > 0: neighbors.append(Vector2i(x - 1, y))
		if x < grid_size - 1: neighbors.append(Vector2i(x + 1, y))
		if y > 0: neighbors.append(Vector2i(x, y - 1))
		if y < grid_size - 1: neighbors.append(Vector2i(x, y + 1))
		
		var target_pos = neighbors.pick_random()
		var tile = grid[target_pos.y][target_pos.x]
		
		# Move silently (no tween)
		grid[empty_tile_pos.y][empty_tile_pos.x] = tile
		grid[target_pos.y][target_pos.x] = null
		tile.grid_pos = empty_tile_pos
		tile.position = grid_to_world(empty_tile_pos)
		empty_tile_pos = target_pos
		
		moves += 1

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(back_scene_path)
