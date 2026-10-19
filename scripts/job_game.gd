extends Control
## Trabajo de profesor/a (matematicas o ingles): un salon de clase con dos alumnos Pompon estudiando.
## Cada tanto un alumno levanta la mano (señal "!"): hay que tocarlo y corregir su examen resolviendo
## la cuenta o eligiendo la palabra en ingles. Mientras tanto, abajo, se ordena (libros, lapices y
## manzanas) en un juego tranquilo.
## La paga es SIEMPRE la misma (se premia intentarlo, no saber). Se mide el acierto y el tiempo de
## cada respuesta para decidir cuando se domina el nivel. Si se falla, se muestra la respuesta.

enum State { INTRO, PLAY, QUESTION, END }

const INK := Color("5b3a4a")
const SYMBOLS := {"addsub": "+ −", "mul": "×", "div": "÷", "en_words": "ABC", "en_meaning": "Hi!", "en_phrases": "I am",
	"geo_capitals": "Mundo", "geo_flags": "Mundo", "geo_mix": "Mundo"}
const SIGNAL_FIRST := 6.0
const SIGNAL_GAP := Vector2(11.0, 15.0)
const EXAM_HINT := 4.0     # segundos con la mano levantada antes de que la flecha señale el examen
const TIP_FIRST_SHIFT := "job_first_shift"   # cartel "¡Perfecto! ya sabes lo basico" (ya visto)
const OPTION_HINT := 8.0   # segundos sin responder antes de que la flecha recorra las respuestas

var camino := "addsub"
var subject := "math"          # "math", "english" o "geography" (ver Jobs.current)
var problems: GDScript = MathProblems
var level := 1
var state := State.INTRO
var rng := RandomNumberGenerator.new()

var questions_done := 0
var correct := 0
var mistakes: Array = []
var answer_times: Array = []   # segundos que tardo en cada respuesta
var exam_ready := false        # un alumno tiene la mano levantada
var time_left := MathProblems.SHIFT_SECONDS
var full_shift := false         # el turno llego a su fin (todos los examenes o se acabo el tiempo)

var classroom: ClassroomView
var sorter: SortField
var _dots: QuestionDots
var _timer_label: Label
var _timer_chip: PanelContainer
var _finish_button: Button
var _toast: Control
var _problem := {}
var _answered := false
var _recent: Array = []        # ultimas cuentas (para no repetir enseguida)
var _q_started := 0            # cuando se mostro la cuenta (ms)
var _signal_t := SIGNAL_FIRST
var _student := 0
var _layer: Control            # ventana abierta (intro, examen o cartel final)
var _arrow: GuideArrow         # ayuda si el jugador no sabe que tocar
var _hand_wait := 0.0          # segundos que el alumno lleva con la mano levantada
var _option_buttons: Array = []
var _steps: Array = []         # carteles que faltan mostrar al terminar el turno


# ------------------------------------------------------------------ piezas del HUD

class QuestionDots extends Control:
	var results: Array = []
	var total := MathProblems.QUESTIONS_PER_SHIFT

	func _draw() -> void:
		var step := minf(size.x / total, size.y * 1.1)
		var r := step * 0.42
		var x0 := (size.x - step * total) * 0.5 + step * 0.5
		for i in total:
			var c := Vector2(x0 + step * i, size.y * 0.5)
			var pts := PackedVector2Array()
			for k in 10:
				var rr := r if k % 2 == 0 else r * 0.46
				var a := -PI / 2.0 + PI * k / 5.0
				pts.append(c + Vector2(cos(a), sin(a)) * rr)
			var col := Color("ece3ea")
			if i < results.size():
				col = Color("ffcf3f") if results[i] else Color("ffb3c8")
			draw_colored_polygon(pts, col)
			pts.append(pts[0])
			draw_polyline(pts, Color("5b3a4a"), 2.5, true)


class StarsRow extends Control:
	var filled := 0
	var total := 10

	func _draw() -> void:
		var step := minf(size.x / total, size.y * 1.2)
		var r := step * 0.46
		var x0 := (size.x - step * total) * 0.5 + step * 0.5
		for i in total:
			var pts := PackedVector2Array()
			for k in 10:
				var rr := r if k % 2 == 0 else r * 0.45
				var a := -PI / 2.0 + PI * k / 5.0
				pts.append(Vector2(x0 + step * i, size.y * 0.5) + Vector2(cos(a), sin(a)) * rr)
			draw_colored_polygon(pts, Color("ffd33d") if i < filled else Color("e6dccd"))
			pts.append(pts[0])
			draw_polyline(pts, Color("5b3a4a"), 2.5, true)


# --------------------------------------------------------------------- preparacion

func _ready() -> void:
	rng.randomize()
	subject = Jobs.current if Jobs.current in Jobs.SUBJECTS else "math"
	problems = Jobs.problems(subject)
	camino = Jobs.current_track(subject)
	level = GameState.math_level(camino)
	_build_ui()
	if GameState.jobs_done == 0:
		_show_intro()
	else:
		_show_lesson_or_play()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("fff4e8")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	classroom = ClassroomView.new()
	classroom.set_anchors_preset(Control.PRESET_FULL_RECT)
	classroom.offset_top = 112
	classroom.offset_bottom = -500
	classroom.board_text = SYMBOLS[camino]
	classroom.exam_tapped.connect(_on_exam_tapped)
	add_child(classroom)

	# zona de ordenar (abajo)
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	card.offset_left = 14
	card.offset_right = -14
	card.offset_top = -490
	card.offset_bottom = -14
	card.add_theme_stylebox_override("panel", Hud.card(Color("fff9ef"), 38, Color.WHITE, 4, 12))
	add_child(card)
	sorter = SortField.new()
	sorter.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sorter.sorted.connect(_on_sorted)
	card.add_child(sorter)

	_arrow = GuideArrow.new()
	add_child(_arrow)

	# barra de arriba: volver, nivel, examenes corregidos y paga
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 14
	top.offset_right = -14
	top.offset_top = 14
	top.add_theme_constant_override("separation", 10)
	add_child(top)
	top.add_child(Hud.back_button(func(): get_tree().change_scene_to_file("res://scenes/job_menu.tscn")))
	var chip := PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.94), 30, Color.WHITE, 3, 6))
	top.add_child(chip)
	var title := Label.new()
	title.text = "Nivel %d" % level
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", INK)
	title.clip_text = true
	chip.add_child(title)
	var dots_card := PanelContainer.new()
	dots_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dots_card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.94), 30, Color.WHITE, 3, 6))
	top.add_child(dots_card)
	_dots = QuestionDots.new()
	_dots.custom_minimum_size = Vector2(170, 34)
	dots_card.add_child(_dots)
	_timer_chip = PanelContainer.new()
	_timer_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_timer_chip.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.94), 30, Color.WHITE, 3, 6))
	top.add_child(_timer_chip)
	var timer_row := HBoxContainer.new()
	timer_row.add_theme_constant_override("separation", 6)
	var clock := Control.new()
	clock.custom_minimum_size = Vector2(30, 30)
	clock.draw.connect(func():
		var c := clock.size * 0.5
		clock.draw_circle(c, 14.0, Color("5b3a4a"))
		clock.draw_circle(c, 11.0, Color("fffaf0"))
		clock.draw_line(c, c + Vector2(0, -8), Color("5b3a4a"), 3.0, true)
		clock.draw_line(c, c + Vector2(6, 2), Color("ff4f86"), 3.0, true))
	timer_row.add_child(clock)
	_timer_label = Label.new()
	_timer_label.add_theme_font_size_override("font_size", 28)
	_timer_label.add_theme_color_override("font_color", INK)
	timer_row.add_child(_timer_label)
	_timer_chip.add_child(timer_row)
	var pay := PanelContainer.new()
	pay.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pay.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.94), 30, Color.WHITE, 3, 6))
	top.add_child(pay)
	var pay_row := HBoxContainer.new()
	pay_row.add_theme_constant_override("separation", 4)
	pay_row.add_child(Hud.coin_icon(30.0))
	var pay_label := Label.new()
	pay_label.text = "+%d" % GameState.job_pay()
	pay_label.add_theme_font_size_override("font_size", 26)
	pay_label.add_theme_color_override("font_color", Color("b87400"))
	pay_row.add_child(pay_label)
	pay.add_child(pay_row)

	# "Terminar y cobrar": aparece al corregir el primer examen (terminar el turno es opcional)
	_finish_button = Button.new()
	_finish_button.text = "Terminar y cobrar +%d" % GameState.job_pay()
	_finish_button.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_finish_button.offset_left = 120
	_finish_button.offset_right = -120
	_finish_button.offset_top = -574
	_finish_button.offset_bottom = -510
	_finish_button.visible = false
	Hud.style_primary(_finish_button, 28, Color("5fc77f"))
	_finish_button.pressed.connect(_on_finish_pressed)
	add_child(_finish_button)


func _make_modal(width := 640.0) -> PanelContainer:
	_close_layer()
	_layer = Control.new()
	_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.25, 0.12, 0.2, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -width * 0.5
	panel.offset_right = width * 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override("panel", Hud.card(Color("fffafc"), 40, Color("ffb3d1"), 6, 16))
	_layer.add_child(panel)
	return panel


func _close_layer() -> void:
	if _layer != null and is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null


func _label(text: String, size: int, align := HORIZONTAL_ALIGNMENT_CENTER, color := INK) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


# ------------------------------------------------------------------ explicacion inicial

func _show_intro() -> void:
	state = State.INTRO
	var panel := _make_modal(660.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_label(Jobs.greeting(GameState.player_title, GameState.player_name), 34, HORIZONTAL_ALIGNMENT_CENTER, Color("d6336c")))
	var demo := IntroDemo.new()
	demo.custom_minimum_size = Vector2(0, 300)
	box.add_child(demo)
	var caps := HBoxContainer.new()
	caps.add_theme_constant_override("separation", 16)
	box.add_child(caps)
	for text in ["Ordena los objetos", "Corrige el examen cuando levanten la mano"]:
		var l := _label(text, 25)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size = Vector2(0, 70)
		caps.add_child(l)
	var go := Button.new()
	go.text = "¡A enseñar!"
	go.custom_minimum_size = Vector2(0, 92)
	Hud.style_primary(go, 40)
	go.pressed.connect(func():
		_close_layer()
		_show_lesson_or_play())
	box.add_child(go)


## Antes de practicar un nivel por primera vez se muestra su leccion (trucos y ejemplos).
func _show_lesson_or_play() -> void:
	if GameState.lesson_seen(camino, level):
		_start_play()
		return
	state = State.INTRO
	var panel := _make_modal(660.0)
	var lesson := LessonView.new()
	lesson.setup(camino, level)
	lesson.closed.connect(func():
		GameState.mark_lesson_seen(camino, level)
		_close_layer()
		_start_play())
	panel.add_child(lesson)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())


func _start_play() -> void:
	state = State.PLAY
	_signal_t = SIGNAL_FIRST


# ------------------------------------------------------------------------ juego

func _process(delta: float) -> void:
	sorter.paused = state != State.PLAY
	if state == State.PLAY:
		time_left = maxf(0.0, time_left - delta)
		if time_left <= 0.0 and questions_done >= 1 and not full_shift:
			full_shift = true  # se acabo el tiempo: el turno termino completo
			classroom.lower_hand()
			exam_ready = false
			_finish(true)
			return
		if not exam_ready and (_signal_t - delta <= 0.0 or (time_left <= 0.0 and questions_done == 0)):
			exam_ready = true
			_student = rng.randi() % 2
			classroom.raise_hand(_student)
		_signal_t -= delta
	_update_hint_arrow(delta)
	_update_timer_label()


## Ayuda: si el alumno espera y no lo tocas, la flecha señala su examen; si en el examen no
## respondes, la flecha pasa por las respuestas (sin decir cual es la correcta).
func _update_hint_arrow(delta: float) -> void:
	_hand_wait = _hand_wait + delta if state == State.PLAY and exam_ready else 0.0
	var targets: Array = []
	if state == State.PLAY and exam_ready and _hand_wait >= EXAM_HINT:
		targets = [classroom.anchor]
	elif state == State.QUESTION and not _answered and _layer != null 			and (Time.get_ticks_msec() - _q_started) / 1000.0 >= OPTION_HINT:
		targets = _option_buttons
	_arrow.set_targets(targets)
	sorter.hint_enabled = targets.is_empty()  # una ayuda por vez: primero el examen
	if not targets.is_empty() and _arrow.get_index() != get_child_count() - 1:
		_arrow.move_to_front()  # encima de la ventana del examen


func _update_timer_label() -> void:
	if _timer_label == null:
		return
	var secs := int(ceil(time_left))
	_timer_label.text = "%d:%02d" % [secs / 60, secs % 60]
	var low := time_left < 10.0 and state == State.PLAY
	_timer_label.add_theme_color_override("font_color", Color("e0295f") if low else INK)
	if low:
		_timer_chip.pivot_offset = _timer_chip.size * 0.5
		var pulse := 1.0 + 0.06 * sin(Time.get_ticks_msec() / 90.0)
		_timer_chip.scale = Vector2(pulse, pulse)
	else:
		_timer_chip.scale = Vector2.ONE


## Cobrar antes de que acabe el turno (solo despues del primer examen): se lleva la paga de siempre.
func _on_finish_pressed() -> void:
	if state != State.PLAY or questions_done < 1:
		return
	exam_ready = false
	classroom.lower_hand()
	_finish(false)


func _show_toast(text: String) -> void:
	if _toast != null and is_instance_valid(_toast):
		_toast.queue_free()
	var chip := Hud.chip(text, Color("d8f5e3"), Color("1f7a4d"), 26)
	chip.set_anchors_preset(Control.PRESET_CENTER_TOP)
	chip.offset_top = 128
	chip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(chip)
	_toast = chip
	var tw := chip.create_tween()
	tw.tween_interval(3.0)
	tw.tween_property(chip, "modulate:a", 0.0, 0.5)
	tw.tween_callback(chip.queue_free)


func _on_sorted(right: bool, _kind: String) -> void:
	if right and sorter.sorted_total % 8 == 0:
		classroom.cheer(3)


func _on_exam_tapped() -> void:
	if state != State.PLAY or not exam_ready:
		return
	exam_ready = false
	classroom.lower_hand()
	_open_question()


# ---------------------------------------------------------------------- el examen (cuenta)

func _open_question() -> void:
	state = State.QUESTION
	_answered = false
	_problem = problems.pick_problem(camino, level, rng, GameState.weak_facts(camino), _recent)
	_recent.append(_problem["key"])
	while _recent.size() > 4:
		_recent.pop_front()
	_q_started = Time.get_ticks_msec()
	Audio.play("ding")
	var panel := _make_modal(660.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(_label("Examen de %s" % classroom.student_names[_student], 40, HORIZONTAL_ALIGNMENT_CENTER, Color("d6336c")))
	if _problem.get("review", false):
		var row_chip := HBoxContainer.new()
		row_chip.alignment = BoxContainer.ALIGNMENT_CENTER
		row_chip.add_child(Hud.chip("Repaso", Color("fff0cf"), Color("8a6d3b"), 22))
		box.add_child(row_chip)
	var row: BoxContainer
	var flag_options: bool = _problem.get("option_flags", false)
	if subject == "english":
		_english_prompt(box)
		row = VBoxContainer.new()
	elif subject == "geography":
		_geo_prompt(box)
		row = HBoxContainer.new() if flag_options else VBoxContainer.new()
	else:
		var eq := _label("%s = ?" % _problem["text"], 96)
		eq.name = "Equation"
		box.add_child(eq)
		row = HBoxContainer.new()
	row.name = "Options"
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	_option_buttons = []
	for value in _problem["options"]:
		var b := Button.new()
		b.text = "" if flag_options else str(value)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 150 if subject == "math" or flag_options else 96)
		Hud.style_soft(b, 70 if subject == "math" else 40)
		if flag_options:   # se elige entre tres banderas
			var flag := FlagArt.new()
			flag.set_anchors_preset(Control.PRESET_FULL_RECT)
			flag.offset_left = 14
			flag.offset_right = -14
			flag.offset_top = 14
			flag.offset_bottom = -14
			flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			flag.show_flag(str(value))
			b.add_child(flag)
		b.set_meta("value", value)
		b.pressed.connect(_on_option.bind(b))
		row.add_child(b)
		_option_buttons.append(b)
	var result := _label("", 36)
	result.name = "Result"
	box.add_child(result)
	var info := VBoxContainer.new()
	info.name = "Info"
	info.visible = false
	info.add_theme_constant_override("separation", 10)
	box.add_child(info)


## Pregunta de geografia: la bandera (si va), el pais o la capital, la pregunta y la pista ("T…").
func _geo_prompt(box: VBoxContainer) -> void:
	if _problem["flag"] != "":
		var flag := FlagArt.new()
		flag.custom_minimum_size = Vector2(0, 170)
		flag.show_flag(_problem["flag"])
		box.add_child(flag)
	if _problem["prompt"] != "":
		var prompt := _label(_problem["prompt"], 54)
		prompt.name = "Prompt"
		box.add_child(prompt)
	box.add_child(_label(_problem["ask"], 30, HORIZONTAL_ALIGNMENT_CENTER, Color("a0527a")))
	if _problem["hint"] != "":   # niveles con pista: la primera letra
		var hint_row := HBoxContainer.new()
		hint_row.alignment = BoxContainer.ALIGNMENT_CENTER
		hint_row.add_child(Hud.chip("Pista: %s" % _problem["hint"], Color("fff3d1"), Color("8a6d00"), 30))
		box.add_child(hint_row)


## Geografia, ya respondido: la bandera chiquita con el pais y su capital, para recordarlo.
func _geo_answered(box: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	var flag := FlagArt.new()
	flag.custom_minimum_size = Vector2(66, 44)
	flag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	flag.show_flag(_problem["id"])
	row.add_child(flag)
	row.add_child(Hud.chip("%s · capital: %s" % [_problem["country"], _problem["capital"]], Color("e3f6ea"), Color("1f7a4d"), 24))
	box.add_child(row)
	box.move_child(row, box.get_node("Options").get_index() + 1)


## Pregunta de ingles: el dibujo (si tiene), la palabra o la frase grande y que hay que hacer.
func _english_prompt(box: VBoxContainer) -> void:
	var pic: String = _problem.get("pic", "")
	if EnglishPicture.has_picture(pic):
		var art := EnglishPicture.new()
		art.custom_minimum_size = Vector2(0, 190)
		art.show_pic(pic)
		box.add_child(art)
	var phrase: bool = camino == "en_phrases"
	var prompt := _label(_problem["prompt"], 50 if phrase else 66)
	prompt.name = "Prompt"
	box.add_child(prompt)
	if camino == "en_meaning":  # como se lee en ingles (y si el telefono tiene voz, se puede escuchar)
		var say_row := HBoxContainer.new()
		say_row.alignment = BoxContainer.ALIGNMENT_CENTER
		say_row.add_theme_constant_override("separation", 10)
		say_row.add_child(Hud.chip("Se dice: %s" % _problem["say"], Color("e6efff"), Color("3f66b0"), 24))
		if Speech.available():
			say_row.add_child(_speak_button(_problem["en"]))
		box.add_child(say_row)
	box.add_child(_label(_problem["ask"], 28, HORIZONTAL_ALIGNMENT_CENTER, Color("a0527a")))


## Boton con un parlante: dice la palabra en ingles con la voz del telefono.
func _speak_button(text: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(64, 52)
	b.focus_mode = Control.FOCUS_NONE
	Hud.style_soft(b, 20)
	b.pressed.connect(func(): Speech.say(text))
	var icon := Control.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func():
		var c := icon.size * 0.5 + Vector2(-6, 0)
		icon.draw_colored_polygon(PackedVector2Array([c + Vector2(-12, -6), c + Vector2(-4, -6), c + Vector2(6, -14),
			c + Vector2(6, 14), c + Vector2(-4, 6), c + Vector2(-12, 6)]), INK)
		for k in 2:
			icon.draw_arc(c + Vector2(8, 0), 8.0 + 7.0 * k, -0.9, 0.9, 8, INK, 3.0, true))
	b.add_child(icon)
	return b


func _on_option(button: Button) -> void:
	if _answered or _layer == null:
		return
	_answered = true
	var value = button.get_meta("value")
	var answer = _problem["answer"]
	var right: bool = str(value) == str(answer)
	var seconds := (Time.get_ticks_msec() - _q_started) / 1000.0
	answer_times.append(seconds)
	GameState.record_answer(camino, _problem, right, seconds)
	var box: VBoxContainer = _layer.get_child(1).get_child(0)
	var row: BoxContainer = box.get_node("Options")
	var result: Label = box.get_node("Result")
	var info: VBoxContainer = box.get_node("Info")
	for b in row.get_children():
		var is_right: bool = str(b.get_meta("value")) == str(answer)
		if is_right:
			b.self_modulate = Color(0.55, 0.9, 0.6)
		elif b == button:
			b.self_modulate = Color(1.0, 0.55, 0.55)
		else:
			b.modulate.a = 0.45
	_dots.results.append(right)
	_dots.queue_redraw()
	if subject == "english":
		_english_answered(box)
	elif subject == "geography":
		_geo_answered(box)
	if right:
		correct += 1
		result.text = "¡Correcto!" if seconds > problems.fast_seconds(camino, level) else "¡Correcto y rápido!"
		result.add_theme_color_override("font_color", Color("2f9e6e"))
		Audio.play("coin")
		await get_tree().create_timer(1.0 if subject == "math" else 1.8).timeout
		_end_question()
	else:
		var explanation: String = problems.explanation(_problem)
		var review: String = "%s = %d" % [_problem["text"], answer] if subject == "math" else _problem["text"]
		mistakes.append({"text": _problem["text"], "answer": answer, "picked": value, "explanation": explanation, "review": review})
		result.text = "¡Casi! Es %s" % (str(answer) if not _problem.get("option_flags", false) else "la de %s" % _problem["country"])
		result.add_theme_color_override("font_color", Color("d6336c"))
		Audio.play("fail")
		info.visible = true
		info.add_child(_label(explanation, 28))
		if subject == "math" and MathHint.can_draw(_problem):
			var hint := MathHint.new()
			hint.custom_minimum_size = Vector2(0, 190)
			hint.show_problem(_problem)
			info.add_child(hint)
		var ok := Button.new()
		ok.text = "¡Entendido!"
		ok.custom_minimum_size = Vector2(0, 84)
		Hud.style_primary(ok, 36)
		ok.pressed.connect(_end_question)
		info.add_child(ok)


## Ingles, ya respondido: la frase queda completa, se ve como se pronuncia y se escucha (si hay voz).
func _english_answered(box: VBoxContainer) -> void:
	var prompt: Label = box.get_node_or_null("Prompt")
	if camino == "en_phrases":
		if prompt != null:
			prompt.text = _problem["text"]
			prompt.add_theme_color_override("font_color", Color("2f9e6e"))
		Speech.say(_problem["text"])
		return
	if camino == "en_words":
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(Hud.chip("%s · se dice: %s" % [_problem["en"], _problem["say"]], Color("e6efff"), Color("3f66b0"), 26))
		box.add_child(row)
		box.move_child(row, box.get_node("Options").get_index() + 1)
	Speech.say(_problem["en"])


func _end_question() -> void:
	if state != State.QUESTION:
		return
	_close_layer()
	questions_done += 1
	if _dots.results.size() > 0 and _dots.results[_dots.results.size() - 1]:
		classroom.cheer(5)
	if questions_done >= MathProblems.QUESTIONS_PER_SHIFT:
		full_shift = true
		_finish(true)
	else:
		state = State.PLAY
		_signal_t = rng.randf_range(SIGNAL_GAP.x, SIGNAL_GAP.y)
		if questions_done == 1:  # ya se puede cobrar
			_finish_button.visible = true
			_show_toast("¡Ya puedes cobrar!")


# --------------------------------------------------------------------- cartel final

func _finish(full := true) -> void:
	state = State.END
	_finish_button.visible = false
	var res := GameState.finish_job(camino, correct, maxi(questions_done, 1), full)
	# carteles en fila: nivel de matematicas, ascenso de profesor/a, primer turno y el resultado
	_steps = []
	if res["action"] in ["up", "jump", "complete"]:
		_steps.append(_show_level_up.bind(res))
	if res["promoted"]:
		_steps.append(_show_promotion.bind(res))
	if GameState.jobs_done == 1 and not GameState.tips_seen.has(TIP_FIRST_SHIFT):
		_steps.append(_show_first_shift)
	_steps.append(_show_result.bind(res))
	_next_step()


## Muestra el siguiente cartel de la fila.
func _next_step() -> void:
	_close_layer()
	if not _steps.is_empty():
		(_steps.pop_front() as Callable).call()


## Ascenso de profesor/a: nueva ficha con mas paga por turno.
func _show_promotion(res: Dictionary) -> void:
	var notice := BigNotice.new(660.0)
	_layer = notice
	add_child(notice)
	notice.title("¡Ascendiste!", Color("d6336c"), 52)
	notice.add(TeacherCard.new().setup(res["career_after"]))
	notice.text_line("Ahora ganas %d monedas por turno." % Jobs.pay_for_level(res["career_after"]), 28, Color("8a6d00"))
	notice.button("¡Genial!", _next_step)
	Audio.play("success")
	classroom.cheer(8)


## Cartel 3 (el primer turno): ya sabe lo basico; si el huevo espera, a comprar la cuna.
func _show_first_shift() -> void:
	GameState.tips_seen.append(TIP_FIRST_SHIFT)
	GameState.save_game()
	var notice := BigNotice.new()
	_layer = notice
	add_child(notice)
	var crib := GameState.egg_waiting() and not GameState.owns_crib()
	var affordable := crib and GameState.coins >= int(Catalog.get_item(GameState.CRIB_ID)["price"])
	notice.add(BigNotice.icon_strip([["check", Color("5fc77f")], ["crib", Color("ffb938")]] if crib else [["check", Color("5fc77f")], ["heart", Color("ff7aa8")]]))
	notice.title("¡Perfecto!")
	notice.text_line("Ya sabes lo básico para cuidar a tu Pompon.", 30)
	if crib:
		notice.text_line("Pronto nacerá: ¡compremos una cuna!", 30, Color("a0527a"))
	if affordable:
		notice.button("Ir a la Tienda", func(): get_tree().change_scene_to_file("res://scenes/shop.tscn"), true, Color("5fc77f"))
		notice.button("Ver mi nota", _next_step, false)
	else:
		notice.button("Ver mi nota", _next_step)


## Cartel de avance: el juego decidio que se domina el nivel. El premio es siempre el mismo.
func _show_level_up(res: Dictionary) -> void:
	var panel := _make_modal(640.0)
	panel.add_theme_stylebox_override("panel", Hud.card(Color("fff9e0"), 40, Color("ffcf3f"), 10, 16))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var complete: bool = res["action"] == "complete"
	box.add_child(_label("¡CAMINO COMPLETO!" if complete else "¡SUBISTE DE NIVEL!", 42, HORIZONTAL_ALIGNMENT_CENTER, Color("d6336c")))
	if complete:
		box.add_child(_label("¡Dominaste %s!" % String(problems.LABELS[camino]).to_lower(), 34))
	else:
		box.add_child(_label("Nivel %d" % res["level_after"], 120, HORIZONTAL_ALIGNMENT_CENTER, Color("e0a800")))
		box.add_child(_label(problems.level_name(camino, res["level_after"]), 34))
	var prize := HBoxContainer.new()
	prize.alignment = BoxContainer.ALIGNMENT_CENTER
	prize.add_theme_constant_override("separation", 10)
	prize.add_child(Hud.coin_icon(54.0))
	var prize_text := _label("+%d monedas" % res["bonus"], 46, HORIZONTAL_ALIGNMENT_CENTER, Color("b8860b"))
	prize_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	prize.add_child(prize_text)
	box.add_child(prize)
	var go := Button.new()
	go.text = "¡Genial!"
	go.custom_minimum_size = Vector2(0, 92)
	Hud.style_primary(go, 40)
	go.pressed.connect(_next_step)
	box.add_child(go)
	Audio.play("success")
	classroom.cheer(8)


## Cartel con la nota del turno, el progreso hacia el siguiente nivel y las cuentas para repasar.
func _show_result(res: Dictionary) -> void:
	var panel := _make_modal(660.0)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, minf(size.y - 330.0, 860.0))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)

	box.add_child(_label("¡Fin del turno!", 36, HORIZONTAL_ALIGNMENT_CENTER, Color("a0527a")))
	box.add_child(_label("Nota: %d / 10" % res["note"], 70, HORIZONTAL_ALIGNMENT_CENTER, Color("d6336c")))
	var stars := StarsRow.new()
	stars.filled = res["note"]
	stars.custom_minimum_size = Vector2(0, 46)
	box.add_child(stars)
	box.add_child(_label(res["title"], 38, HORIZONTAL_ALIGNMENT_CENTER, Color("2f9e6e") if res["note"] >= 5 else INK))
	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 12)
	chips.add_child(Hud.chip("%s: %d de %d" % ["Cuentas bien" if subject == "math" else "Bien", correct, maxi(questions_done, 1)], Color("d8f5e3"), Color("1f7a4d"), 24))
	chips.add_child(Hud.chip("Ordenados: %d" % sorter.sorted_total, Color("e6efff"), Color("3f66b0"), 24))
	box.add_child(chips)
	var pay := HBoxContainer.new()
	pay.alignment = BoxContainer.ALIGNMENT_CENTER
	pay.add_theme_constant_override("separation", 10)
	pay.add_child(Hud.coin_icon(50.0))
	var pay_text := _label("+%d monedas" % res["pay"], 44, HORIZONTAL_ALIGNMENT_CENTER, Color("b8860b"))
	pay_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	pay.add_child(pay_text)
	box.add_child(pay)
	if res["extra"] > 0:
		var extra_row := HBoxContainer.new()
		extra_row.alignment = BoxContainer.ALIGNMENT_CENTER
		extra_row.add_child(Hud.chip("¡Turno completo! +%d monedas extra" % res["extra"], Color("fff0cf"), Color("8a6d3b"), 26))
		box.add_child(extra_row)
	else:
		box.add_child(_label("Termina el turno completo y gana +%d extra" % problems.FULL_SHIFT_BONUS, 22, HORIZONTAL_ALIGNMENT_CENTER, Color("a0527a")))
	if res["bonus"] > 0:
		box.add_child(_label("+%d monedas de premio por el nivel" % res["bonus"], 28, HORIZONTAL_ALIGNMENT_CENTER, Color("2f9e6e")))
	box.add_child(HSeparator.new())
	box.add_child(_label("%s · Nivel %d" % [problems.LABELS[camino], res["level_before"]], 28, HORIZONTAL_ALIGNMENT_CENTER, Color("a0527a")))
	var dots := MasteryDots.new()
	dots.custom_minimum_size = Vector2(0, 50)
	dots.set_data(res["history"], problems.fast_seconds(camino, res["level_before"]))
	box.add_child(dots)
	var streak: int = problems.good_streak(camino, res["level_before"], res["history"])
	match res["action"]:
		"up", "jump", "complete":
			box.add_child(_label("¡Ahora estás en el nivel %d!" % res["level_after"], 28, HORIZONTAL_ALIGNMENT_CENTER, Color("2f9e6e")))
		"down":
			box.add_child(_label("Bajamos un nivel para afirmar. ¡Tú puedes!", 26))
		_:
			box.add_child(_label("Para subir: %d seguidas bien y rápidas (llevas %d)" % [problems.WINDOW, streak], 24))

	if not mistakes.is_empty():
		box.add_child(HSeparator.new())
		box.add_child(_label("Para repasar", 32, HORIZONTAL_ALIGNMENT_CENTER, Color("d6336c")))
		for m in mistakes:
			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", Hud.card(Color("fff1f6"), 24, Color("ffc2d9"), 3, 0))
			card.add_child(_label(m["review"], 42 if subject == "math" else 32))
			box.add_child(card)

	if GameState.egg_waiting() and not GameState.owns_crib():
		var price: int = Catalog.get_item(GameState.CRIB_ID)["price"]
		box.add_child(HSeparator.new())
		var bar := StatBar.new().setup("", "crib", Color("ffb938"))
		bar.custom_minimum_size = Vector2(0, 48)
		bar.max_value = float(price)
		bar.value = float(mini(GameState.coins, price))
		bar.font_size = 22
		bar.text = "Cuna  %d / %d" % [mini(GameState.coins, price), price]
		box.add_child(bar)

	var again := Button.new()
	again.text = "¡Otra vez!"
	again.custom_minimum_size = Vector2(0, 84)
	Hud.style_primary(again, 36)
	again.pressed.connect(func(): get_tree().reload_current_scene())
	outer.add_child(again)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	outer.add_child(row)
	var office := Button.new()
	office.text = "Aula"
	office.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	office.custom_minimum_size = Vector2(0, 76)
	Hud.style_soft(office, 30)
	office.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/job_menu.tscn"))
	row.add_child(office)
	var go_on := Button.new()
	go_on.text = "Casa"  # en la casa una flecha lleva a la Tienda cuando alcanza para la cuna
	go_on.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go_on.custom_minimum_size = Vector2(0, 76)
	Hud.style_soft(go_on, 30)
	go_on.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/home.tscn"))
	row.add_child(go_on)
