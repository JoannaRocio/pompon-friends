extends Control
## El Cine Pompon (desde el pueblo): en la boleteria se ve la pelicula de esta semana (rotan cada
## semana, los lunes: ver Movies) y la que viene; se puede ir solo o invitar a un vecino. La entrada trae pochoclos. En la sala
## la pelicula se cuenta en escenas con subtitulos: tocar la pantalla pasa a la siguiente y "Saltar"
## la termina. Al final, tu Pompon cuenta que le parecio (va a su diario) y sube la diversion.

const INK := Color("5b3a4a")
const NIGHT := Color("2a2140")

var movie := {}
var companion := {}            # vecino invitado ({} = solo)
var state := "lobby"           # "lobby", "watching", "end"
var screen: MovieScreen
var _subtitle: Label
var _scene_t := 0.0
var _layer: Control
var _companion_buttons: Array = []
var _pet: PomponView
var _buddy: PomponView


func _ready() -> void:
	movie = Movies.of_day(Missions.today(int(Time.get_unix_time_from_system())))
	_show_lobby()


func _clear() -> void:
	for c in get_children():
		c.queue_free()
	_layer = null


func _today() -> int:
	return Missions.today(int(Time.get_unix_time_from_system()))


# ------------------------------------------------------------------ boleteria

func _show_lobby() -> void:
	_clear()
	state = "lobby"
	var bg := ColorRect.new()
	bg.color = Color("3b2f55")
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
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	top.add_child(Hud.back_button(func(): get_tree().change_scene_to_file("res://scenes/town.tscn")))
	var title := Label.new()
	title.text = "Cine Pompon"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("ffe066"))
	top.add_child(title)
	var coins := HBoxContainer.new()
	coins.add_theme_constant_override("separation", 6)
	coins.add_child(Hud.coin_icon(34.0))
	var coin_label := Label.new()
	coin_label.text = str(GameState.coins)
	coin_label.add_theme_font_size_override("font_size", 30)
	coin_label.add_theme_color_override("font_color", Color("ffe066"))
	coins.add_child(coin_label)
	top.add_child(coins)

	root.add_child(_poster(movie, true))
	var next := Movies.next_of(_today())
	var left := Movies.days_left(_today())
	var next_row := HBoxContainer.new()
	next_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var when := T.s("desde mañana") if left == 1 else T.s("en %d días") % left
	next_row.add_child(Hud.chip(T.s("Próxima: %s · %s") % [T.s(next["title"]), when], Color("4a3d6b"), Color("ffe9a3"), 24))
	root.add_child(next_row)

	# ¿con quien vas?
	var who := Label.new()
	who.text = "¿Con quién vas?"
	who.add_theme_font_size_override("font_size", 30)
	who.add_theme_color_override("font_color", Color("ffe9a3"))
	root.add_child(who)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	_companion_buttons = []
	var options: Array = [{}] + Neighbors.all().slice(0, 4)
	for entry in options:
		var b := Button.new()
		b.custom_minimum_size = Vector2(118, 132)
		b.focus_mode = Control.FOCUS_NONE
		b.text = "" if not entry.is_empty() else "Solo"
		b.set_meta("entry", entry)
		b.pressed.connect(_pick_companion.bind(entry))
		row.add_child(b)
		_companion_buttons.append(b)
		if not entry.is_empty():
			var view := PomponView.new()
			view.set_anchors_preset(Control.PRESET_FULL_RECT)
			view.offset_bottom = -26
			view.mouse_filter = Control.MOUSE_FILTER_IGNORE
			view.animated = false
			var data := Neighbors.build(entry)
			view.head_zoom = PomponView.portrait_zoom(data["pompon"], int(Time.get_unix_time_from_system()))
			view.set_pompon(data["pompon"], data["equipped"])
			b.add_child(view)
			var name_label := Label.new()
			name_label.text = entry["name"]
			name_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
			name_label.offset_top = -30
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.add_theme_font_size_override("font_size", 20)
			name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(name_label)
	_pick_companion({})

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	var buy := Button.new()
	buy.text = T.s("Ver la película · %d") % Movies.TICKET
	buy.custom_minimum_size = Vector2(0, 100)
	Hud.style_primary(buy, 38, Color("e0609e"))
	buy.pressed.connect(_buy)
	root.add_child(buy)
	var popcorn := Label.new()
	popcorn.text = "La entrada trae pochoclos"
	popcorn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popcorn.add_theme_font_size_override("font_size", 22)
	popcorn.add_theme_color_override("font_color", Color("ffe9a3"))
	root.add_child(popcorn)


## Afiche de una pelicula: un dibujo de su primera escena, el titulo y de que se trata.
func _poster(m: Dictionary, big: bool) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Hud.card(Color("fffaf0"), 30, Color(m["color"]), 8, 12))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	head.add_child(Hud.chip("Esta semana" if big else "Próxima", Color(m["color"]), Color.WHITE, 22))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	head.add_child(Hud.chip(m["genre"], Color("fff3d1"), Color("8a6d00"), 22))
	var preview := MovieScreen.new()
	preview.custom_minimum_size = Vector2(0, 330 if big else 180)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(preview)
	preview.setup.call_deferred(m)
	var title := Label.new()
	title.text = m["title"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44 if big else 30)
	title.add_theme_color_override("font_color", Color(m["color"]).darkened(0.2))
	col.add_child(title)
	var tag := Label.new()
	tag.text = m["tagline"]
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.add_theme_font_size_override("font_size", 24)
	tag.add_theme_color_override("font_color", INK)
	col.add_child(tag)
	var seen := int(GameState.movies_seen.get(m["id"], 0))
	if seen > 0:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(Hud.chip(T.s("Ya la viste %d %s") % [seen, T.s("vez") if seen == 1 else T.s("veces")], Color("e3f6ea"), Color("1f7a4d"), 20))
		col.add_child(row)
	return card


func _pick_companion(entry: Dictionary) -> void:
	companion = entry
	for b in _companion_buttons:
		var picked: bool = b.get_meta("entry") == entry
		var sb := Hud.card(Color("fff6fa") if picked else Color("4a3d6b"), 24, Color("ffe066") if picked else Color("6b5a8f"), 6 if picked else 3, 0)
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, sb)
		b.add_theme_color_override("font_color", INK if picked else Color("ffe9a3"))


func _buy() -> void:
	if GameState.coins < Movies.TICKET:
		_message("Te faltan monedas", T.s("La entrada cuesta %d monedas. ¡Gánalas en Trabajo!") % Movies.TICKET)
		return
	GameState.coins -= Movies.TICKET
	GameState.save_game()
	Audio.play("coin")
	_start_movie()


# ------------------------------------------------------------------ la sala

func _start_movie() -> void:
	_clear()
	state = "watching"
	var bg := ColorRect.new()
	bg.color = NIGHT
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# cortinas rojas a los costados
	var curtains := Control.new()
	curtains.set_anchors_preset(Control.PRESET_FULL_RECT)
	curtains.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curtains.draw.connect(func():
		for side in [0.0, 1.0]:
			for k in 4:
				var x: float = side * curtains.size.x + (k * 14.0 if side == 0.0 else -k * 14.0 - 14.0)
				curtains.draw_rect(Rect2(x, 0, 14, curtains.size.y * 0.7), Color("b02a4a") if k % 2 == 0 else Color("8e1f3a")))
	add_child(curtains)
	screen = MovieScreen.new()
	screen.set_anchors_preset(Control.PRESET_TOP_WIDE)
	screen.offset_left = 66
	screen.offset_right = -66
	screen.offset_top = 120
	screen.offset_bottom = 120 + 560
	screen.gui_input.connect(_on_screen_input)
	add_child(screen)
	screen.setup(movie)
	_subtitle = Label.new()
	_subtitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_subtitle.offset_left = 40
	_subtitle.offset_right = -40
	_subtitle.offset_top = 700
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.add_theme_font_size_override("font_size", 32)
	_subtitle.add_theme_color_override("font_color", Color("fff3d1"))
	add_child(_subtitle)
	# las butacas: tu Pompon (y tu invitado) con pochoclos
	var seats := Control.new()
	seats.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	seats.offset_top = -420
	seats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seats.draw.connect(func():
		for i in 5:
			var x := seats.size.x * (0.1 + i * 0.2)
			seats.draw_rect(Rect2(x - 62, seats.size.y - 170, 124, 170), Color("7a1f3a"))
			seats.draw_rect(Rect2(x - 70, seats.size.y - 190, 140, 40), Color("9b2a4c")))
	add_child(seats)
	_pet = PomponView.new()
	_pet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pet.size = Vector2(260, 260)
	if GameState.pompon != null:
		_pet.set_pompon(GameState.pompon, GameState.equipped)
	add_child(_pet)
	if not companion.is_empty():
		var data := Neighbors.build(companion)
		_buddy = PomponView.new()
		_buddy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_buddy.size = Vector2(240, 240)
		_buddy.set_pompon(data["pompon"], data["equipped"])
		_buddy.facing = -1.0
		add_child(_buddy)
	var popcorn := Control.new()
	popcorn.size = Vector2(90, 100)
	popcorn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popcorn.draw.connect(func():
		popcorn.draw_colored_polygon(PackedVector2Array([Vector2(10, 30), Vector2(80, 30), Vector2(70, 100), Vector2(20, 100)]), Color("ef4444"))
		for k in 3:
			popcorn.draw_rect(Rect2(22 + k * 18, 30, 8, 70), Color.WHITE)
		for k in 7:
			popcorn.draw_circle(Vector2(18 + k * 9.0, 26 - (k % 2) * 8.0), 11.0, Color("fff3c4")))
	popcorn.name = "Popcorn"
	add_child(popcorn)
	var skip := Button.new()
	skip.text = "Saltar"
	skip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip.offset_left = -170
	skip.offset_right = -20
	skip.offset_top = 24
	skip.offset_bottom = 90
	skip.focus_mode = Control.FOCUS_NONE
	Hud.style_soft(skip, 28)
	skip.pressed.connect(_end_movie)
	add_child(skip)
	var hint := Label.new()
	hint.text = "Toca la pantalla para seguir"
	hint.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hint.position = Vector2(24, 40)
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	add_child(hint)
	resized.connect(_place_seats)
	_place_seats.call_deferred()
	_show_scene(0)
	Audio.play("ding")


func _place_seats() -> void:
	if state != "watching" or _pet == null:
		return
	var y := size.y - 300.0
	_pet.position = Vector2(size.x * 0.3 - 130.0, y)
	if _buddy != null:
		_buddy.position = Vector2(size.x * 0.7 - 120.0, y + 10.0)
	var pc: Control = get_node_or_null("Popcorn")
	if pc != null:
		pc.position = Vector2(size.x * 0.5 - 45.0, size.y - 190.0)


func _show_scene(i: int) -> void:
	screen.show_scene(i)
	_subtitle.text = T.s(screen.scene()["text"])
	_scene_t = Movies.scene_seconds(_subtitle.text)
	if screen.scene()["actors"].any(func(a): return a[3].get("mood", "") == "happy"):   # el publico se alegra
		_pet.celebrate(2)
		if _buddy != null:
			_buddy.celebrate(2)


func _on_screen_input(event: InputEvent) -> void:
	if state == "watching" and event is InputEventMouseButton and event.pressed:
		next_scene()


## Pasa a la escena siguiente (o termina).
func next_scene() -> void:
	if state != "watching":
		return
	if screen.scene_i >= movie["scenes"].size() - 1:
		_end_movie()
	else:
		_show_scene(screen.scene_i + 1)


func _process(delta: float) -> void:
	if state != "watching":
		return
	_scene_t -= delta
	if _scene_t <= 0.0:
		next_scene()


# ------------------------------------------------------------------ el final

func _end_movie() -> void:
	if state != "watching":
		return
	state = "end"
	var res: Dictionary = GameState.watch_movie(movie["id"], companion)
	var notice := BigNotice.new(640.0)
	_layer = notice
	add_child(notice)
	notice.title("¡Fin!", Color("e0609e"), 56)
	notice.text_line(movie["title"], 32, Color(movie["color"]).darkened(0.2))
	var face := PomponView.new()
	face.custom_minimum_size = Vector2(0, 220)
	if GameState.pompon != null:
		face.set_pompon(GameState.pompon, GameState.equipped)
	notice.add(face)
	face.celebrate(6)
	notice.text_line(movie["message"], 26, Color("a0527a"))
	notice.text_line("“%s”" % res["reaction"], 28)   # (ya viene en el idioma del juego)
	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 14)
	chips.add_child(MiniGameBase.RewardChip.new().setup("game", "+%d" % int(res["fun"]), Hud.STAT_COLORS["diversion"]))
	if res["social"] > 0.0:
		chips.add_child(MiniGameBase.RewardChip.new().setup("people", "+%d" % int(res["social"]), Hud.STAT_COLORS["amistad"]))
	notice.add(chips)
	notice.button("Volver al pueblo", func(): get_tree().change_scene_to_file("res://scenes/town.tscn"), true, Color("e0609e"))
	notice.button("Boletería", func(): _show_lobby(), false)
	Audio.play("success")


func _message(title: String, text: String) -> void:
	if _layer != null:
		return
	var notice := BigNotice.new(600.0)
	_layer = notice
	add_child(notice)
	notice.closed.connect(func(): _layer = null)
	notice.title(title, Color("d6336c"))
	notice.text_line(text, 28)
	notice.button("¡Bien!", notice.close)
