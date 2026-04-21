extends TextureButton

var number: int

signal tile_pressed(number: int)
signal slide_completed(number: int)

func _ready() -> void:
	# TextureButton has a "pressed" signal. Let's connect it to our internal handler.
	if not pressed.is_connected(_on_tile_pressed):
		pressed.connect(_on_tile_pressed)

# Update the number of the tile
func set_text(new_number: int) -> void:
	number = new_number
	$Number/Label.text = str(number)

var is_moving: bool = false

# Update the background image of the tile
func set_sprite(new_frame: int, grid_size: int, tile_size: float) -> void:
	var sprite: Sprite2D = $Sprite2D
	
	update_size(grid_size, tile_size)
	
	sprite.set_hframes(grid_size)
	sprite.set_vframes(grid_size)
	sprite.set_frame(new_frame)

# scale to the new tile_size
func update_size(grid_size: int, tile_size: float) -> void:
	var new_size = Vector2(tile_size, tile_size)
	size = new_size # Set control size
	
	$Number.set_size(new_size)
	$Number/ColorRect.set_size(new_size)
	$Number/Label.set_size(new_size)
	$Border.set_size(new_size)

	var sprite: Sprite2D = $Sprite2D
	if sprite.texture:
		var tex_size = sprite.texture.get_size()
		# scale = (grid_size * tile_size) / tex_size
		var target_full_size = Vector2(grid_size, grid_size) * tile_size
		var to_scale = target_full_size / tex_size
		sprite.set_scale(to_scale)
		# Ensure the sprite is centered
		sprite.position = new_size / 2.0

# Update the entire background image
func set_sprite_texture(texture: Texture2D) -> void:
	$Sprite2D.set_texture(texture)

# Slide the tile to a new position
func slide_to(new_position: Vector2, duration: float) -> void:
	if is_moving:
		return
		
	is_moving = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", new_position, duration)
	tween.finished.connect(func(): 
		is_moving = false
		slide_completed.emit(number)
	, CONNECT_ONE_SHOT)

# Hide / Show the number of the tile
func set_number_visible(state: bool) -> void:
	$Number.visible = state

# Tile is pressed
func _on_tile_pressed() -> void:
	tile_pressed.emit(number)
