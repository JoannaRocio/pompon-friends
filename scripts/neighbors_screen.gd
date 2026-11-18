extends Control
## Lista de vecinos: arriba la barra Social de tu Pompon (la mitad solo se llena con otros
## Pompons); despues una tarjeta por vecino con su nivel de amistad (corazones), la barra 0-100,
## lo que ya sumo hoy (1 punto por visita y por cada actividad) y "Visitar".
## Arriba de la lista, los amigos de verdad (Friends): tu codigo, "Agregar amigo" y las solicitudes.

const BG := Color("e8f6ee")
const PINK := Color("ff7aa8")
const GREEN := Color("5fc77f")

var _list: VBoxContainer
var _notice: BigNotice
var _dirty := false


var _friends_card_node: Control
var _tut: TutorialOverlay


func _ready() -> void:
	Town.from_town = false
	_tutorial_step.call_deferred()
	if Friends.is_active() and GameState.age_group == "":   # partidas de antes: se pregunta la edad una vez
		(func(): FriendSafety.ask_age(self, func(_g): _dirty = true)).call_deferred()
	var bg := Control.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.draw.connect(func():
		bg.draw_rect(Rect2(Vector2.ZERO, bg.size), BG)
		for s in [[Vector2(0.95, 0.04), 170.0, Color("fff1c9")], [Vector2(0.0, 0.3), 160.0, Color("ffe0ec")],
				[Vector2(1.0, 0.7), 210.0, Color("d6ecff")], [Vector2(0.05, 0.98), 200.0, Color("e6dcff")]]:
			bg.draw_circle(Vector2(s[0]) * bg.size, float(s[1]), Color(s[2], 0.6)))
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_right = -20
	root.offset_top = 20
	root.offset_bottom = -20
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	# arriba: volver, titulo y monedas (el regalo cuesta monedas)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	top.add_child(Hud.back_button(func(): get_tree().change_scene_to_file("res://scenes/home.tscn")))
	var title := Label.new()
	title.text = "Vecinos"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("7a56c4"))
	top.add_child(title)
	var coin_card := PanelContainer.new()
	coin_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coin_card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.94), 30, Color.WHITE, 3, 6))
	top.add_child(coin_card)
	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 6)
	coin_row.add_child(Hud.coin_icon(34.0))
	var coins := Label.new()
	coins.text = str(GameState.coins)
	coins.add_theme_font_size_override("font_size", 30)
	coins.add_theme_color_override("font_color", Color("b87400"))
	coin_row.add_child(coins)
	coin_card.add_child(coin_row)

	if GameState.has_pompon() and GameState.pompon.hatched:
		root.add_child(_social_card())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 12)
	scroll.add_child(_list)
	Friends.changed.connect(func(): _dirty = true)
	_rebuild()
	if Friends.is_active():
		Friends.refresh()   # trae solicitudes y amigos nuevos (al terminar, la lista se redibuja)


func _process(_delta: float) -> void:
	if _dirty:
		_dirty = false
		_rebuild()


func _rebuild() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var friends_card := _friends_card()
	if friends_card != null:
		_list.add_child(friends_card)
	_friends_card_node = friends_card
	for entry in Neighbors.all():
		_list.add_child(_make_row(entry))


## Tutorial (capitulo "amigos"): resalta la tarjeta de amigos de verdad y explica el codigo.
func _tutorial_step() -> void:
	var step := GameState.tutorial_current()
	if step.get("screen", "") != "neighbors" or _tut != null:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if _friends_card_node == null or not is_instance_valid(_friends_card_node):
		GameState.tutorial_step_done()   # (sin servidor de amigos: no hay nada que mostrar)
		return
	_tut = TutorialOverlay.new().setup(TutorialSteps.fill(step["text"], GameState.pompon.display_name() if GameState.pompon != null else "", 0), _friends_card_node, "next")
	add_child(_tut)
	_tut.done.connect(func():
		GameState.tutorial_step_done()
		_tut.queue_free()
		_tut = null)
	_tut.skipped.connect(func():
		GameState.tutorial_skip()
		_tut.queue_free()
		_tut = null)


## Tu Pompon y su barra Social: para que se entienda por que visitar.
func _social_card() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.95), 34, Color.WHITE, 3, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	row.add_child(_portrait(GameState.pompon, GameState.equipped, 92.0, Color("ffe0ec")))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	row.add_child(col)
	var label := Label.new()
	label.text = "Social"
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Hud.INK)
	col.add_child(label)
	var bar := StatBar.new().setup("amistad")
	bar.custom_minimum_size = Vector2(0, 40)
	bar.value = GameState.pompon.stats.get("amistad", 0.0)
	col.add_child(bar)
	var hint := Label.new()   # para que se entienda que la barra se llena visitando
	hint.text = "¡Le encanta tener amigos!" if bar.value >= 80.0 else "Se llena visitando a tus vecinos."
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Hud.MUTED)
	col.add_child(hint)
	return card


func _make_row(entry: Dictionary) -> Control:
	var data := Neighbors.build(entry)
	var p: Pompon = data["pompon"]
	var id: String = entry["id"]
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.96), 34, Color.WHITE, 3, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	row.add_child(_portrait(p, data["equipped"], 118.0, p.color_primary.lightened(0.55)))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	info.add_child(head)
	var name_label := Label.new()
	name_label.text = data["name"]
	name_label.add_theme_font_size_override("font_size", 30)
	name_label.add_theme_color_override("font_color", Hud.INK)
	head.add_child(name_label)
	if entry.get("same_age", false):
		var chip := Hud.chip("De tu edad", Color("e6efff"), Color("3f66b0"), 17)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(chip)
	elif entry.get("real", false):
		var who := str(entry.get("player", ""))
		var chip2 := Hud.chip(T.s("de %s") % who if who != "" else T.s("Amigo"), Color("ffe6ef"), Color("d6336c"), 17)
		chip2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(chip2)
	var pts := int(GameState.friend_points.get(id, 0))
	var lvl := HBoxContainer.new()
	lvl.add_theme_constant_override("separation", 8)
	lvl.add_child(HeartsRow.new().setup(Neighbors.level_index(pts) + 1, 22.0, Neighbors.LEVELS.size()))
	var lvl_name := Label.new()
	lvl_name.text = Neighbors.level_name(pts)
	lvl_name.add_theme_font_size_override("font_size", 24)
	lvl_name.add_theme_color_override("font_color", PINK.darkened(0.2))
	lvl.add_child(lvl_name)
	info.add_child(lvl)
	var bar := StatBar.new().setup("", "heart", PINK)
	bar.custom_minimum_size = Vector2(0, 36)
	bar.font_size = 17
	bar.warn_low = false
	bar.max_value = float(Neighbors.MAX_POINTS)
	bar.value = float(pts)
	bar.text = "%d / %d" % [pts, Neighbors.MAX_POINTS]
	info.add_child(bar)
	info.add_child(_today_dots(id))

	var visit := Button.new()
	visit.custom_minimum_size = Vector2(108, 108)
	visit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	visit.focus_mode = Control.FOCUS_NONE
	Hud.style_primary(visit, 22, GREEN)
	var inner := VBoxContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 0)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visit.add_child(inner)
	var house := Control.new()
	house.custom_minimum_size = Vector2(0, 46)
	house.mouse_filter = Control.MOUSE_FILTER_IGNORE
	house.draw.connect(func(): Hud.draw_icon(house, "house", house.size * 0.5, 46.0, Color.WHITE, GREEN.darkened(0.2)))
	inner.add_child(house)
	var go := Label.new()
	go.text = "Visitar"
	go.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go.add_theme_font_size_override("font_size", 24)
	go.add_theme_color_override("font_color", Color.WHITE)
	go.add_theme_color_override("font_outline_color", GREEN.darkened(0.3))
	go.add_theme_constant_override("outline_size", 8)
	go.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(go)
	visit.pressed.connect(func():
		Neighbors.current = id
		get_tree().change_scene_to_file("res://scenes/visit.tscn"))
	if entry.get("real", false):  # amigo de verdad: se puede quitar
		var side := VBoxContainer.new()
		side.alignment = BoxContainer.ALIGNMENT_CENTER
		side.add_theme_constant_override("separation", 8)
		side.add_child(visit)
		var quit := Button.new()
		quit.text = "Quitar"
		quit.custom_minimum_size = Vector2(108, 44)
		quit.focus_mode = Control.FOCUS_NONE
		Hud.style_soft(quit, 18)
		quit.pressed.connect(func(): FriendSafety.friend_options(self, entry, func(): _dirty = true))
		side.add_child(quit)
		row.add_child(side)
	else:
		row.add_child(visit)
	return card


## Foto redonda con el Pompon enterito adentro.
func _portrait(p: Pompon, equipped: Dictionary, px: float, tint: Color) -> Control:
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(px, px)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.draw.connect(func():
		frame.draw_circle(frame.size * 0.5, px * 0.5, Color.WHITE)
		frame.draw_circle(frame.size * 0.5, px * 0.5 - 4.0, tint))
	var view := PomponView.new()
	view.animated = false
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.head_zoom = PomponView.portrait_zoom(p, int(Time.get_unix_time_from_system()))
	view.set_pompon(p, equipped)
	frame.add_child(view)
	return frame


## Lo que ya sumo hoy (visita, caricia, juego y regalo): circulitos llenos.
func _today_dots(id: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var today := Label.new()   # "Hoy": los circulitos son lo que ya hicieron juntos hoy
	today.text = "Hoy"
	today.add_theme_font_size_override("font_size", 20)
	today.add_theme_color_override("font_color", Hud.MUTED)
	row.add_child(today)
	for key in Neighbors.DAILY_KEYS:
		var look := Neighbors.daily_look(key)
		var dot := Control.new()
		dot.custom_minimum_size = Vector2(30, 30)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tint: Color = look[1] if GameState.friend_done_today(id, key) else Color("e6dce3")
		var kind: String = look[0]
		dot.draw.connect(func():
			dot.draw_circle(Vector2(15, 15), 15.0, tint)
			Hud.draw_icon(dot, kind, Vector2(15, 15), 20.0, Color.WHITE, tint))
		row.add_child(dot)
	return row


# ------------------------------------------------------------------ amigos de verdad

## Tarjeta de amigos: activar (la primera vez) o tu codigo + "Agregar amigo"; despues las solicitudes.
func _friends_card() -> Control:
	if not Friends.is_available() or GameState.pompon == null or not GameState.pompon.hatched:
		return null
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Hud.card(Color("fff6fa"), 34, Color("ffc2d9"), 4, 8))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	col.add_child(head)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(46, 46)
	icon.draw.connect(func():
		icon.draw_circle(icon.size * 0.5, 23.0, PINK)
		Hud.draw_icon(icon, "people", icon.size * 0.5, 32.0, Color.WHITE, PINK))
	head.add_child(icon)
	var title := Label.new()
	title.text = "Amigos de verdad"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("d6336c"))
	head.add_child(title)
	if Friends.is_active():   # cuantos tiene (maximo 10)
		var full := GameState.friends.size() >= Friends.MAX_FRIENDS
		head.add_child(Hud.chip("%d / %d" % [GameState.friends.size(), Friends.MAX_FRIENDS],
			Color("ffe6ef") if full else Color("d8f5e3"), Color("d6336c") if full else Color("1f7a4d"), 22))

	if not Friends.is_active():
		col.add_child(_pill_button("Activar amigos", _activate, PINK))
		return card

	var code_row := HBoxContainer.new()
	code_row.add_theme_constant_override("separation", 10)
	col.add_child(code_row)
	var mine := VBoxContainer.new()
	mine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mine.add_theme_constant_override("separation", 0)
	code_row.add_child(mine)
	mine.add_child(_small("Tu código de amigo", 21, Color("a0527a")))
	var code := Label.new()
	code.text = CloudCode.format_code(GameState.friend_code)
	code.add_theme_font_size_override("font_size", 40)
	code.add_theme_color_override("font_color", Hud.INK)
	mine.add_child(code)
	var add := _pill_button("Agregar amigo", _ask_add, GREEN)
	add.size_flags_horizontal = Control.SIZE_SHRINK_END
	add.custom_minimum_size = Vector2(230, 76)
	code_row.add_child(add)

	for f in GameState.friend_requests:
		col.add_child(_request_row(f))
	for f in GameState.friend_sent:
		col.add_child(_small(T.s("Esperando que %s acepte…") % CloudCode.format_code(f["code"]), 20, Hud.MUTED))
	return card


## "Mochi (de Ana) quiere ser tu amigo" con Aceptar / No.
func _request_row(f: Dictionary) -> Control:
	var data := Neighbors.build(Neighbors.friend_entry(f))   # su Pompon, igual que el de un amigo
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var p: Pompon = data["pompon"]
	row.add_child(_portrait(p, data["equipped"], 76.0, p.color_primary.lightened(0.55)))
	var text := _small(T.s("¡%s quiere ser tu amigo!") % Friends.display_name(f), 22)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var code: String = f["code"]
	row.add_child(_pill_button("Aceptar", func(): _accept(code), GREEN, Vector2(140, 64)))
	var no := Button.new()
	no.text = "No"
	no.custom_minimum_size = Vector2(80, 64)
	no.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	no.focus_mode = Control.FOCUS_NONE
	Hud.style_soft(no, 22)
	var who := Friends.display_name(f)
	no.pressed.connect(func():   # no aceptar: simplemente "no", o bloquear / denunciar
		var n := BigNotice.new(600.0)
		add_child(n)
		n.title(who, Color("d6336c"))
		n.button("No, gracias", func():
			n.close()
			Friends.answer(code, false), true, GREEN)
		n.button("Bloquear", func():
			n.close()
			Friends.block(code), false)
		n.button("Denunciar", func():
			n.close()
			FriendSafety.report(self, code, who), false)
		n.button("Cancelar", n.close, false))
	row.add_child(no)
	return row


## Aceptar una solicitud: si la lista esta llena (lo diga el juego o el servidor), un aviso amable.
func _accept(code: String) -> void:
	var res: Dictionary = await Friends.answer(code, true)
	if not is_inside_tree() or res["ok"]:
		return
	if res["result"] == "full":
		_show_message("¡Lista llena!", Friends.limit_text("accept", "full"))
	else:
		_show_message("¡Ups!", _error_text(res["result"]))


func _small(text: String, font_size: int, color := Hud.INK) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(200, 0)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _pill_button(text: String, callback: Callable, color: Color, min_size := Vector2(0, 76)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_NONE
	Hud.style_primary(b, 26, color)
	b.pressed.connect(callback)
	return b


## Activar amigos: primero la edad (una vez) y, si es menor de 13, el permiso de un adulto.
func _activate() -> void:
	if GameState.age_group == "":
		FriendSafety.ask_age(self, func(_g): _activate())
		return
	if GameState.kids_mode():
		FriendSafety.parental_gate(self, func(ok: bool):
			if ok:
				_do_activate())
		return
	_do_activate()


func _do_activate() -> void:
	var res: Dictionary = await Friends.activate()
	if not res["ok"]:
		_show_message("¡Ups!", _error_text(res["error"]))
	_dirty = true


## Escribir el codigo de un amigo y mandarle la solicitud.
func _ask_add() -> void:
	if _notice != null:
		return
	_notice = BigNotice.new(620.0)
	add_child(_notice)
	_notice.closed.connect(func(): _notice = null)
	_notice.title("Agregar amigo", Color("2f9e6e"))
	_notice.text_line("Escribe el código de tu amigo.", 28)
	var edit := LineEdit.new()
	edit.placeholder_text = "ABCD-EFGH"
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.max_length = 10
	edit.custom_minimum_size = Vector2(0, 86)
	edit.add_theme_font_size_override("font_size", 40)
	edit.add_theme_stylebox_override("normal", Hud.card(Color("fffdfb"), 30, Color("a9e0c0"), 4, 0))
	edit.add_theme_stylebox_override("focus", Hud.card(Color("fffdfb"), 30, GREEN, 5, 0))
	_notice.add(edit)
	var send := _notice.button("Mandar solicitud", func(): _send(edit.text), true, GREEN)
	send.disabled = true
	edit.text_changed.connect(func(t: String):
		var shown := CloudCode.format_code(CloudCode.normalize(t).left(CloudCode.FRIEND_LEN))
		if shown != t:
			edit.text = shown
			edit.caret_column = shown.length()
		send.disabled = Friends.clean_code(shown) == "")
	_notice.button("Volver", _notice.close, false)
	edit.grab_focus.call_deferred()


func _send(text: String) -> void:
	if _notice != null:
		_notice.close()
	var res: Dictionary = await Friends.request(text)
	var msg: String = {
		"sent": "¡Solicitud enviada! Cuando la acepte, aparece en tu lista.",
		"accepted": "¡Ya son amigos! Ya puedes visitarlo.",
		"friends": "Ya son amigos.",
		"self": "Ese es tu propio código.",
		"not_found": "No encontramos ese código. Revisa las letras.",
		"limit": Friends.limit_text("request", "limit"),
		"full": Friends.limit_text("request", "full"),
	}.get(res["result"], _error_text(res["result"]))
	if not is_inside_tree():
		return
	_show_message("¡Listo!" if res["ok"] else ("¡Lista llena!" if res["result"] == "full" else "¡Ups!"), msg)


func _ask_remove(entry: Dictionary) -> void:
	if _notice != null:
		return
	_notice = BigNotice.new(600.0)
	add_child(_notice)
	_notice.closed.connect(func(): _notice = null)
	_notice.title("¿Dejar de ser amigos?", Color("d6336c"))
	_notice.text_line(T.s("%s ya no va a aparecer en tu lista.") % entry["name"], 28)
	var code: String = entry["code"]
	_notice.button("No, seguir siendo amigos", _notice.close, true, GREEN)
	_notice.button("Quitar amigo", func():
		_notice.close()
		Friends.remove(code), false)


func _show_message(title: String, text: String) -> void:
	if _notice != null:
		_notice.close()
	_notice = BigNotice.new(600.0)
	add_child(_notice)
	_notice.closed.connect(func(): _notice = null)
	_notice.title(title, Color("2f9e6e") if title == "¡Listo!" else Color("e0295f"))
	_notice.text_line(text, 28)
	_notice.button("Volver", _notice.close, true, PINK)


func _error_text(error: String) -> String:
	return {
		"network": "No hay conexión a internet. Prueba de nuevo en un ratito.",
		"code": "El código tiene 8 letras y números.",
		"off": "Los amigos todavía no están disponibles.",
	}.get(error, "Algo salió mal. Prueba más tarde.")
