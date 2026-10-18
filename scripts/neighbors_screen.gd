extends Control
## Lista de vecinos: arriba la barra Social de tu Pompon (la mitad solo se llena con otros
## Pompons); despues una tarjeta por vecino con su nivel de amistad (corazones), la barra 0-100,
## lo que ya sumo hoy (1 punto por visita y por cada actividad) y "Visitar".

const BG := Color("e8f6ee")
const PINK := Color("ff7aa8")
const GREEN := Color("5fc77f")

var _list: VBoxContainer


func _ready() -> void:
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
	for entry in Neighbors.all():
		_list.add_child(_make_row(entry))


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
	var pts := int(GameState.friend_points.get(id, 0))
	var lvl := HBoxContainer.new()
	lvl.add_theme_constant_override("separation", 8)
	lvl.add_child(HeartsRow.new().setup(Neighbors.level_index(pts) + 1, 22.0, Neighbors.LEVELS.size()))
	var lvl_name := Label.new()
	lvl_name.text = Neighbors.level_name(pts)
	lvl_name.add_theme_font_size_override("font_size", 20)
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
	go.add_theme_font_size_override("font_size", 22)
	go.add_theme_color_override("font_color", Color.WHITE)
	go.add_theme_color_override("font_outline_color", GREEN.darkened(0.3))
	go.add_theme_constant_override("outline_size", 8)
	go.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(go)
	visit.pressed.connect(func():
		Neighbors.current = id
		get_tree().change_scene_to_file("res://scenes/visit.tscn"))
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
