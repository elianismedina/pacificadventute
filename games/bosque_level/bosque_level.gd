extends Control

enum State { IDLE, WATCHING, PLAYING }

const MAX_ROUNDS := 4
const HIGHLIGHT_ON := 0.5
const HIGHLIGHT_OFF := 0.6
const NOTE_GAP := 0.5

# C4 major scale — bar heights are proportional (longer bar = lower pitch, like a real marimba)
const NOTE_FREQUENCIES := [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25]
const BAR_HEIGHTS      := [400,    356,    318,    300,    267,    238,    212,    200   ]

const BAR_WIDTH := 90
const BAR_SEP   := 15

const BAR_COLORS := [
	Color(0.95, 0.12, 0.12),  # red    — C4
	Color(0.98, 0.50, 0.05),  # orange — D4
	Color(0.95, 0.85, 0.05),  # yellow — E4
	Color(0.55, 0.88, 0.10),  # lime   — F4
	Color(0.08, 0.72, 0.15),  # green  — G4
	Color(0.05, 0.75, 0.88),  # cyan   — A4
	Color(0.12, 0.30, 0.92),  # blue   — B4
	Color(0.62, 0.08, 0.92),  # purple — C5
]

var _pattern: Array = []
var _player_index: int = 0
var _current_round: int = 0
var _state: State = State.IDLE
var _bars: Array = []
var _note_players: Array = []
var _status_label: Label = null

func _ready() -> void:
	_note_players = [
		$AudioPlayers/Note1, $AudioPlayers/Note2, $AudioPlayers/Note3,
		$AudioPlayers/Note4, $AudioPlayers/Note5, $AudioPlayers/Note6,
		$AudioPlayers/Note7, $AudioPlayers/Note8,
	]
	for i in _note_players.size():
		if _note_players[i].stream == null:
			_note_players[i].stream = _generate_tone(NOTE_FREQUENCIES[i])
	_create_status_label()
	_create_marimba()
	_set_bars_disabled(true)
	await get_tree().create_timer(1.5).timeout
	_start_round()

func _create_status_label() -> void:
	var vp_size := get_viewport_rect().size
	_status_label = Label.new()
	_status_label.position = Vector2(0.0, 30.0)
	_status_label.size = Vector2(vp_size.x, 80.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 52)
	_status_label.modulate = Color.WHITE
	$UI_Layer.add_child(_status_label)

func _create_marimba() -> void:
	var vp_size := get_viewport_rect().size
	var n := BAR_COLORS.size()
	var total_w := n * BAR_WIDTH + (n - 1) * BAR_SEP
	var max_h := BAR_HEIGHTS[0]

	# Plain Control so we can position bars manually (bottom-aligned, varying heights)
	var container := Control.new()
	container.custom_minimum_size = Vector2(float(total_w), float(max_h))
	container.size = Vector2(float(total_w), float(max_h))
	container.position = Vector2(
		(vp_size.x - float(total_w)) / 2.0,
		(vp_size.y - float(max_h)) / 2.0 + 50.0
	)
	add_child(container)

	for i in n:
		var bar_h: int = BAR_HEIGHTS[i]
		var bar := Button.new()
		bar.custom_minimum_size = Vector2(float(BAR_WIDTH), float(bar_h))
		bar.size = Vector2(float(BAR_WIDTH), float(bar_h))
		# Bottom-align: top = max_h - this bar's height
		bar.position = Vector2(float(i * (BAR_WIDTH + BAR_SEP)), float(max_h - bar_h))
		_apply_bar_style(bar, BAR_COLORS[i])
		bar.pressed.connect(_on_bar_pressed.bind(i))
		_bars.append(bar)
		container.add_child(bar)

func _apply_bar_style(bar: Button, color: Color) -> void:
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var s := StyleBoxFlat.new()
		s.corner_radius_bottom_left = 12
		s.corner_radius_bottom_right = 12
		s.corner_radius_top_left = 5
		s.corner_radius_top_right = 5
		match state_name:
			"normal":
				s.bg_color = color
			"hover":
				s.bg_color = color.lightened(0.25)
			"pressed":
				s.bg_color = color.darkened(0.2)
			"disabled":
				s.bg_color = color.darkened(0.45)
			"focus":
				s.bg_color = color
				s.border_color = Color.WHITE
				s.set_border_width_all(3)
		bar.add_theme_stylebox_override(state_name, s)

func _start_round() -> void:
	_current_round += 1
	_pattern.append(randi() % BAR_COLORS.size())
	_state = State.WATCHING
	_status_label.text = "¡Mira y escucha!"
	_set_bars_disabled(true)
	await get_tree().create_timer(0.5).timeout
	for idx in _pattern:
		await _play_bar(idx)
		await get_tree().create_timer(NOTE_GAP).timeout
	_state = State.PLAYING
	_player_index = 0
	_status_label.text = "¡Tu turno!"
	_set_bars_disabled(false)

func _generate_tone(frequency: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 1.5
	var attack := 0.01
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = sample_rate
	var frames := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(sample_rate)
		var env: float = (t / attack) if t < attack else exp(-4.0 * (t - attack) / duration)
		var s := sin(TAU * frequency * t) * 0.65
		s += sin(TAU * frequency * 2.0 * t) * 0.25
		s += sin(TAU * frequency * 3.0 * t) * 0.10
		var sample := clampi(int(s * env * 28000), -32768, 32767)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	stream.data = data
	return stream

func _play_bar(index: int) -> void:
	_note_players[index].play()
	var bar: Button = _bars[index]
	var tween := create_tween()
	tween.tween_property(bar, "modulate", Color(2.2, 2.2, 2.2, 1.0), HIGHLIGHT_ON)
	tween.tween_property(bar, "modulate", Color(1.0, 1.0, 1.0, 1.0), HIGHLIGHT_OFF)
	await tween.finished

func _on_bar_pressed(index: int) -> void:
	if _state != State.PLAYING:
		return
	_play_bar(index)  # fire-and-forget: highlight + sound without blocking
	if index != _pattern[_player_index]:
		_game_over()
		return
	_player_index += 1
	if _player_index == _pattern.size():
		_set_bars_disabled(true)
		_state = State.IDLE
		if _current_round >= MAX_ROUNDS:
			_status_label.text = "¡Lo lograste!"
			await get_tree().create_timer(1.2).timeout
			_show_overlay(true)
		else:
			_status_label.text = "¡Muy bien!"
			await get_tree().create_timer(2.0).timeout
			_start_round()

func _game_over() -> void:
	_state = State.IDLE
	_set_bars_disabled(true)
	_status_label.text = "¡Inténtalo de nuevo!"
	await get_tree().create_timer(1.0).timeout
	_show_overlay(false)

func _set_bars_disabled(disabled: bool) -> void:
	for bar in _bars:
		(bar as Button).disabled = disabled

func _show_overlay(won: bool) -> void:
	var vp_size := get_viewport_rect().size

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.7)
	overlay.position = Vector2.ZERO
	overlay.size = vp_size
	overlay.z_index = 100
	add_child(overlay)

	var center := CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = vp_size
	overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "¡Felicidades!" if won else "¡Oops!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	title.modulate = Color(1.0, 0.88, 0.1) if won else Color(1.0, 0.45, 0.45)
	vbox.add_child(title)

	var btn := Button.new()
	btn.text = "¡Volver!" if won else "Reintentar"
	btn.custom_minimum_size = Vector2(280, 70)
	btn.add_theme_font_size_override("font_size", 32)
	if won:
		btn.pressed.connect(func() -> void: GameLoader.load_scene("res://scenes/levels_map.tscn"))
	else:
		btn.pressed.connect(func() -> void: get_tree().reload_current_scene())
	vbox.add_child(btn)
