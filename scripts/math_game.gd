extends MiniGameBase
## Minijuego "Matemáticas": 5 cuentas con el MISMO nivel que tienes en el trabajo (sumas y restas,
## multiplicaciones y divisiones, cada una en su nivel). Es practica: no cambia el nivel del trabajo.
## Recompensa: monedas, +1 Inteligencia, Diversion y Amor (ver MiniGameBase).

const QUESTIONS := 5

var _asked := 0
var _correct := 0
var _answer := 0
var _locked := false
var _tracks: Array = []
var _recent: Array = []
var _rng := RandomNumberGenerator.new()
var _level_chip_label: Label

var _question_label: Label
var _answer_buttons: Array[Button] = []


func _ready() -> void:
	game_id = "math"
	_rng.randomize()
	_build_chrome(Color("d9f0ff"), QUESTIONS)
	# las secciones del trabajo, mezcladas, cada una con su nivel
	_tracks = MathProblems.TRACKS.duplicate()
	_tracks.shuffle()
	while _tracks.size() < QUESTIONS:
		_tracks.append(MathProblems.TRACKS[_rng.randi() % MathProblems.TRACKS.size()])
	var level_chip := PanelContainer.new()
	level_chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	level_chip.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.95), 30, Color.WHITE, 3, 6))
	content.add_child(level_chip)
	_level_chip_label = _label("", 30, Color("3f66b0"))
	_level_chip_label.custom_minimum_size = Vector2(380, 0)
	level_chip.add_child(_level_chip_label)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.95), 44, Color.WHITE, 4, 12))
	content.add_child(card)
	_question_label = _label("", 118, Color("3f66b0"))
	card.add_child(_question_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	content.add_child(row)
	for i in 3:
		var b := Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 190)
		Hud.style_soft(b, 84)
		b.pressed.connect(_on_answer.bind(b))
		row.add_child(b)
		_answer_buttons.append(b)
	_next_question()


func _next_question() -> void:
	if _asked >= QUESTIONS:
		_finish()
		return
	_locked = false
	_asked += 1
	var track: String = _tracks[_asked - 1]
	var level := GameState.math_level(track)
	var problem := MathProblems.pick_problem(track, level, _rng, [], _recent)
	_recent.append(problem["key"])
	while _recent.size() > 4:
		_recent.pop_front()
	_answer = problem["answer"]
	_question_label.text = "%s = ?" % problem["text"]
	_question_label.add_theme_font_size_override("font_size", 118 if _question_label.text.length() <= 10 else 80)
	_level_chip_label.text = T.s("%s · Nivel %d") % [MathProblems.track_label(track), level]
	var options: Array = problem["options"]
	for i in 3:
		_answer_buttons[i].text = str(options[i])
		_answer_buttons[i].set_meta("value", options[i])
		_answer_buttons[i].self_modulate = Color.WHITE
		_answer_buttons[i].modulate.a = 1.0


func _on_answer(button: Button) -> void:
	if _locked or _ended:
		return
	_locked = true
	var right: bool = button.get_meta("value") == _answer
	for b in _answer_buttons:
		if int(b.get_meta("value")) == _answer:
			b.self_modulate = Color(0.55, 0.9, 0.6)
		elif b == button:
			b.self_modulate = Color(1.0, 0.55, 0.55)
		else:
			b.modulate.a = 0.45
	if right:
		_correct += 1
		Audio.play("coin")
	else:
		Audio.play("fail")
	_mark(right)
	await get_tree().create_timer(0.8).timeout
	if is_inside_tree():
		_next_question()


func _finish() -> void:
	_ended = true
	var title := T.s("¡Muy bien!") if _correct >= 4 else (T.s("¡Bien!") if _correct >= 2 else T.s("¡Sigue practicando!"))
	_show_result(title, _correct, QUESTIONS)
