extends Control
## Aula de la materia elegida en el periodico (matematicas o ingles, ver Jobs.current): se elige que
## practicar. Cada camino muestra su nivel, los puntitos de dominio y un boton para trabajar.
## Poco texto: todo se entiende de un vistazo.

const COLORS := {"addsub": Color("ff9b54"), "mul": Color("e0609e"), "div": Color("4cb782"),
	"en_words": Color("5aa9e6"), "en_meaning": Color("8a7be0"), "en_phrases": Color("3cb8a0"),
	"es_words": Color("5aa9e6"), "es_meaning": Color("8a7be0"), "es_phrases": Color("3cb8a0"),
	"geo_capitals": Color("4cb782"), "geo_flags": Color("ff8a5b"), "geo_mix": Color("5aa9e6")}
const SYMBOLS := {"addsub": "+ −", "mul": "×", "div": "÷", "en_words": "ABC", "en_meaning": "¿?", "en_phrases": "Hi!", "es_words": "ABC", "es_meaning": "¿?", "es_phrases": "¡Hola!", "geo_capitals": "", "geo_flags": "", "geo_mix": ""}

var _layer: Control
var _arrow: GuideArrow
var _shop_button: Button
var _work_buttons: Array = []   # los tres T.s("Trabajar"): la flecha los recorre la primera vez
var _problems: GDScript         # MathProblems o EnglishProblems


func _ready() -> void:
	_problems = Jobs.problems(Jobs.current)
	var bg := ColorRect.new()
	bg.color = Color("fff4e8")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_right = -20
	root.offset_top = 20
	root.offset_bottom = -20
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	# pizarra de cabecera: volver, titulo y monedas
	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel", Hud.card(Color("4f8a76"), 34, Color("c99560"), 8, 10))
	root.add_child(board)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	board.add_child(head)
	head.add_child(Hud.back_button(func(): get_tree().change_scene_to_file("res://scenes/job_board.tscn")))
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", 0)
	head.add_child(texts)
	var title := Label.new()
	title.text = T.s("Aula de %s") % Jobs.subject_name(Jobs.current)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("fffbe8"))
	texts.add_child(title)
	var who := Label.new()
	who.text = T.s("Escuela Pompon · %s") % Jobs.full_title(GameState.player_title, GameState.player_name)
	who.add_theme_font_size_override("font_size", 24)
	who.add_theme_color_override("font_color", Color("ffe9a3"))
	texts.add_child(who)
	var coins := HBoxContainer.new()
	coins.add_theme_constant_override("separation", 6)
	coins.add_child(Hud.coin_icon(38.0))
	var coin_label := Label.new()
	coin_label.text = str(GameState.coins)
	coin_label.add_theme_font_size_override("font_size", 32)
	coin_label.add_theme_color_override("font_color", Color("fffbe8"))
	coins.add_child(coin_label)
	head.add_child(coins)

	if GameState.egg_waiting() and not GameState.owns_crib():
		root.add_child(_crib_card())

	var pick := Label.new()
	pick.text = T.s("¿Qué practicamos?")
	pick.add_theme_font_size_override("font_size", 34)
	pick.add_theme_color_override("font_color", Color("a0527a"))
	root.add_child(pick)
	# turnos con paga completa que quedan hoy (despues se practica con paga chica)
	var left := GameState.paid_shifts_left()
	var paid_text := T.s("Turnos con paga hoy: %d de %d") % [left, GameState.PAID_SHIFTS_PER_DAY] if left > 0 \
		else T.s("Hoy ya cobraste. ¡Mañana hay más!")
	var paid_row := HBoxContainer.new()
	paid_row.add_child(Hud.chip(paid_text, Color("fff0cf") if left > 0 else Color("f1e6f7"), Color("8a6d3b") if left > 0 else Color("7a56c4"), 24))
	root.add_child(paid_row)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)
	for camino in _problems.TRACKS:
		list.add_child(_track_card(camino))
	root.add_child(_classroom())

	_arrow = GuideArrow.new()
	add_child(_arrow)


## Mientras haya que aprender a trabajar, la flecha pasa por los tres T.s("Trabajar") (sirve cualquiera).
## Si ya alcanza para la cuna, señala T.s("Ir a la Tienda").
func _process(_delta: float) -> void:
	if _layer != null:
		_arrow.set_targets([])
	elif _shop_button != null:
		_arrow.set_targets([_shop_button])
	else:
		_arrow.set_targets(_work_buttons if GameState.job_guide_on() else [])


## Abajo, el aula: una pizarra con los simbolos de la materia y tu Pompon al lado, de profe.
## (Antes quedaba media pantalla vacia debajo de los tres caminos.)
func _classroom() -> Control:
	var room := Control.new()
	room.custom_minimum_size = Vector2(0, 400)
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var marks: Array = []
	for camino in _problems.TRACKS:
		if SYMBOLS[camino] != "":
			marks.append(SYMBOLS[camino])
	room.draw.connect(func():
		var w := room.size.x
		var h := room.size.y
		var board_r := Rect2(w * 0.04, h * 0.1, w * 0.56, h * 0.6)
		room.draw_rect(Rect2(board_r.position - Vector2(12, 12), board_r.size + Vector2(24, 24)), Color("c99560"))
		room.draw_rect(board_r, Color("4f8a76"))
		var font := room.get_theme_default_font()
		if marks.is_empty():   # geografia: un globo terraqueo de tiza
			var c := board_r.get_center()
			room.draw_arc(c, 62.0, 0.0, TAU, 40, Color(1, 1, 1, 0.85), 5.0, true)
			room.draw_line(c - Vector2(62, 0), c + Vector2(62, 0), Color(1, 1, 1, 0.6), 4.0)
			for k in [-1.0, 1.0]:
				room.draw_line(c + Vector2(-54, k * 30.0), c + Vector2(54, k * 30.0), Color(1, 1, 1, 0.5), 3.0)
			room.draw_line(c - Vector2(0, 62), c + Vector2(0, 62), Color(1, 1, 1, 0.6), 4.0)
		else:
			var text := "   ".join(marks)
			var fs := 64
			while fs > 30 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > board_r.size.x - 40.0:
				fs -= 4
			var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			room.draw_string(font, Vector2(board_r.get_center().x - tw * 0.5, board_r.get_center().y + fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.9))
		# repisa de la tiza
		room.draw_rect(Rect2(board_r.position.x - 4.0, board_r.end.y + 12.0, board_r.size.x + 8.0, 10.0), Color("b07a52"))
		room.draw_rect(Rect2(board_r.position.x + 30.0, board_r.end.y + 4.0, 26.0, 8.0), Color.WHITE))
	if GameState.pompon != null:
		var pet := PomponView.new()
		pet.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pet.set_anchors_preset(Control.PRESET_FULL_RECT)
		pet.anchor_left = 0.6
		pet.facing = -1.0   # mira a la pizarra
		pet.set_pompon(GameState.pompon, GameState.equipped)
		room.add_child(pet)
	return room


## Cuanto falta para comprar la cuna del huevo (barra + atajo a la tienda si ya alcanza).
func _crib_card() -> Control:
	var price: int = Catalog.get_item(GameState.CRIB_ID)["price"]
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.95), 30, Color.WHITE, 3, 6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	var bar := StatBar.new().setup("", "crib", Color("ffb938"))
	bar.custom_minimum_size = Vector2(0, 50)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.max_value = float(price)
	bar.value = float(mini(GameState.coins, price))
	bar.font_size = 22
	bar.text = T.t("home.crib_bar", {"have": mini(GameState.coins, price), "price": price})
	row.add_child(bar)
	if GameState.coins >= price:
		var go := Button.new()
		go.text = T.s("Ir a la Tienda")
		go.custom_minimum_size = Vector2(0, 62)
		Hud.style_primary(go, 24)
		go.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/shop.tscn"))
		row.add_child(go)
		_shop_button = go
	return card


func _track_card(camino: String) -> Control:
	var st := GameState.math_state(camino)
	var level := GameState.math_level(camino)
	var color: Color = COLORS[camino]
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.95), 34, Color.WHITE, 3, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	# simbolo grande en un circulo de color
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(104, 104)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_theme_stylebox_override("panel", Hud.card(color, 52, Color.WHITE, 5, 6))
	row.add_child(badge)
	var symbol := Label.new()
	symbol.text = SYMBOLS[camino]
	symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol.add_theme_font_size_override("font_size", 62 if SYMBOLS[camino].length() == 1 else (48 if camino == "addsub" else 42))
	symbol.add_theme_color_override("font_color", Color.WHITE)
	badge.add_child(symbol)
	if SYMBOLS[camino] == "":   # geografia: una banderita en lugar del simbolo
		var flag := FlagArt.new()
		flag.custom_minimum_size = Vector2(76, 52)
		flag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		flag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flag.show_flag({"geo_capitals": "japon", "geo_flags": "brasil", "geo_mix": "francia"}.get(camino, "japon"))
		badge.add_child(flag)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)
	var name_label := Label.new()
	name_label.text = _problems.track_label(camino)
	name_label.add_theme_font_size_override("font_size", 30)
	info.add_child(name_label)
	var lvl_row := HBoxContainer.new()
	lvl_row.add_theme_constant_override("separation", 10)
	info.add_child(lvl_row)
	lvl_row.add_child(Hud.chip(T.s("Nivel %d") % level, Color("ffe6ef"), Color("d6336c"), 20))
	if st["completed"]:
		lvl_row.add_child(Hud.chip(T.s("¡Completo!"), Color("d8f5e3"), Color("1f7a4d"), 20))
	var lvl := Label.new()
	lvl.text = _problems.level_name(camino, level)
	lvl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lvl.add_theme_font_size_override("font_size", 24)
	lvl.add_theme_color_override("font_color", Color("a0527a"))
	info.add_child(lvl)
	var dots := MasteryDots.new()
	dots.custom_minimum_size = Vector2(0, 30)
	dots.set_data(st["history"], _problems.fast_seconds(camino, level))
	info.add_child(dots)

	var buttons := VBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 8)
	row.add_child(buttons)
	var go := Button.new()
	go.text = T.s("Trabajar")
	go.custom_minimum_size = Vector2(160, 72)
	Hud.style_primary(go, 28, color)
	go.pressed.connect(func():
		Jobs.set_track(camino)
		get_tree().change_scene_to_file("res://scenes/job_game.tscn"))
	buttons.add_child(go)
	_work_buttons.append(go)
	var under := HBoxContainer.new()
	under.alignment = BoxContainer.ALIGNMENT_CENTER
	under.add_theme_constant_override("separation", 8)
	buttons.add_child(under)
	var pay := HBoxContainer.new()
	pay.add_theme_constant_override("separation", 4)
	pay.add_child(Hud.coin_icon(26.0))
	var pay_label := Label.new()
	pay_label.text = "+%d" % GameState.job_pay()
	pay_label.add_theme_font_size_override("font_size", 24)
	pay_label.add_theme_color_override("font_color", Color("b87400"))
	pay.add_child(pay_label)
	under.add_child(pay)
	var learn := Button.new()
	learn.text = T.s("Lección")
	learn.custom_minimum_size = Vector2(88, 40)
	Hud.style_soft(learn, 18)
	learn.pressed.connect(func(): _show_lesson(camino, level))
	under.add_child(learn)
	return card


func _show_lesson(camino: String, level: int) -> void:
	if _layer != null:
		return
	_layer = Control.new()
	_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.25, 0.12, 0.2, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(dim)
	var lesson := LessonView.new()
	lesson.set_anchors_preset(Control.PRESET_CENTER)
	lesson.offset_left = -330
	lesson.offset_right = 330
	lesson.grow_horizontal = Control.GROW_DIRECTION_BOTH
	lesson.grow_vertical = Control.GROW_DIRECTION_BOTH
	lesson.setup(camino, level)
	lesson.closed.connect(func():
		GameState.mark_lesson_seen(camino, level)
		_layer.queue_free()
		_layer = null)
	_layer.add_child(lesson)
