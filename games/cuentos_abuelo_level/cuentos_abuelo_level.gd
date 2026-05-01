extends Control

enum StoryState { INTRO, MEET_PACHO, PACHO_SAD, CLEANING, FINISHED }

@onready var background = $Background
@onready var pacho = $Characters/Pacho
@onready var abuelo_vo = $AudioPlayers/AbueloVO
@onready var ad_player = $AudioPlayers/ADPlayer
@onready var music_player = $AudioPlayers/MusicPlayer
@onready var sfx_player = $AudioPlayers/SFXPlayer
@onready var subtitle_label = $UI/Subtitles
@onready var ad_button = $UI/Controls/ADButton
@onready var next_button = $UI/Controls/NextButton
@onready var close_button = $UI/Controls/CloseButton
@onready var trash_container = $TrashContainer

var _ad_enabled: bool = true
var _current_state: StoryState = StoryState.INTRO
var _bottles_collected: int = 0
var _total_bottles: int = 0

func _ready() -> void:
	_setup_ui()
	_play_intro()

func _setup_ui() -> void:
	subtitle_label.text = ""
	ad_button.pressed.connect(_toggle_ad)
	next_button.pressed.connect(_on_next_pressed)
	next_button.hide()
	
	if pacho:
		pacho.modulate.a = 0
		pacho.pressed.connect(_on_pacho_pressed)
	
	if trash_container:
		_total_bottles = 0
		for bottle in trash_container.get_children():
			if bottle is TextureButton:
				_total_bottles += 1
				bottle.pressed.connect(_on_bottle_pressed.bind(bottle))

func _on_pacho_pressed() -> void:
	if pacho.modulate.a < 0.5: return
	
	match _current_state:
		StoryState.INTRO:
			var interaction_text = "Pacho está muy triste para hablar ahora..."
			_show_dialogue(interaction_text, "")
		StoryState.MEET_PACHO:
			_advance_to_pacho_sad()
	
	# Common feedback animation
	var tween = create_tween()
	tween.tween_property(pacho, "scale", Vector2(0.55, 0.55), 0.1)
	tween.tween_property(pacho, "scale", Vector2(0.5, 0.5), 0.1)

func _toggle_ad() -> void:
	_ad_enabled = !_ad_enabled
	ad_button.text = "AD: ON" if _ad_enabled else "AD: OFF"
	# If AD is currently playing and disabled, stop it
	if !_ad_enabled and ad_player.playing:
		ad_player.stop()

func _play_intro() -> void:
	_current_state = StoryState.INTRO
	
	# Background sounds
	if music_player:
		music_player.play()
	
	# Start Dialogue
	var dialogue = "¡Acércate, pequeño explorador! ¿Ves esas raíces que parecen dedos largos hundidos en el lodo? Es el manglar, el guardián de nuestra costa. Hoy, el manglar está en silencio... algo le pasa a Pacho, el cangrejo azul."
	
	_show_dialogue(dialogue, "res://assets/sounds/vo_abuelo_intro.mp3")
	
	await abuelo_vo.finished
	
	# Audio Description
	if _ad_enabled:
		var ad_text = "Aparece un cangrejo azul brillante sentado sobre una raíz. Tiene sus tenazas caídas y una expresión triste."
		_play_ad(ad_text, "res://assets/sounds/ad_abuelo_intro.mp3")
		await ad_player.finished
	
	_show_pacho()
	next_button.show()

func _show_dialogue(text: String, audio_path: String) -> void:
	print("Intentando mostrar diálogo: ", text, " con audio: ", audio_path)
	subtitle_label.text = text
	
	if abuelo_vo.playing:
		abuelo_vo.stop()
		
	if audio_path != "" and FileAccess.file_exists(audio_path):
		var stream = load(audio_path)
		if stream:
			abuelo_vo.stream = stream
			abuelo_vo.play()
			print("Audio cargado y reproduciendo: ", audio_path)
		else:
			print("ERROR: No se pudo cargar el stream de audio: ", audio_path)
			_fallback_subtitle_animation()
	else:
		if audio_path != "":
			print("AVISO: El archivo de audio no existe: ", audio_path)
		_fallback_subtitle_animation()

func _fallback_subtitle_animation() -> void:
	var tween = create_tween()
	subtitle_label.visible_ratio = 0
	tween.tween_property(subtitle_label, "visible_ratio", 1.0, 3.0)
	await tween.finished
	# Emitimos una señal manual o esperamos un tiempo para simular que terminó el audio
	await get_tree().create_timer(1.0).timeout

func _play_ad(text: String, audio_path: String) -> void:
	print("Reproduciendo AD: ", text)
	if ad_player.playing:
		ad_player.stop()
		
	if FileAccess.file_exists(audio_path):
		ad_player.stream = load(audio_path)
		ad_player.play()
	else:
		print("AVISO: No se encontró audio de AD: ", audio_path)
		await get_tree().create_timer(2.0).timeout

func _show_pacho() -> void:
	if pacho:
		var tween = create_tween()
		tween.tween_property(pacho, "modulate:a", 1.0, 1.5)
		# Add a subtle "sad" animation if possible
		_animate_pacho_sad()

func _animate_pacho_sad() -> void:
	if pacho:
		var tween = create_tween().set_loops()
		tween.tween_property(pacho, "position:y", pacho.position.y + 5, 2.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(pacho, "position:y", pacho.position.y, 2.0).set_trans(Tween.TRANS_SINE)

func _on_next_pressed() -> void:
	# Advance to next scene logic
	match _current_state:
		StoryState.INTRO:
			_advance_to_meet_pacho()
		# Add more cases as needed

func _advance_to_meet_pacho() -> void:
	_current_state = StoryState.MEET_PACHO
	next_button.hide()
	
	var dialogue = "Pacho no suele estar así de callado. Normalmente es el más bromista del manglar. ¡Intenta saludarlo tocándolo con cuidado! Quizás así nos cuente qué le preocupa."
	_show_dialogue(dialogue, "res://assets/sounds/vo_abuelo_pregunta.mp3")
	
	await abuelo_vo.finished
	
	if _ad_enabled:
		var ad_text = "Pacho permanece inmóvil. El botón de interacción sobre él parpadea suavemente."
		_play_ad(ad_text, "res://assets/sounds/ad_pacho_espera.mp3")
		await ad_player.finished
	
	# Highlight Pacho to encourage interaction
	var tween = create_tween().set_loops()
	tween.tween_property(pacho, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.8)
	tween.tween_property(pacho, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.8)

func _advance_to_pacho_sad() -> void:
	# Stop the highlight tween
	var tween_stop = create_tween()
	tween_stop.tween_property(pacho, "modulate", Color.WHITE, 0.2)
	
	_current_state = StoryState.PACHO_SAD
	
	# Move subtitles to top to avoid blocking trash
	_move_subtitles_to_top()
	
	# Show trash
	_show_trash()
	
	# Here Pacho starts explaining his problem
	var dialogue = "Pacho dice que el agua está muy sucia hoy... ¡Mira cuántas botellas han llegado con la marea!"
	_show_dialogue(dialogue, "res://assets/sounds/vo_abuelo_problema.mp3")
	
	await abuelo_vo.finished
	
	# After revealing problem, give cleaning instructions
	_start_cleaning_phase()

func _move_subtitles_to_top() -> void:
	var tween = create_tween()
	# Move to top anchors (Top Wide)
	tween.tween_property(subtitle_label, "anchor_top", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(subtitle_label, "anchor_bottom", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	# Adjust offsets for the top position
	tween.parallel().tween_property(subtitle_label, "offset_top", 50.0, 0.5).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(subtitle_label, "offset_bottom", 150.0, 0.5).set_trans(Tween.TRANS_SINE)

func _start_cleaning_phase() -> void:
	# Start cleaning instructions
	_current_state = StoryState.CLEANING
	var cleaning_dialogue = "¡Esto es terrible! ¿Nos ayudarías a limpiar el manglar? Si tocas cada botella, las recogeremos."
	_show_dialogue(cleaning_dialogue, "res://assets/sounds/vo_abuelo_limpieza.mp3")
	
	if _ad_enabled:
		await abuelo_vo.finished
		_play_ad("Diez botellas de plástico flotan en el agua. El jugador debe tocarlas.", "res://assets/sounds/ad_limpieza_instruccion.mp3")

func _on_bottle_pressed(bottle: TextureButton) -> void:
	if _current_state != StoryState.CLEANING: return
	
	_bottles_collected += 1
	bottle.disabled = true
	
	# Collect animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(bottle, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(bottle, "modulate:a", 0.0, 0.3)
	
	# Play collect sound
	if FileAccess.file_exists("res://assets/sounds/quick_woosh.mp3"):
		sfx_player.stream = load("res://assets/sounds/quick_woosh.mp3")
		sfx_player.play()
	
	if _bottles_collected == _total_bottles:
		_finish_level()

func _finish_level() -> void:
	_current_state = StoryState.FINISHED
	
	# Play victory sound effect
	if FileAccess.file_exists("res://assets/sounds/success_sound.wav"):
		sfx_player.stream = load("res://assets/sounds/success_sound.wav")
		sfx_player.play()
	
	# Pacho becomes happy (Visual reaction)
	if pacho:
		# Change texture to happy if available
		var happy_tex_path = "res://assets/textures/pacho_happy.png"
		if FileAccess.file_exists(happy_tex_path):
			pacho.texture_normal = load(happy_tex_path)
		
		var tween = create_tween()
		tween.set_loops(3) # Joyful bounce
		tween.tween_property(pacho, "position:y", pacho.position.y - 30, 0.2).set_trans(Tween.TRANS_SINE)
		tween.tween_property(pacho, "position:y", pacho.position.y, 0.2).set_trans(Tween.TRANS_SINE)
		pacho.modulate = Color(1.2, 1.2, 1.2, 1.0) # Brighten up
	
	var final_dialogue = "¡Lo lograste! Mira a Pacho, ¡está tan feliz! El manglar vuelve a estar limpio gracias a ti."
	_show_dialogue(final_dialogue, "res://assets/sounds/vo_abuelo_final.mp3")
	
	await abuelo_vo.finished
	await get_tree().create_timer(1.0).timeout
	next_button.hide()
	close_button.show()

func _show_trash() -> void:
	if trash_container:
		trash_container.show()
		trash_container.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(trash_container, "modulate:a", 1.0, 2.0)
		
		# Animate each bottle floating
		for bottle in trash_container.get_children():
			if bottle is TextureButton:
				_animate_floating(bottle)

func _animate_floating(node: Control) -> void:
	var tween = create_tween().set_loops()
	var random_offset = randf_range(10.0, 20.0)
	var duration = randf_range(2.0, 3.5)
	
	tween.tween_property(node, "position:y", node.position.y + random_offset, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position:y", node.position.y, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Small rotation as well
	var rot_tween = create_tween().set_loops()
	rot_tween.tween_property(node, "rotation_degrees", 5.0, duration * 1.5).set_trans(Tween.TRANS_SINE)
	rot_tween.tween_property(node, "rotation_degrees", -5.0, duration * 1.5).set_trans(Tween.TRANS_SINE)
