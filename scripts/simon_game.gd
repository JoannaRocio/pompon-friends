extends MiniGameBase
## Minijuego "Simón Dice": repite la secuencia de colores. Maximo 6 rondas.

const ROUNDS := 6
const COLORS := [Color("ff6b7a"), Color("5bb8f5"), Color("5fd48a"), Color("ffd24d")]
const DIM := 0.45

var _sequence: Array[int] = []
var _input_index := 0
var _accepting := false
var _finished := false
var _rounds_done := 0

var _status: Label
var _buttons: Array[Button] = []


func _ready() -> void:
	game_id = "simon"
	_build_chrome(Color("efe6ff"), ROUNDS)
	var chip := PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.95), 34, Color.WHITE, 3, 8))
	content.add_child(chip)
	_status = _label("", 40, Color("7a56c4"))
	_status.custom_minimum_size = Vector2(300, 0)
	chip.add_child(_status)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	content.add_child(grid)
	for i in 4:
		var b := Button.new()
		b.custom_minimum_size = Vector2(310, 310)
		b.set_meta("silent", true)  # cada color suena con su propia nota
		b.focus_mode = Control.FOCUS_NONE
		_set_button_color(b, COLORS[i], DIM)
		b.pressed.connect(_on_color_pressed.bind(i))
		grid.add_child(b)
		_buttons.append(b)

	await get_tree().create_timer(0.6).timeout
	_next_round()


func _set_button_color(b: Button, c: Color, brightness: float) -> void:
	var sb := StyleBoxFlat.new()
	var lit := brightness >= 1.0
	# En reposo: version pastel suave; al iluminarse: el color pleno con un aro blanco.
	sb.bg_color = c if lit else c.lerp(Color("fff1e6"), 0.55)
	sb.set_corner_radius_all(64)
	sb.set_border_width_all(10)
	sb.border_color = Color.WHITE
	sb.shadow_color = Color(c.darkened(0.4), 0.5 if lit else 0.25)
	sb.shadow_size = 18 if lit else 6
	sb.shadow_offset = Vector2(0, 6)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, sb)


func _flash(i: int, seconds := 0.45) -> void:
	Audio.play("simon%d" % i)
	_set_button_color(_buttons[i], COLORS[i], 1.0)
	await get_tree().create_timer(seconds).timeout
	_set_button_color(_buttons[i], COLORS[i], DIM)
	await get_tree().create_timer(0.15).timeout


func _next_round() -> void:
	if _finished:
		return
	if _sequence.size() >= ROUNDS:
		_end(T.s("¡Muy bien!"))
		return
	_sequence.append(randi() % 4)
	_input_index = 0
	_accepting = false
	_status.text = T.s("¡Mira!")
	for i in _sequence:
		await _flash(i)
		if not is_inside_tree():
			return
	_accepting = true
	_status.text = T.s("¡Tu turno!")


func _on_color_pressed(i: int) -> void:
	if not _accepting or _finished:
		return
	_flash(i, 0.2)
	if i != _sequence[_input_index]:
		_accepting = false
		_end(T.s("¡Casi!"))
		return
	_input_index += 1
	if _input_index == _sequence.size():
		_accepting = false
		_rounds_done += 1
		_mark(true)
		await get_tree().create_timer(0.5).timeout
		_next_round()


func _end(message: String) -> void:
	if _finished:
		return
	_finished = true
	_ended = true
	_status.text = message
	await get_tree().create_timer(0.5).timeout
	if is_inside_tree():
		_show_result(message, _rounds_done, ROUNDS)
